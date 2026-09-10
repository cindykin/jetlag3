import SwiftUI

// MARK: - Mock Data Model (backend-ready: Identifiable + Decodable-friendly)
import SwiftUI

// MARK: - Activity Type

enum ActivityType: String, CaseIterable, Codable {
    case flight = "Flight"
    case caffeine = "Caffeine"
    case avoidCaffeine = "Avoid Caffeine"
    case seekLight = "Seek Light"
    case avoidLight = "Avoid Light"
    case sleep = "Go to Sleep"
    case nap = "Take a nap\n(If can)"
    case melatonin = "Take melantonin\n& Go to Sleep"

    var accentColor: Color {
        switch self {
        case .flight: return Color("#E8682A")
        case .caffeine: return Color("#7B4F2E")
        case .avoidCaffeine, .avoidLight: return Color(.systemGray3)
        case .seekLight: return Color("#E8A020")
        case .sleep, .melatonin: return Color("#4A7FD4")
        case .nap: return Color("#7BAED4")
        }
    }

    var bgColor: Color {
        switch self {
        case .flight: return Color("#E8682A").opacity(0.10)
        case .caffeine: return Color("#7B4F2E").opacity(0.09)
        case .avoidCaffeine, .avoidLight: return Color(.systemGray6)
        case .seekLight: return Color("#E8A020").opacity(0.12)
        case .sleep, .melatonin: return Color("#4A7FD4").opacity(0.10)
        case .nap: return Color("#7BAED4").opacity(0.10)
        }
    }

    var primaryIcon: String {
        switch self {
        case .flight: return "airplane"
        case .caffeine, .avoidCaffeine: return "cup.and.saucer.fill"
        case .seekLight, .avoidLight: return "sun.max.fill"
        case .sleep, .nap, .melatonin: return "bed.double.fill"
        }
    }

    var badgeIcon: String? {
        switch self {
        case .avoidCaffeine, .avoidLight:
            return "xmark.circle.fill"
        default:
            return nil
        }
    }

    var showSunBadge: Bool { self == .nap }
    var showPillBadge: Bool { self == .melatonin }
}

// MARK: - Activity Item

struct ActivityItem: Identifiable, Codable {
    var id: UUID = UUID()
    var type: ActivityType
    var startHour: Double
    var durationHours: Double
    var timezone: String
    var date: String

    var endHour: Double { startHour + durationHours }

    init(_ type: ActivityType, start: Double, duration: Double, tz: String, date: String) {
        self.type = type
        self.startHour = start
        self.durationHours = duration
        self.timezone = tz
        self.date = date
    }
}

// MARK: - Timeline Section

struct TimelineSection: Identifiable {
    var id: String { "\(dateLabel)-\(timezoneLabel ?? "orig")" }

    var dateLabel: String
    var timezoneLabel: String?
    var localTimeLabel: String
    var startHour: Double
    var endHour: Double
    var activities: [ActivityItem]
    var isDividerHighEmphasis: Bool = false

    // ✅ Safer initializer (order flexible)
    init(
        dateLabel: String,
        timezoneLabel: String?,
        localTimeLabel: String,
        startHour: Double,
        endHour: Double,
        activities: [ActivityItem],
        isDividerHighEmphasis: Bool = false
    ) {
        self.dateLabel = dateLabel
        self.timezoneLabel = timezoneLabel
        self.localTimeLabel = localTimeLabel
        self.startHour = startHour
        self.endHour = endHour
        self.activities = activities
        self.isDividerHighEmphasis = isDividerHighEmphasis
    }
}

// MARK: - Mock Schedule

