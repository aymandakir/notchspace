import SwiftUI

// MARK: - Panel

public struct ClipboardPanel: View {

    @ObservedObject public var manager: ClipboardManager

    public init(manager: ClipboardManager) { self.manager = manager }

    public var body: some View {
        Group {
            if manager.clips.isEmpty {
                emptyState
            } else {
                clipScroll
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Clip scroll

    private var clipScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(manager.clips) { clip in
                    ClipCard(
                        clip:     clip,
                        onCopy:   { manager.copy(clip) },
                        onDelete: { manager.delete(clip) }
                    )
                    .transition(
                        .scale(scale: 0.82, anchor: .leading)
                         .combined(with: .opacity)
                    )
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 5) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 18))
                .foregroundStyle(.white.opacity(0.2))
            Text("No clipboard history")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.2))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Card

private struct ClipCard: View {

    let clip:     ClipItem
    let onCopy:   () -> Void
    let onDelete: () -> Void

    @State private var highlighted = false

    private let spring   = Animation.spring(response: 0.28, dampingFraction: 0.7)
    private let cardW:   CGFloat = 136
    private let cardH:   CGFloat = 70

    var body: some View {
        ZStack(alignment: .topTrailing) {
            cardBody
            deleteButton
        }
        .frame(width: cardW, height: cardH)
    }

    // MARK: Card body

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(clip.preview)
                .font(.system(size: 11, weight: .medium, design: .default))
                .foregroundStyle(.white.opacity(0.82))
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 4)

            Text(relativeTime(clip.timestamp))
                .font(.system(size: 9.5, weight: .regular))
                .foregroundStyle(.white.opacity(0.32))
        }
        .padding(.horizontal, 10)
        .padding(.top, 9)
        .padding(.bottom, 7)
        .frame(width: cardW, height: cardH)
        .background(cardFill)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(cardBorder)
        // Green glow layers
        .shadow(
            color: highlighted ? Color.green.opacity(0.45) : .clear,
            radius: 10, x: 0, y: 0
        )
        .shadow(
            color: highlighted ? Color.green.opacity(0.2) : .clear,
            radius: 20, x: 0, y: 0
        )
        .animation(spring, value: highlighted)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onTapGesture { triggerCopy() }
    }

    private var cardFill: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(
                highlighted
                    ? Color.green.opacity(0.13)
                    : Color.white.opacity(0.07)
            )
            .animation(spring, value: highlighted)
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(
                highlighted
                    ? Color.green.opacity(0.55)
                    : Color.white.opacity(0.10),
                lineWidth: highlighted ? 1.0 : 0.5
            )
            .animation(spring, value: highlighted)
    }

    // MARK: Delete button

    private var deleteButton: some View {
        // Button sits atop the card in the ZStack, so SwiftUI's hit-testing
        // gives it priority over the card's onTapGesture without any extra work.
        Button(action: onDelete) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.35))
                .frame(width: 26, height: 26)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(4)
    }

    // MARK: Helpers

    private func triggerCopy() {
        onCopy()
        withAnimation(spring)    { highlighted = true  }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            withAnimation(spring) { highlighted = false }
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let s = Date().timeIntervalSince(date)
        switch s {
        case ..<60:      return "just now"
        case ..<3600:    return "\(Int(s / 60))m ago"
        case ..<86400:   return "\(Int(s / 3600))h ago"
        default:
            let f = DateFormatter(); f.dateFormat = "MM/dd"
            return f.string(from: date)
        }
    }
}
