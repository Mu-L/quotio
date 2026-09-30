import SwiftUI

/// One muted line for an account the host has no quota data for.
struct EmptyAccountRow: View {
    let title: String?
    let reason: String?

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: DS.Space.s) { content }
            VStack(alignment: .leading, spacing: DS.Space.xxs) { content }
        }
        .font(DS.Typography.valueLabel)
        .padding(.horizontal, DS.Space.m)
        .padding(.vertical, DS.Space.s + DS.Space.xxs)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardSurface()
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var content: some View {
        if let title {
            Text(title).foregroundStyle(.primary).lineLimit(1).truncationMode(.middle)
        }
        Text("No quota data").foregroundStyle(.secondary)
        if let reason {
            Text(reason).foregroundStyle(.tertiary)
        }
    }
}

#if DEBUG
#Preview("States", traits: .sizeThatFitsLayout) {
    VStack(spacing: DS.Space.s) {
        EmptyAccountRow(title: nil, reason: "Not loaded yet")
        EmptyAccountRow(title: "person@example.test", reason: "Signed out")
        EmptyAccountRow(title: "a.really.long.email.address@some-company.example.com", reason: "Keychain access needed on your Mac")
        EmptyAccountRow(title: nil, reason: nil)
    }
    .padding()
    .frame(width: 390)
}

#Preview("Variants", traits: .sizeThatFitsLayout) {
    PreviewMatrix { EmptyAccountRow(title: "person@example.test", reason: "Signed out") }.frame(width: 390)
}
#endif