enum MockSchedule {
    static let sections: [TimelineSection] = [

        TimelineSection(
            dateLabel: "Tue, 10 April",
            timezoneLabel: nil,
            localTimeLabel: "Jakarta 17:00",
            startHour: 17,
            endHour: 24,
            activities: [
                ActivityItem(.flight, start: 17.0, duration: 7.0, tz: "Jakarta", date: "1"),
                ActivityItem(.caffeine, start: 17.5, duration: 1.5, tz: "Jakarta", date: "1"),
                ActivityItem(.sleep, start: 19.25, duration: 3.5, tz: "Jakarta", date: "1"),
                ActivityItem(.caffeine, start: 22.0, duration: 1.0, tz: "Jakarta", date: "1"),
                ActivityItem(.nap, start: 22.5, duration: 1.0, tz: "Jakarta", date: "1"),
            ]
        ),

        TimelineSection(
            dateLabel: "Tue, 10 April",
            timezoneLabel: nil,
            localTimeLabel: "Jakarta 00:00",
            startHour: 0,
            endHour: 3.5,
            activities: [
                ActivityItem(.flight, start: 0.0, duration: 3.5, tz: "Jakarta", date: "2"),
                ActivityItem(.sleep, start: 0.0, duration: 3.5, tz: "Jakarta", date: "2"),
            ]
        ),

        TimelineSection(
            dateLabel: "Wed, 11 April",
            timezoneLabel: "Doha Time",
            localTimeLabel: "00:00",
            startHour: 0,
            endHour: 9.5,
            activities: [
                ActivityItem(.flight, start: 0.0, duration: 2.0, tz: "Doha", date: "3"),
                ActivityItem(.flight, start: 2.0, duration: 7.5, tz: "Doha", date: "3"),
                ActivityItem(.seekLight, start: 3.0, duration: 5.0, tz: "Doha", date: "3"),
                ActivityItem(.sleep, start: 8.0, duration: 1.5, tz: "Doha", date: "3"),
            ],
            isDividerHighEmphasis: true
        ),

        TimelineSection(
            dateLabel: "Thu, 11 April",
            timezoneLabel: "Paris Time",
            localTimeLabel: "09:00",
            startHour: 9,
            endHour: 24,
            activities: [
                ActivityItem(.caffeine, start: 10.0, duration: 1.0, tz: "Paris", date: "4"),
                ActivityItem(.avoidLight, start: 10.5, duration: 0.75, tz: "Paris", date: "4"),
                ActivityItem(.nap, start: 11.75, duration: 1.5, tz: "Paris", date: "4"),
                ActivityItem(.caffeine, start: 13.75, duration: 1.0, tz: "Paris", date: "4"),
                ActivityItem(.avoidCaffeine, start: 15.5, duration: 1.5, tz: "Paris", date: "4"),
                ActivityItem(.seekLight, start: 19.5, duration: 3.5, tz: "Paris", date: "4"),
                ActivityItem(.avoidLight, start: 21.75, duration: 1.5, tz: "Paris", date: "4"),
            ],
            isDividerHighEmphasis: true
        ),

        TimelineSection(
            dateLabel: "Fri, 12 April",
            timezoneLabel: nil,
            localTimeLabel: "Paris 00:00",
            startHour: 0,
            endHour: 5.5,
            activities: [
                ActivityItem(.sleep, start: 0.5, duration: 5.0, tz: "Paris", date: "5"),
            ]
        ),
    ]
}

// MARK: - Layout Constants
private enum TL {
    static let hourHeight: CGFloat        = 56
    static let timeColumnWidth: CGFloat   = 44
    static let blockCornerRadius: CGFloat = 14
    static let accentBarWidth: CGFloat    = 4
    static let blockMinHeight: CGFloat    = 38
    static let iconSize: CGFloat          = 22
}

// MARK: - ScheduleView
struct ScheduleView: View {
    let trip: Trip
    @State private var selectedActivity: ActivityItem?
    @State private var showDetail = false
    @State private var showReschedule = false
    @State private var rescheduleStart = Date()
    @State private var rescheduleEnd   = Date()

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(MockSchedule.sections) { section in
                        SectionView(section: section) { item in
                            selectedActivity = item
                            showDetail = true
                        }
                    }
                    EndOfPlanFooter().padding(.bottom, 72)
                }
            }

            TapHintPill().padding(.bottom, 20)
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
            if let a = selectedActivity {
                ActivityDetailSheet(activity: a) {
                    showDetail = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { showReschedule = true }
                }
            }
        }
        .sheet(isPresented: $showReschedule) {
            RescheduleSheet(sleepStart: $rescheduleStart, sleepEnd: $rescheduleEnd) { }
        }
    }
}

// MARK: - Section View
private struct SectionView: View {
    let section: TimelineSection
    let onTap: (ActivityItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            SectionHeader(section: section)
            TimelineGrid(section: section, onTap: onTap)
        }
    }
}

// MARK: - Section Header
private struct SectionHeader: View {
    let section: TimelineSection

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text(section.dateLabel)
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            Spacer()

