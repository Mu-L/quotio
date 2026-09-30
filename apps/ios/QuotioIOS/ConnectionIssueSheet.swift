import SwiftUI
import QuotioMobile

/// Details and troubleshooting for the current connection issue.
struct ConnectionIssueSheet: View {
    let issue: ConnectionIssue
    let lastSync: Date?
    let retry: () -> Void
    let pair: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(issue.detail)
                    if let lastSync {
                        LabeledContent("Last synced") {
                            FreshnessLabel(date: lastSync, style: .wide)
                        }
                    }
                }
                if !issue.steps.isEmpty {
                    Section("Try this") {
                        ForEach(Array(issue.steps.enumerated()), id: \.offset) { index, step in
                            Label {
                                Text(step)
                            } icon: {
                                Text(index + 1, format: .number).font(DS.Typography.value).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section {
                    if issue.needsPairing {
                        Button("Pair again") { dismiss(); pair() }
                    } else {
                        Button("Retry") { dismiss(); retry() }
                    }
                }
            }
            .navigationTitle(issue.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { dismiss() } }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#if DEBUG
#Preview("Unreachable") {
    ConnectionIssueSheet(issue: .unreachable, lastSync: .now.addingTimeInterval(-900), retry: {}, pair: {})
}

#Preview("Needs pairing · VI") {
    ConnectionIssueSheet(issue: .needsPairing, lastSync: nil, retry: {}, pair: {})
        .environment(\.locale, Locale(identifier: "vi"))
}
#endif
