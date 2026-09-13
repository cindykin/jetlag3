import SwiftUI

// MARK: - Layout Constants
private enum TL {
    static let hourHeight: CGFloat        = 56
    static let timeColumnWidth: CGFloat   = 44
    static let blockCornerRadius: CGFloat = 14
    static let accentBarWidth: CGFloat    = 4
    static let blockMinHeight: CGFloat    = 38
    static let iconSize: CGFloat          = 22
}

// MARK: - BlockType UI Extensions (view-only presentation helpers)

private extension BlockType {
    /// Short display label for the timeline block.
    var displayLabel: String {
        switch self {
        case .seekLight:   return "Seek Light"
        case .avoidLight:  return "Avoid Light"
        case .sleep:       return "Go to Sleep"
        case .nap:         return "Take a nap\n(If can)"
        case .caffeine:    return "Caffeine"
        case .noCaffeine:  return "Avoid Caffeine"
        case .melatonin:   return "Take melantonin\n& Go to Sleep"
        case .flight:      return "Flight"
        }
    }
}

// MARK: - Section Builder
//
// `DaySection`, `PositionedBlock`, `TimezoneDividerInfo`, and `buildSections(from:flights:)`
// now live in `Services/ScheduleTimelineBuilder.swift` (extracted out of this View file so
// the boundary/split logic is unit-testable — see `ScheduleTimelineBuilderTests.swift`).

// MARK: - ScheduleView
struct ScheduleView: View {
    @EnvironmentObject private var appState: AppState
    @State private var trip: Trip
    @State private var selectedBlock: TimelineBlock?
    @State private var showDetail = false
    @State private var showReschedule = false
    @State private var rescheduleStart = Date()
    @State private var rescheduleEnd   = Date()

    init(trip: Trip) {
        _trip = State(initialValue: trip)
    }

    private var sections: [DaySection] {
        buildSections(from: trip.blocks, flights: trip.flights)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    if sections.isEmpty {
                        emptyState
                    } else {
                        ForEach(sections) { section in
                            SectionView(section: section) { block in
                                selectedBlock = block
                                showDetail = true
                            }
                        }
                        EndOfPlanFooter().padding(.bottom, 72)
                    }
                }
            }

            if !sections.isEmpty {
                TapHintPill().padding(.bottom, 20)
            }
        }
        .navigationTitle(
            "\(trip.originCity.isEmpty ? trip.originCode : trip.originCity) - " +
            "\(trip.destinationCity.isEmpty ? trip.destinationCode : trip.destinationCity)"
        )
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showDetail) {
            if let block = selectedBlock {
                BlockDetailSheet(block: block, canReschedule: !trip.hasRescheduled) {
                    prepareReschedule()
                    showDetail = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showReschedule = true }
                }
            }
        }
        .sheet(isPresented: $showReschedule) {
            RescheduleSheet(sleepStart: $rescheduleStart, sleepEnd: $rescheduleEnd) {
                applyReschedule()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundStyle(Color(.tertiaryLabel))
            Text("No schedule yet")
                .font(.headline)
                .foregroundStyle(Color(.secondaryLabel))
            Text("Your adaptation plan will appear here once generated.")
                .font(.subheadline)
                .foregroundStyle(Color(.tertiaryLabel))
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    private func prepareReschedule() {
        if let sleepBlock = trip.blocks.first(where: { $0.type == .sleep || $0.type == .melatonin }) {
            rescheduleStart = sleepBlock.startTime
            rescheduleEnd = sleepBlock.endTime
        }
    }

    private func applyReschedule() {
        guard let updatedTrip = appState.rescheduleTrip(
            id: trip.id,
            actualSleepStart: rescheduleStart,
            actualSleepEnd: rescheduleEnd
        ) else {
            return
        }
        trip = updatedTrip
        selectedBlock = nil
    }
}


// MARK: - Section View
private struct SectionView: View {
    let section: DaySection
    let onTap: (TimelineBlock) -> Void

    var body: some View {
        VStack(spacing: 0) {
            SectionHeader(section: section)
            TimelineGrid(section: section, onTap: onTap)
        }
    }
}

// MARK: - Section Header
//
// Consolidated bar (2026-09-12): previously a boundary section rendered TWO stacked bars —
// `TimezoneDividerView` (date + optional city badge + time) immediately followed by this
// plain header (date + time again) — visually duplicated the date/time. Now this single
// view reads `section.divider` directly: the city badge only appears for a genuine
// timezone-arrival boundary, and the bottom border only appears when this section was
// opened by ANY boundary (midnight or arrival) — never for the very first (trip-start)
// section, matching `dividerInfo(for:)`'s existing rule that trip-start has no divider.
private struct SectionHeader: View {
    let section: DaySection

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(section.dateLabel)
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            Spacer()

            if let cityName = section.divider?.cityName {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text("\(cityName) Time")
                }
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(.secondarySystemBackground))
                .clipShape(Capsule())
            }

            Text("\(section.localTimeLabel) · \(section.timeZoneLabel)")
                .font(.footnote)
                .foregroundStyle(Color(.secondaryLabel))
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, section.divider != nil ? 10 : 6)
        .overlay(alignment: .bottom) {
            if section.divider != nil {
                Rectangle()
                    .fill(Color(.separator).opacity(0.5))
                    .frame(height: 0.5)
            }
        }
    }
}

