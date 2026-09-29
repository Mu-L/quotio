import SwiftUI
import Charts
import QuotioMobile

struct MetricView: View {
    let metric: MobileSnapshot.Metric
    let hidden: Bool
    let showUsed: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var percentage: Double? { metric.remainingPercent.map { showUsed ? 100 - $0 : $0 } }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(metric.name).font(.subheadline)
                Spacer()
                if let reset = metric.resetsAt { Text(reset, format: .dateTime.month(.abbreviated).day().hour().minute()).font(.caption).foregroundStyle(.secondary) }
            }
            if hidden {
                Text("••••").font(.largeTitle).accessibilityLabel("Values hidden")
            } else if let value = percentage {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(value / 100, format: .percent.precision(.fractionLength(0)))
                        .font(.system(.largeTitle, design: .rounded).weight(.medium)).monospacedDigit()
                        .contentTransition(.numericText())
                    Text(showUsed ? "used" : "left").foregroundStyle(.secondary)
                }
                ProgressView(value: value, total: 100).tint(.green)
                    .accessibilityLabel(metric.name)
                    .accessibilityValue(Text("\(Int(value)) percent \(showUsed ? String(localized: "used") : String(localized: "left"))"))
            } else if metric.state == "unlimited" {
                Text("Unlimited").font(.title2)
            } else if let amount = metric.amount {
                HStack { Text(amount, format: .number); Text(metric.unit ?? "") }.font(.title2)
            } else { Text("Not available").font(.title2).foregroundStyle(.secondary) }
            if metric.resetsAt == nil, let description = metric.resetDescription { Text(description).font(.caption).foregroundStyle(.secondary) }
        }
        .animation(hidden || reduceMotion ? nil : .smooth(duration: 0.3), value: percentage)
        .privacySensitive()
    }
}

struct AccountCard: View {
    let account: MobileSnapshot.Account
    let hidden: Bool
    let showUsed: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Group {
                    if let image = UIImage(named: account.providerID == "codex" ? "openai" : account.providerID) {
                        Image(uiImage: image).renderingMode(.template).resizable().scaledToFit().frame(width: 30, height: 30)
                    } else { Image(systemName: "chart.pie.fill").font(.title2).foregroundStyle(.green) }
                }.accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.providerName).font(.title2.weight(.semibold))
                    Text(hidden ? String(localized: "Account hidden") : account.name).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }
            if let metric = account.metrics.first { MetricView(metric: metric, hidden: hidden, showUsed: showUsed) }
            else { Text(account.plan ?? String(localized: "Quota not loaded")).foregroundStyle(.secondary) }
            TimelineView(.periodic(from: .now, by: 60)) { context in
                if account.isStale(at: context.date) { Label("Older or unavailable data", systemImage: "clock").font(.caption).foregroundStyle(.secondary) }
            }
            if !account.enabled { Label("Disabled on host", systemImage: "pause.circle").font(.caption) }
        }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 28))
    }
}

struct AccountDetail: View {
    let account: MobileSnapshot.Account
    let hidden: Bool
    let showUsed: Bool
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(account.metrics) { metric in
                    MetricView(metric: metric, hidden: hidden, showUsed: showUsed).padding(24).cardSurface()
                }
                if let count = account.availableResets(at: .now) {
                    Label {
                        Text("\(hidden ? "••••" : count.formatted()) available resets")
                    } icon: { Image(systemName: "arrow.counterclockwise.circle").foregroundStyle(.green) }
                    .font(.title3).padding(24).cardSurface().accessibilityLabel(hidden ? Text("Values hidden") : Text("\(count) available resets"))
                }
                if let analytics = account.analytics { AnalyticsView(analytics: analytics, hidden: hidden) }
                VStack(alignment: .leading, spacing: 12) {
                    if let plan = account.plan { LabeledContent("Plan", value: hidden ? "••••" : plan) }
                    LabeledContent("Status", value: account.state)
                    if let date = account.fetchedAt { LabeledContent("Observed", value: date.formatted()) }
                    if let issue = account.issue { Label(issue, systemImage: "exclamationmark.triangle").font(.caption) }
                    ForEach(Array(account.sourceStates.enumerated()), id: \.offset) { _, state in Text(state).font(.caption).foregroundStyle(.secondary) }
                }.padding(24).cardSurface()
            }.padding(20)
        }.background(Color(.systemGroupedBackground))
            .navigationTitle(hidden ? account.providerName : account.name)
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct AnalyticsView: View {
    let analytics: MobileSnapshot.Analytics
    let hidden: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Account activity").font(.title2.weight(.semibold))
            Text("30 reported days").foregroundStyle(.secondary)
            Text(hidden ? "••••" : analytics.latest30BucketsTokens.formatted()).font(.largeTitle).monospacedDigit()
            Text("tokens").font(.caption).foregroundStyle(.secondary)
            if hidden {
                Label("Activity hidden", systemImage: "eye.slash").frame(maxWidth: .infinity, minHeight: 150)
            } else {
                Chart(Array(analytics.days.suffix(30))) { day in
                    BarMark(x: .value("Reported day", day.date), y: .value("Tokens", day.tokens)).foregroundStyle(.green).cornerRadius(3)
                        .accessibilityLabel(day.date).accessibilityValue("\(day.tokens) tokens")
                }.chartXAxis(.hidden).frame(height: 170)
                HStack { Text(analytics.days.suffix(30).first?.date ?? ""); Spacer(); Text(analytics.days.last?.date ?? "") }.font(.caption).foregroundStyle(.secondary)
            }
            Divider()
            statistic("Lifetime tokens", analytics.lifetimeTokens)
            statistic("Peak day", analytics.peakDailyTokens)
            statistic("Longest turn (seconds)", analytics.longestRunningTurnSeconds)
            statistic("Current streak (days)", analytics.currentStreakDays)
            statistic("Longest streak (days)", analytics.longestStreakDays)
            Text("Provider-reported days. Missing days are unavailable, not zero. Dates keep the provider's calendar.").font(.footnote).foregroundStyle(.secondary)
        }.padding(24).cardSurface().privacySensitive()
    }
    @ViewBuilder private func statistic(_ label: LocalizedStringKey, _ value: UInt64?) -> some View {
        if let value { LabeledContent(label, value: hidden ? "••••" : value.formatted()) }
    }
}

extension View {
    func cardSurface() -> some View {
        frame(maxWidth: .infinity, alignment: .leading).background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 28))
    }
}