            if let tz = section.timezoneLabel {
                HStack(spacing: 4) {
                    Image(systemName: "clock.arrow.2.circlepath")
                        .font(.system(size: 10, weight: .medium))
                    Text(tz)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(
                    section.isDividerHighEmphasis
                    ? Color("#E8682A")
                    : Color(.secondaryLabel)
                )
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(
                    Capsule().fill(
                        section.isDividerHighEmphasis
                        ? Color("#E8682A").opacity(0.10)
                        : Color(.secondarySystemBackground)
                    )
                )
                .padding(.trailing, 8)
            }

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
    let section: TimelineSection
    let onTap: (ActivityItem) -> Void

    private var hourTicks: [Int] {
        let s = Int(floor(section.startHour))
        let e = Int(ceil(section.endHour))
        return Array(s...e)
    }
    private var totalHeight: CGFloat {
        CGFloat(section.endHour - section.startHour) * TL.hourHeight
    }
    private var columns: [[ActivityItem]] { layoutColumns(section.activities) }

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

                // Activity columns
                HStack(alignment: .top, spacing: 4) {
                    ForEach(columns.indices, id: \.self) { ci in
                        let col = columns[ci]
                        ZStack(alignment: .topLeading) {
                            Color.clear.frame(maxWidth: .infinity).frame(height: totalHeight)
                            ForEach(col) { item in
                                let top = CGFloat(item.startHour - section.startHour) * TL.hourHeight
                                let h   = max(CGFloat(item.durationHours) * TL.hourHeight, TL.blockMinHeight)
                                ActivityBlock(activity: item)
                                    .frame(maxWidth: .infinity).frame(height: h)
                                    .offset(y: top)
                                    .onTapGesture { onTap(item) }
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
private func layoutColumns(_ items: [ActivityItem]) -> [[ActivityItem]] {
    var columns: [[ActivityItem]] = []
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

// MARK: - Activity Block
private struct ActivityBlock: View {
    let activity: ActivityItem

    var body: some View {
        HStack(spacing: 0) {
            // Left accent bar
            Rectangle()
                .fill(activity.type.accentColor)
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

                Text(activity.type.rawValue)
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
        .background(activity.type.bgColor)
        .clipShape(RoundedRectangle(cornerRadius: TL.blockCornerRadius))
    }

    @ViewBuilder
    private var iconCluster: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(systemName: activity.type.primaryIcon)
                .font(.system(size: TL.iconSize, weight: .regular))
                .foregroundStyle(activity.type.accentColor)

            if let badge = activity.type.badgeIcon {
                Image(systemName: badge)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(.systemGray2))
                    .background(Color(.systemBackground).clipShape(Circle()))
                    .offset(x: 7, y: 7)
            }
            if activity.type.showSunBadge {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color("#E8A020"))
                    .background(Color(.systemBackground).clipShape(Circle()))
                    .offset(x: 9, y: -9)
            }
            if activity.type.showPillBadge {
                Image(systemName: "pills.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color("#9B59B6"))
                    .background(Color(.systemBackground).clipShape(Circle()))
                    .offset(x: 9, y: -9)
            }
        }
        .frame(width: TL.iconSize + 10, height: TL.iconSize + 10)
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
                .foregroundStyle(Color("#E8A020"))
            Text("Yay you did it!! Enjoy your day!")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color("#E8A020").opacity(0.08))
    }
}

// MARK: - Activity Detail Sheet
struct ActivityDetailSheet: View {
    let activity: ActivityItem
    let onReschedule: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var bt: BlockType {
        switch activity.type {
        case .flight:        return .flight
        case .caffeine:      return .caffeine
        case .avoidCaffeine: return .noCaffeine
        case .seekLight:     return .seekLight
        case .avoidLight:    return .avoidLight
        case .sleep:         return .sleep
        case .nap:           return .nap
        case .melatonin:     return .melatonin
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Header
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(activity.type.accentColor.opacity(0.13))
                                .frame(width: 56, height: 56)
                            Image(systemName: activity.type.primaryIcon)
                                .font(.system(size: 26, weight: .regular))
                                .foregroundStyle(activity.type.accentColor)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(bt.rawValue)
                                .font(.title3).fontWeight(.semibold)
                            Text("\"\(bt.rawValue) at your scheduled time\"")
                                .font(.subheadline).foregroundStyle(.secondary).italic()
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(activity.type.accentColor.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    DetailInfoSection(title: "What I should do?",
                                      icon: "checkmark.circle.fill", color: .green,
                                      content: bt.whatToDo)
                    DetailInfoSection(title: "I can't do it, what should I do?",
                                      icon: "arrow.triangle.2.circlepath", color: Color("#4A90E2"),
                                      content: bt.alternatives)
                    DetailInfoSection(title: "Why is this so important?",
                                      icon: "info.circle.fill", color: activity.type.accentColor,
                                      content: bt.whyItMatters)

                    if activity.type != .flight {
                        Button(action: onReschedule) {
                            Label("Reschedule", systemImage: "calendar.badge.clock")
                                .font(.headline)
                                .foregroundStyle(Color("#E8682A"))
                                .frame(maxWidth: .infinity).frame(height: 52)
                                .background(Color("#E8682A").opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle(bt.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.medium)
                        .foregroundStyle(Color("#E8682A"))
                }
            }
        }
    }
}
private struct DetailInfoSection: View {
    let title: String
    let icon: String
    let color: Color
    let content: String   // ✅ renamed

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)

            Text(content)   // ✅ updated here
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
    let leg = FlightLeg(origin: "CGK", destination: "CDG",
                        departure: Date(), arrival: Date().addingTimeInterval(3600*16))
    var trip = Trip(flights: [leg], blocks: [])
    trip.originCity = "Jakarta"; trip.destinationCity = "Paris"
    return NavigationStack { ScheduleView(trip: trip) }
}

#Preview("Block Types") {
    ScrollView {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(ActivityType.allCases, id: \.rawValue) { t in
                ActivityBlock(activity: ActivityItem(t, start: 0, duration: 2, tz: "", date: ""))
                    .frame(height: 80)
            }
        }.padding(16)
    }
}
