import SwiftUI

/// Renders a status message in a tinted card, with light formatting for
/// multi-line messages and an animated ellipsis for in-progress states.
struct ResultCard: View {

    let message: Message

    var body: some View {
        let tint = Self.tint(for: self.message)

        return VStack(alignment: .leading, spacing: 10) {
            self.content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(tint.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(tint.opacity(0.35), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var content: some View {
        if self.message.isLoading {
            TimelineView(.periodic(from: .now, by: 0.45)) { context in
                Text(Self.animatedEllipsisMessage(for: self.message.text, at: context.date))
                    .font(.body)
                    .foregroundColor(.primary)
            }
        } else if let emphasis = Self.emphasizedTwoLineMessage(for: self.message.text) {
            Text(emphasis.firstLine)
                .font(.body)
                .foregroundColor(.primary)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(emphasis.secondLabel):")
                    .font(.body)
                    .foregroundColor(.primary)

                Text(emphasis.secondValue)
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)
            }
        } else if let twoLine = Self.simpleTwoLineMessage(for: self.message.text) {
            Text(twoLine.firstLine)
                .font(.body)
                .foregroundColor(.primary)

            Text(twoLine.secondLine)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)
        } else {
            Text(self.message.text)
                .font(.body)
                .foregroundColor(.primary)
        }
    }

    private static func tint(for message: Message) -> Color {
        switch message.severity {
        case .info:
            return .blue
        case .success:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }

    private static func animatedEllipsisMessage(for message: String, at date: Date) -> String {
        guard message.hasSuffix("...") else { return message }

        let base = String(message.dropLast(3))
        let dots = Int(date.timeIntervalSinceReferenceDate * 2).quotientAndRemainder(dividingBy: 3).remainder + 1
        return base + String(repeating: ".", count: dots)
    }

    private static func emphasizedTwoLineMessage(
        for message: String
    ) -> (firstLine: String, secondLabel: String, secondValue: String)? {
        let lines = message.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count == 2 else { return nil }
        guard let separatorIndex = lines[1].firstIndex(of: ":") else { return nil }

        let label = String(lines[1][..<separatorIndex]).trimmingCharacters(in: .whitespaces)
        let value = String(lines[1][lines[1].index(after: separatorIndex)...]).trimmingCharacters(in: .whitespaces)
        guard !label.isEmpty, !value.isEmpty else { return nil }

        return (lines[0], label, value)
    }

    private static func simpleTwoLineMessage(for message: String) -> (firstLine: String, secondLine: String)? {
        let lines = message.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count == 2 else { return nil }
        guard Self.emphasizedTwoLineMessage(for: message) == nil else { return nil }

        return (lines[0], lines[1])
    }

}
