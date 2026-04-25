import SwiftUI
import AVFoundation
import Accelerate
import Core

// MARK: - AudioVisualizer
//
// Drives 12 bar heights in real-time.
//
// A tap on AVAudioEngine.mainMixerNode provides genuine FFT data for any audio
// routed through this process. When the engine is silent (the common case, since
// playback happens in another app), the visualizer falls back to a sine-composite
// simulation so the bars still look alive.
//
// For true system-audio capture (Spotify, Music, etc.) you would replace this
// with an AVAudioEngine process tap (macOS 14.2+) or ScreenCaptureKit audio
// (macOS 12.3+, requires a permission prompt).

@MainActor
private final class AudioVisualizer: ObservableObject {

    @Published var bars:     [Float] = Array(repeating: 0.03, count: 12)
    @Published var rotation: Double  = 0           // album-art rotation, degrees

    private let numBands   = 12
    private let engine     = AVAudioEngine()
    private var simTimer:  Timer?
    private var phase      = Double.zero
    private var smooth:    [Float]
    private var realSignal = false                 // true when FFT data is non-zero

    // FFT setup (reused across callbacks for efficiency)
    private let fftLen    = 1024
    private lazy var fftSetup: FFTSetup? = {
        vDSP_create_fftsetup(vDSP_Length(log2(Float(fftLen))), FFTRadix(kFFTRadix2))
    }()

    init() { smooth = Array(repeating: 0.03, count: numBands) }

    deinit { engine.stop(); simTimer?.invalidate() }

    // MARK: Start / stop

    func start(isPlaying: Bool) {
        isPlaying ? resume() : pause()
    }

    func pause() {
        simTimer?.invalidate(); simTimer = nil
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            bars    = Array(repeating: 0.03, count: numBands)
            smooth  = Array(repeating: 0.03, count: numBands)
        }
    }

    func resume() {
        installEngineTap()
        startSimTimer()
    }

    // MARK: AVAudioEngine tap

    private func installEngineTap() {
        let mixer = engine.mainMixerNode
        let fmt   = mixer.outputFormat(forBus: 0)
        guard fmt.sampleRate > 0 else { return }

        mixer.removeTap(onBus: 0)
        mixer.installTap(onBus: 0, bufferSize: AVAudioFrameCount(fftLen), format: fmt) { [weak self] buf, _ in
            self?.processFFT(buf)
        }
        try? engine.start()
    }

    // MARK: FFT

    private func processFFT(_ buffer: AVAudioPCMBuffer) {
        guard let setup = fftSetup,
              let channel = buffer.floatChannelData?[0] else { return }

        let frameCount = Int(min(buffer.frameLength, AVAudioFrameCount(fftLen)))

        // Hann window
        var windowed = [Float](repeating: 0, count: fftLen)
        var win      = [Float](repeating: 0, count: fftLen)
        vDSP_hann_window(&win, vDSP_Length(fftLen), Int32(vDSP_HANN_NORM))
        vDSP_vmul(channel, 1, win, 1, &windowed, 1, vDSP_Length(frameCount))

        // Forward FFT
        let half = fftLen / 2
        var realp = [Float](repeating: 0, count: half)
        var imagp = [Float](repeating: 0, count: half)
        var split = DSPSplitComplex(realp: &realp, imagp: &imagp)

        windowed.withUnsafeBytes { raw in
            raw.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: half) { ptr in
                vDSP_ctoz(ptr, 2, &split, 1, vDSP_Length(half))
            }
        }
        let log2n = vDSP_Length(log2(Float(fftLen)))
        vDSP_fft_zrip(setup, &split, 1, log2n, FFTDirection(FFT_FORWARD))

        var mags = [Float](repeating: 0, count: half)
        vDSP_zvabs(&split, 1, &mags, 1, vDSP_Length(half))

        // Scale
        var scale = 2.0 / Float(fftLen)
        vDSP_vsmul(mags, 1, &scale, &mags, 1, vDSP_Length(half))

        // Map half-spectrum into numBands (log-spaced)
        let bandMags = logBands(mags, count: numBands)
        let peak = bandMags.max() ?? 0
        realSignal = peak > 0.001

        Task { @MainActor [weak self] in
            self?.applyBands(bandMags)
        }
    }

    private func logBands(_ mags: [Float], count: Int) -> [Float] {
        let lo   = 1
        let hi   = mags.count - 1
        var bands = [Float]()
        for i in 0..<count {
            let t     = Float(i) / Float(count - 1)
            let start = Int(Float(lo) * pow(Float(hi) / Float(lo), t == 0 ? 0 : Float(i)     / Float(count)))
            let end   = Int(Float(lo) * pow(Float(hi) / Float(lo),              Float(i + 1) / Float(count)))
            let slice = mags[max(lo, min(start, hi)) ..< max(lo + 1, min(end + 1, hi + 1))]
            bands.append(slice.reduce(0, +) / Float(max(slice.count, 1)))
        }
        return bands
    }

    // MARK: Simulation fallback + rotation ticker

    private func startSimTimer() {
        simTimer?.invalidate()
        let t = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        simTimer = t
    }

    private func tick() {
        phase    += 0.12
        rotation += 0.3          // 6°/s  ≈ 1 full revolution per minute

        guard !realSignal else { return }      // FFT data already applied in processFFT

        var next = [Float]()
        for i in 0..<numBands {
            let d = Double(i)
            let v = Float(
                sin(phase * 1.7 + d * 0.61) * 0.45
              + sin(phase * 2.3 + d * 1.13) * 0.35
              + sin(phase * 0.9 + d * 0.37) * 0.20
            ) * 0.5 + 0.5
            smooth[i] = smooth[i] * 0.6 + v * 0.4
            next.append(max(0.04, smooth[i]))
        }
        applyBands(next)
    }

    private func applyBands(_ bands: [Float]) {
        withAnimation(.linear(duration: 0.05)) { bars = bands }
    }
}