// MARK: - Timeline Grid
private struct TimelineGrid: View {
    let section: DaySection
    let onTap: (TimelineBlock) -> Void

    private var hourTicks: [Int] {
        let s = Int(floor(section.startHour))
        let e = Int(ceil(section.endHour))
        return Array(s...e)
    }
    private var totalHeight: CGFloat {
        CGFloat(section.endHour - section.startHour) * TL.hourHeight
    }
    private var columns: [[PositionedBlock]] { layoutColumns(section.blocks) }

    /// Real wall-clock label for each hour tick. `hour` here is relative to
    /// `section.startHour` (often non-integer/non-midnight — e.g. a segment opening right
    /// after a 03:01 arrival) — it is NOT itself an hour-of-day. The old code formatted
    /// `hour % 24` directly as if it were, so a segment starting mid-hour always showed
    /// "00:00" on its first tick. This derives the actual Date for each tick from
    /// `segmentStartDate` + `timeZone` and formats THAT, so the label is always correct
    /// local wall-clock time (truncated to the hour, matching the original ":00" display).
    private var hourLabels: [Int: String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:00"
        formatter.timeZone = section.timeZone
        var labels: [Int: String] = [:]
        for hour in hourTicks {
            let actualDate = section.segmentStartDate.addingTimeInterval((Double(hour) - section.startHour) * 3600)
            labels[hour] = formatter.string(from: actualDate)
        }
        return labels
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Time column
            ZStack(alignment: .topTrailing) {
                Color.clear
                    .frame(width: TL.timeColumnWidth, height: totalHeight)
                ForEach(hourTicks, id: \.self) { hour in
                    let offset = CGFloat(Double(hour) - section.startHour) * TL.hourHeight
                    Text(hourLabels[hour] ?? "")
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color(.tertiaryLabel))
                        .offset(y: offset - 6)
                }
            }

            // Separator
            Color.clear.frame(width: 8)

            // Block area
            ZStack(alignment: .topLeading) {
                // Grid lines
                ZStack {
                    Color.clear.frame(maxWidth: .infinity).frame(height: totalHeight)
                    ForEach(hourTicks, id: \.self) { hour in
                        let offset = CGFloat(Double(hour) - section.startHour) * TL.hourHeight
                        Rectangle()
                            .fill(Color(.separator).opacity(0.3))
                            .frame(maxWidth: .infinity).frame(height: 0.5)
                            .offset(y: offset)
                    }
                }

                // Block columns
                HStack(alignment: .top, spacing: 4) {
                    ForEach(columns.indices, id: \.self) { ci in
                        let col = columns[ci]
                        ZStack(alignment: .topLeading) {
                            Color.clear.frame(maxWidth: .infinity).frame(height: totalHeight)
                            ForEach(col) { item in
                                let top = CGFloat(item.startHour - section.startHour) * TL.hourHeight
                                let h   = max(CGFloat(item.durationHours) * TL.hourHeight, TL.blockMinHeight)
                                BlockView(block: item.block)
                                    .frame(maxWidth: .infinity).frame(height: h)
                                    .offset(y: top)
                                    .onTapGesture { onTap(item.block) }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity).frame(height: totalHeight)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }
}

// MARK: - Column layout (greedy overlap resolver)
private func layoutColumns(_ items: [PositionedBlock]) -> [[PositionedBlock]] {
    var columns: [[PositionedBlock]] = []
    var colEnd: [Double] = []
    for item in items.sorted(by: { $0.startHour < $1.startHour }) {
        var placed = false
        for i in columns.indices {
            if item.startHour >= colEnd[i] {
                columns[i].append(item); colEnd[i] = item.endHour; placed = true; break
            }
        }
        if !placed { columns.append([item]); colEnd.append(item.endHour) }
    }
    return columns
}

// MARK: - Block View (was ActivityBlock)
private struct BlockView: View {
    let block: TimelineBlock

    var body: some View {
        HStack(spacing: 0) {
            // Left accent bar
            Rectangle()
                .fill(block.type.color)
                .frame(width: TL.accentBarWidth)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: TL.blockCornerRadius,
                        bottomLeadingRadius: TL.blockCornerRadius,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 0
                    )
                )

            // Body
            HStack(alignment: .top, spacing: 6) {
                iconCluster
                    .padding(.leading, 8)
                    .padding(.top, 8)

                Text(block.type.displayLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(.label))
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                    .padding(.trailing, 6)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(block.type.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: TL.blockCornerRadius))
    }

    @ViewBuilder
    private var iconCluster: some View {
        HStack(spacing: 2) {
            ForEach(block.type.icons, id: \.self) { icon in
                Image(systemName: icon)
                    .font(.system(size: TL.iconSize, weight: .regular))
                    .foregroundStyle(block.type.color)
            }
        }
        .frame(height: TL.iconSize + 10)
    }
}

// MARK: - Tap Hint Pill
private struct TapHintPill: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "hand.tap")
                .font(.system(size: 12))
            Text("Tap a block for details")
                .font(.system(size: 13))
        }
        .foregroundStyle(Color(.secondaryLabel))
        .padding(.horizontal, 18).padding(.vertical, 9)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.07), radius: 8, y: 3)
    }
}

