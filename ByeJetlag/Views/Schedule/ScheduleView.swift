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

// MARK: - Day Section (internal grouping, not a domain model)

/// Groups `TimelineBlock`s into per-day rendering sections.
/// This is a **view-local layout helper**, NOT a domain model — it exists only to
/// organize blocks for the positioned timeline grid and is derived from `[TimelineBlock]`.
private struct DaySection: Identifiable {
    let id: String
    let dateLabel: String
    let localTimeLabel: String
    let startHour: Double
    let endHour: Double
    let blocks: [PositionedBlock]
}

/// A `TimelineBlock` annotated with hour-based offsets for timeline positioning.
private struct PositionedBlock: Identifiable {
    let id: UUID
    let block: TimelineBlock
    let startHour: Double
    let durationHours: Double

    var endHour: Double { startHour + durationHours }
}

// MARK: - Section Builder

/// Converts `[TimelineBlock]` into `[DaySection]` for timeline rendering.
/// Each section covers a contiguous range of hours within one calendar day.
private func buildSections(from blocks: [TimelineBlock]) -> [DaySection] {
    guard !blocks.isEmpty else { return [] }

    let sorted = blocks.sorted { $0.startTime < $1.startTime }
    let calendar = Calendar.current

    // Group blocks by calendar day of their startTime
    var dayGroups: [(date: Date, blocks: [TimelineBlock])] = []
    for block in sorted {
        let dayStart = calendar.startOfDay(for: block.startTime)
        if let lastIdx = dayGroups.indices.last, dayGroups[lastIdx].date == dayStart {
            dayGroups[lastIdx].blocks.append(block)
        } else {
            dayGroups.append((date: dayStart, blocks: [block]))
        }
    }

    let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE, dd MMM"
        return f
    }()

    let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    var sections: [DaySection] = []

    for (index, group) in dayGroups.enumerated() {
        let dayStart = group.date

        // Convert blocks to positioned blocks with hour offsets
        let positioned: [PositionedBlock] = group.blocks.map { block in
            let startInterval = block.startTime.timeIntervalSince(dayStart)
            let startH = startInterval / 3600.0
            let durationH = block.endTime.timeIntervalSince(block.startTime) / 3600.0
            return PositionedBlock(
                id: block.id,
                block: block,
                startHour: startH,
                durationHours: max(durationH, 0)
            )
        }

        guard let minHour = positioned.map(\.startHour).min(),
              let maxHour = positioned.map(\.endHour).max() else { continue }

        let sectionStartHour = floor(minHour)
        let sectionEndHour = ceil(maxHour)

        let dateLabel = dateFormatter.string(from: dayStart)
        let timeLabel = timeFormatter.string(from: group.blocks.first?.startTime ?? dayStart)

        sections.append(DaySection(
            id: "\(index)-\(dateLabel)",
            dateLabel: dateLabel,
            localTimeLabel: timeLabel,
            startHour: sectionStartHour,
            endHour: max(sectionEndHour, sectionStartHour + 1), // at least 1 hour range
            blocks: positioned
        ))
    }

    return sections
}

// MARK: - ScheduleView
struct ScheduleView: View {
    let trip: Trip
    @State private var selectedBlock: TimelineBlock?
    @State private var showDetail = false
    @State private var showReschedule = false
    @State private var rescheduleStart = Date()
    @State private var rescheduleEnd   = Date()

    private var sections: [DaySection] {
        buildSections(from: trip.blocks)
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showReschedule = true } label: {
                    Text("Align Sleep")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .overlay(Capsule().stroke(Color(.separator), lineWidth: 1))
                }
            }
        }
        .sheet(isPresented: $showDetail) {
            if let block = selectedBlock {
                BlockDetailSheet(block: block) {
                    showDetail = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showReschedule = true }
                }
            }
        }
        .sheet(isPresented: $showReschedule) {
            RescheduleSheet(sleepStart: $rescheduleStart, sleepEnd: $rescheduleEnd) { }
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
private struct SectionHeader: View {
    let section: DaySection

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text(section.dateLabel)
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            Spacer()

            Text(section.localTimeLabel)
                .font(.footnote)
                .foregroundStyle(Color(.secondaryLabel))
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 6)
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

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Time column
            ZStack(alignment: .topTrailing) {
                Color.clear
                    .frame(width: TL.timeColumnWidth, height: totalHeight)
                ForEach(hourTicks, id: \.self) { hour in
                    let offset = CGFloat(Double(hour) - section.startHour) * TL.hourHeight
                    Text(String(format: "%02d:00", hour % 24))
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

                    if block.type != .flight {
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
}

#Preview("Empty Schedule") {
    let trip = Trip(flights: [], blocks: [])
    return NavigationStack { ScheduleView(trip: trip) }
}