// MARK: - Marquee text

private struct Marquee: View {
    let text:  String
    let font:  Font
    let color: Color

    @State private var offset:     CGFloat = 0
    @State private var textWidth:  CGFloat = 0
    @State private var boxWidth:   CGFloat = 0
    @State private var animating   = false

    var body: some View {
        GeometryReader { geo in
            Text(text)
                .font(font)
                .foregroundStyle(color)
                .lineLimit(1)
                .fixedSize()
                .offset(x: offset)
                .background(
                    GeometryReader { inner in
                        Color.clear
                            .onAppear {
                                textWidth = inner.size.width
                                boxWidth  = geo.size.width
                                maybeScroll()
                            }
                            .onChange(of: text) { _, _ in
                                offset    = 0
                                animating = false
                                textWidth = inner.size.width
                                boxWidth  = geo.size.width
                                maybeScroll()
                            }
                    }
                )
        }
        .clipped()
    }

    private func maybeScroll() {
        guard textWidth > boxWidth, !animating else { return }
        animating = true
        // Wait 1 s at rest, then scroll at 44 pt/s, pause 0.5 s, repeat
        let scrollDist = textWidth + 32
        let duration   = scrollDist / 44
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.linear(duration: duration)) { offset = -scrollDist }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.5) {
                offset    = 0
                animating = false
                maybeScroll()
            }
        }
    }
}

// MARK: - MediaPanel

public struct MediaPanel: View {

    @ObservedObject public var media: MediaManager
    @StateObject private var viz = AudioVisualizer()

    private let spring = Animation.spring(response: 0.35, dampingFraction: 0.7)

    public init(media: MediaManager) { self.media = media }

    // MARK: Body

    public var body: some View {
        VStack(spacing: 5) {
            topRow
            vizRow
            progressBar
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .onChange(of: media.isPlaying) { _, playing in viz.start(isPlaying: playing) }
        .onAppear  { viz.start(isPlaying: media.isPlaying) }
        .onDisappear { viz.pause() }
    }

    // MARK: - Top row: art | info | controls

    private var topRow: some View {
        HStack(spacing: 10) {
            albumArt
            trackInfo
            Spacer(minLength: 0)
            controls
        }
    }

    // MARK: Album art

    private var albumArt: some View {
        Group {
            if let img = media.albumArt {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.3))
                    )
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
        )
        .rotationEffect(.degrees(media.isPlaying ? viz.rotation : viz.rotation))
        // Rotation continues from wherever it stopped — no snap-back
        .animation(.linear(duration: 0), value: viz.rotation)
    }

    // MARK: Track info

    private var trackInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Marquee(
                text:  media.title.isEmpty  ? "Not Playing" : media.title,
                font:  .system(size: 12, weight: .semibold),
                color: .white
            )
            Marquee(
                text:  media.artist.isEmpty ? "—"           : media.artist,
                font:  .system(size: 11, weight: .regular),
                color: .white.opacity(0.5)
            )
        }
        .frame(maxWidth: 160, alignment: .leading)
    }

    // MARK: Controls

    private var controls: some View {
        HStack(spacing: 14) {
            controlButton("backward.fill") { media.sendPrevious() }
            controlButton(media.isPlaying ? "pause.fill" : "play.fill") { media.togglePlayPause() }
                .font(.system(size: 18, weight: .bold))
            controlButton("forward.fill")  { media.sendNext() }
        }
        .font(.system(size: 15, weight: .medium))
        .foregroundStyle(.white)
        .buttonStyle(.plain)
    }

    private func controlButton(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
    }

    // MARK: - Visualizer row

    private var vizRow: some View {
        HStack(alignment: .bottom, spacing: 2.5) {
            ForEach(0..<12, id: \.self) { i in
                Capsule()
                    .fill(barGradient(index: i))
                    .frame(width: 3, height: max(3, CGFloat(viz.bars[i]) * 22))
                    .animation(.linear(duration: 0.05), value: viz.bars[i])
            }
        }
        .frame(maxWidth: .infinity, minHeight: 24, maxHeight: 24, alignment: .bottom)
    }

    private func barGradient(index: Int) -> LinearGradient {
        let t = Double(index) / 11.0
        let top = Color(
            red:   0.6 + t * 0.4,
            green: 0.8 - t * 0.3,
            blue:  1.0
        )
        return LinearGradient(
            colors: [top, top.opacity(0.5)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.12))

                Capsule()
                    .fill(Color.white.opacity(0.75))
                    .frame(width: max(4, geo.size.width * CGFloat(media.progress)))
                    .animation(spring, value: media.progress)
            }
        }
        .frame(height: 3)
    }
}
