import SwiftUI

public struct FocusTimerPanel: View {

    @ObservedObject public var manager: FocusTimerManager

    @State private var animatedProgress: Double = 1.0
    @State private var breathe:          Bool   = false

    private let ringSize:  CGFloat = 62
    private let strokeW:   CGFloat = 5
    private let spring = Animation.spring(response: 0.35, dampingFraction: 0.75)

    public init(manager: FocusTimerManager) { self.manager = manager }

    public var body: some View {
        HStack(spacing: 12) {
            ring
            info
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .onChange(of: manager.timeRemaining) { _, _ in updateProgress() }
        .onChange(of: manager.isRunning)     { _, running in
            if running { breathe = false } else { startBreathing() }
        }
        .onAppear {
            updateProgress()
            if !manager.isRunning { startBreathing() }
        }
    }

    // MARK: - Ring

    private var ring: some View {
        ZStack {
            // Track
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: strokeW)

            // Arc (drains clockwise — progress goes from 1→0)
            Canvas { ctx, size in
                let rect   = CGRect(origin: .zero, size: size).insetBy(dx: strokeW / 2, dy: strokeW / 2)
                let start  = Angle.degrees(-90)
                let end    = Angle.degrees(-90 + 360 * animatedProgress)
                let path   = Path { p in
                    p.addArc(center: CGPoint(x: size.width / 2, y: size.height / 2),
                             radius: rect.width / 2,
                             startAngle: start,
                             endAngle:   end,
                             clockwise:  false)
                }
                ctx.addFilter(.shadow(color: arcColor.opacity(0.7), radius: 6))
                ctx.stroke(path,
                           with: .color(arcColor),
                           style: StrokeStyle(lineWidth: strokeW, lineCap: .round))
            }
            .scaleEffect(breathe && !manager.isRunning ? 1.04 : 1.0)
            .opacity(breathe && !manager.isRunning ? 0.85 : 1.0)
            .animation(
                manager.isRunning
                    ? .linear(duration: 0)
                    : .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                value: breathe
            )
        }
        .frame(width: ringSize, height: ringSize)
    }

    // MARK: - Info column

    private var info: some View {
        VStack(alignment: .leading, spacing: 4) {
            timeLabel
            phaseLabel
            cycleDots
            HStack(spacing: 8) {
                startPauseButton
                resetButton
            }
        }
    }

    private var timeLabel: some View {
        Text(formattedTime)
            .font(.system(size: 22, weight: .semibold, design: .monospaced))
            .foregroundStyle(.white)
    }

    private var phaseLabel: some View {
        Text(manager.phase.label)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(arcColor.opacity(0.85))
    }

    private var cycleDots: some View {
        HStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(i < manager.cyclesCompleted % 4 || (manager.cyclesCompleted > 0 && manager.cyclesCompleted % 4 == 0)
                          ? arcColor
                          : Color.white.opacity(0.18))
                    .frame(width: 5, height: 5)
            }
        }
    }

    private var startPauseButton: some View {
        Button(action: manager.isRunning ? manager.pause : manager.start) {
            Image(systemName: manager.isRunning ? "pause.fill" : "play.fill")
                .font(.system(size: 12, weight: .bold))
                .frame(width: 28, height: 20)
                .background(arcColor.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .foregroundStyle(arcColor)
        }
        .buttonStyle(.plain)
    }

    private var resetButton: some View {
        Button(action: manager.reset) {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 11, weight: .medium))
                .frame(width: 22, height: 20)
                .foregroundStyle(.white.opacity(0.4))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var arcColor: Color {
        switch manager.phase {
        case .work:                    return Color(red: 1.0, green: 0.58, blue: 0.2)
        case .shortBreak, .longBreak:  return Color(red: 0.35, green: 0.9, blue: 0.55)
        }
    }

    private var formattedTime: String {
        let t   = Int(manager.timeRemaining)
        let m   = t / 60
        let s   = t % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func updateProgress() {
        let p = manager.timeRemaining / manager.phase.duration
        withAnimation(.linear(duration: 0.8)) { animatedProgress = p }
    }

    private func startBreathing() {
        breathe = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { breathe = true }
    }
}
