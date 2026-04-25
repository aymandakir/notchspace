import AppKit

// MARK: - Model

public struct ClipItem: Identifiable, Equatable {
    public let id:        UUID
    public let text:      String
    public let timestamp: Date

    /// First 40 characters with newlines collapsed to spaces.
    public var preview: String {
        String(
            text
                .replacingOccurrences(of: "\n", with: " ")
                .trimmingCharacters(in: .whitespaces)
                .prefix(40)
        )
    }

    public init(id: UUID = UUID(), text: String, timestamp: Date = Date()) {
        self.id        = id
        self.text      = text
        self.timestamp = timestamp
    }
}

// MARK: - Manager

@MainActor
public final class ClipboardManager: ObservableObject {

    public static let shared = ClipboardManager()

    @Published public var clips: [ClipItem] = []

    private let maxItems      = 10
    private var lastChange:   Int   = 0
    private var timer:        Timer? = nil

    private init() {}

    // MARK: - Lifecycle

    public func start() {
        lastChange = NSPasteboard.general.changeCount
        let t = Timer(timeInterval: 0.8, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.poll() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Polling

    private func poll() {
        let pb = NSPasteboard.general
        guard pb.changeCount != lastChange else { return }
        lastChange = pb.changeCount

        guard let text = pb.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            // Re-copy of an existing entry: bubble it to the front with a fresh timestamp.
            clips.removeAll { $0.text == text }
            clips.insert(ClipItem(text: text), at: 0)
            if clips.count > maxItems { clips = Array(clips.prefix(maxItems)) }
        }
    }

    // MARK: - Actions

    /// Writes `item` back to the pasteboard.
    /// Updates `lastChange` so the poller does not echo this write as a new entry.
    public func copy(_ item: ClipItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(item.text, forType: .string)
        lastChange = pb.changeCount
    }

    public func delete(_ item: ClipItem) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            clips.removeAll { $0.id == item.id }
        }
    }

    public func clear() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            clips.removeAll()
        }
    }
}
