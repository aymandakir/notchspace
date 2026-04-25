import AppKit
import Core

// MARK: - MediaRemote command identifiers

public enum MRCommand: UInt32 {
    case play            = 0
    case pause           = 1
    case togglePlayPause = 2
    case nextTrack       = 4
    case previousTrack   = 5
}

// MARK: - Private info-dict key strings

private enum MRKey {
    static let title        = "kMRMediaRemoteNowPlayingInfoTitle"
    static let artist       = "kMRMediaRemoteNowPlayingInfoArtist"
    static let artworkData  = "kMRMediaRemoteNowPlayingInfoArtworkData"
    static let duration     = "kMRMediaRemoteNowPlayingInfoDuration"
    static let elapsedTime  = "kMRMediaRemoteNowPlayingInfoElapsedTime"
    static let playbackRate = "kMRMediaRemoteNowPlayingInfoPlaybackRate"
}

// MARK: - Notification name strings

private enum MRNote {
    static let infoChanged   = "kMRMediaRemoteNowPlayingInfoDidChangeNotification"
    static let stateChanged  = "kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification"
}

// MARK: - Function-pointer type aliases
//
// MediaRemote lives in a private framework and is loaded dynamically via CFBundle
// so no linker path is needed. The C functions use ObjC block parameters; Swift
// bridges closure literals to blocks transparently in this @convention(c) context.

private typealias FnGetInfo      = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
private typealias FnRegister     = @convention(c) (DispatchQueue) -> Void
private typealias FnSendCommand  = @convention(c) (UInt32, CFDictionary?) -> Bool
private typealias FnIsPlaying    = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void

// MARK: - Manager

@MainActor
public final class MediaManager: ObservableObject {

    public static let shared = MediaManager()

    @Published public var title:    String   = ""
    @Published public var artist:   String   = ""
    @Published public var albumArt: NSImage? = nil
    @Published public var isPlaying: Bool    = false
    @Published public var progress:  Double  = 0.0   // 0–1
    @Published public var duration:  Double  = 0.0   // seconds

    // MARK: Private state

    private var fnGetInfo:     FnGetInfo?
    private var fnRegister:    FnRegister?
    private var fnSendCommand: FnSendCommand?
    private var fnIsPlaying:   FnIsPlaying?

    private var observers:          [Any]  = []
    private var progressTimer:      Timer? = nil
    private var elapsedAtFetch:     Double = 0
    private var fetchDate:          Date   = Date()

    private init() { loadFramework() }

    // MARK: - Dynamic loading

    private func loadFramework() {
        guard let bundle = CFBundleCreate(
            kCFAllocatorDefault,
            NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")
        ) else { return }

        func sym<T>(_ name: String) -> T? {
            CFBundleGetFunctionPointerForName(bundle, name as CFString)
                .map { unsafeBitCast($0, to: T.self) }
        }

        fnGetInfo     = sym("MRMediaRemoteGetNowPlayingInfo")
        fnRegister    = sym("MRMediaRemoteRegisterForNowPlayingNotifications")
        fnSendCommand = sym("MRMediaRemoteSendCommand")
        fnIsPlaying   = sym("MRMediaRemoteGetNowPlayingApplicationIsPlaying")
    }

    // MARK: - Lifecycle

    public func start() {
        fnRegister?(DispatchQueue.main)
        subscribeNotifications()
        fetchInfo()
    }

    public func stop() {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll()
        stopProgressTimer()
    }

    // MARK: - Notifications

    private func subscribeNotifications() {
        let nc = NotificationCenter.default
        observers.append(
            nc.addObserver(forName: .init(MRNote.infoChanged),  object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in self?.fetchInfo() }
            }
        )
        observers.append(
            nc.addObserver(forName: .init(MRNote.stateChanged), object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in self?.fetchPlayState() }
            }
        )
    }

    // MARK: - Fetch

    private func fetchInfo() {
        fnGetInfo?(DispatchQueue.main) { [weak self] info in
            Task { @MainActor [weak self] in self?.applyInfo(info) }
        }
    }

    private func fetchPlayState() {
        fnIsPlaying?(DispatchQueue.main) { [weak self] playing in
            Task { @MainActor [weak self] in
                self?.isPlaying = playing
                playing ? self?.startProgressTimer() : self?.stopProgressTimer()
            }
        }
    }

    private func applyInfo(_ info: [String: Any]) {
        title  = info[MRKey.title]  as? String ?? ""
        artist = info[MRKey.artist] as? String ?? ""

        if let data = info[MRKey.artworkData] as? Data {
            albumArt = NSImage(data: data)
        }

        duration = info[MRKey.duration]     as? Double ?? 0
        let elapsed = info[MRKey.elapsedTime]   as? Double ?? 0
        let rate    = info[MRKey.playbackRate]  as? Double ?? 0

        isPlaying         = rate > 0
        elapsedAtFetch    = elapsed
        fetchDate         = Date()
        progress          = duration > 0 ? elapsed / duration : 0

        isPlaying ? startProgressTimer() : stopProgressTimer()
    }

    // MARK: - Progress timer

    private func startProgressTimer() {
        stopProgressTimer()
        let t = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tickProgress() }
        }
        RunLoop.main.add(t, forMode: .common)
        progressTimer = t
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func tickProgress() {
        guard isPlaying, duration > 0 else { return }
        let elapsed = elapsedAtFetch + Date().timeIntervalSince(fetchDate)
        progress = min(elapsed / duration, 1.0)
    }

    // MARK: - Playback commands

    @discardableResult
    public func sendCommand(_ cmd: MRCommand) -> Bool {
        fnSendCommand?(cmd.rawValue, nil) ?? false
    }

    public func togglePlayPause() { sendCommand(.togglePlayPause) }
    public func sendNext()         { sendCommand(.nextTrack) }
    public func sendPrevious()     { sendCommand(.previousTrack) }
}