// MARK: - End of Plan Footer
private struct EndOfPlanFooter: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color(hex: "#E8A020"))
            Text("Yay you did it!! Enjoy your day!")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(hex: "#E8A020").opacity(0.08))
    }
}

// MARK: - Block Detail Sheet (was ActivityDetailSheet)
struct BlockDetailSheet: View {
    let block: TimelineBlock
    let canReschedule: Bool
    let onReschedule: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Header
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(block.type.backgroundColor)
                                .frame(width: 56, height: 56)
                            HStack(spacing: 2) {
                                ForEach(block.type.icons, id: \.self) { icon in
                                    Image(systemName: icon)
                                        .font(.system(size: 26, weight: .regular))
                                        .foregroundStyle(block.type.color)
                                }
                            }
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(block.type.rawValue)
                                .font(.title3).fontWeight(.semibold)
                            Text("\"\(block.type.rawValue) at your scheduled time\"")
                                .font(.subheadline).foregroundStyle(.secondary).italic()
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(block.type.backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    DetailInfoSection(title: "What I should do?",
                                      icon: "checkmark.circle.fill", color: .green,
                                      content: block.type.whatToDo)
                    DetailInfoSection(title: "I can't do it, what should I do?",
                                      icon: "arrow.triangle.2.circlepath", color: Color(hex: "#4A90E2"),
                                      content: block.type.alternatives)
                    DetailInfoSection(title: "Why is this so important?",
                                      icon: "info.circle.fill", color: block.type.color,
                                      content: block.type.whyItMatters)

                    if canReschedule && block.type != .flight {
                        Button(action: onReschedule) {
                            Label("Reschedule", systemImage: "calendar.badge.clock")
                                .font(.headline)
                                .foregroundStyle(Color(hex: "#E8682A"))
                                .frame(maxWidth: .infinity).frame(height: 52)
                                .background(Color(hex: "#E8682A").opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle(block.type.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.medium)
                        .foregroundStyle(Color(hex: "#E8682A"))
                }
            }
        }
    }
}

private struct DetailInfoSection: View {
    let title: String
    let icon: String
    let color: Color
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)

            Text(content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Previews
#Preview("Jakarta → Paris") {
    let cal = Calendar.current
    let now = cal.startOfDay(for: Date())
    func makeDate(_ day: Int, _ hour: Int, _ min: Int = 0) -> Date {
        cal.date(byAdding: .day, value: day, to: now)
            .flatMap { cal.date(bySettingHour: hour, minute: min, second: 0, of: $0) }
        ?? now
    }
    let leg = FlightLeg(origin: "CGK", destination: "CDG",
                        departure: makeDate(0, 17), arrival: makeDate(1, 6))
    let blocks: [TimelineBlock] = [
        TimelineBlock(type: .seekLight, startTime: makeDate(-1, 7), endTime: makeDate(-1, 9), title: "Seek Light"),
        TimelineBlock(type: .caffeine, startTime: makeDate(-1, 8), endTime: makeDate(-1, 9), title: "Caffeine"),
        TimelineBlock(type: .flight, startTime: makeDate(0, 17), endTime: makeDate(1, 6), title: "Flight CGK → CDG"),
        TimelineBlock(type: .sleep, startTime: makeDate(0, 19), endTime: makeDate(0, 22, 30), title: "Go to Sleep"),
        TimelineBlock(type: .avoidLight, startTime: makeDate(1, 12), endTime: makeDate(1, 15), title: "Avoid Light"),
        TimelineBlock(type: .noCaffeine, startTime: makeDate(1, 15), endTime: makeDate(1, 20), title: "No Caffeine"),
        TimelineBlock(type: .sleep, startTime: makeDate(1, 22), endTime: makeDate(2, 6), title: "Go to Sleep"),
    ]
    var trip = Trip(flights: [leg], blocks: blocks)
    trip.originCity = "Jakarta"; trip.destinationCity = "Paris"
    return NavigationStack { ScheduleView(trip: trip) }
        .environmentObject(AppState())
}

#Preview("Block Types") {
    let cal = Calendar.current
    let now = cal.startOfDay(for: Date())
    let blocks: [TimelineBlock] = BlockType.allCases.enumerated().map { i, type in
        let start = cal.date(byAdding: .hour, value: i * 2, to: now) ?? now
        let end = cal.date(byAdding: .hour, value: i * 2 + 2, to: now) ?? now
        return TimelineBlock(type: type, startTime: start, endTime: end, title: type.rawValue)
    }
    let trip = Trip(flights: [], blocks: blocks)
    return NavigationStack { ScheduleView(trip: trip) }
        .environmentObject(AppState())
}

#Preview("Empty Schedule") {
    let trip = Trip(flights: [], blocks: [])
    return NavigationStack { ScheduleView(trip: trip) }
        .environmentObject(AppState())
}
