import Foundation

// TEMPORARY DEBUG — remove after the "only Sleep visible" / boundary investigation is
// closed. Formats any Date as UTC ISO8601, regardless of which local timezone it's
// "supposed" to represent, so debug prints below are unambiguous and comparable.
private let debugUTCFormatter: ISO8601DateFormatter = {
    let f = ISO8601DateFormatter()
    f.timeZone = TimeZone(identifier: "UTC")
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f
}()

private func debugUTC(_ date: Date) -> String { debugUTCFormatter.string(from: date) }

// MARK: - Timeline Segment Model
//
// View-local layout data (not a domain model) produced by `buildSections`, consumed by
// `ScheduleView`. Extracted out of the View file (rather than kept `private` there) so the
// boundary/split logic below can be covered by XCTest.

/// A visual slice of a `TimelineBlock`, clipped to the segment it's rendered in.
/// A single block (e.g. an 8-hour Sleep block that crosses midnight) can produce more
/// than one `PositionedBlock` — one per segment it overlaps — each with its own `id` so
/// SwiftUI can diff them independently, but all pointing back to the same `sourceBlockID`
/// / `block` so tap-to-detail always opens the original, unsplit block.
struct PositionedBlock: Identifiable {
    let id: UUID
    let sourceBlockID: UUID
    let block: TimelineBlock
    let startHour: Double
    let durationHours: Double

    var endHour: Double { startHour + durationHours }
}

struct TimezoneDividerInfo {
    let date: Date
    let timeZone: TimeZone
    let cityName: String?
}

/// Groups `PositionedBlock`s into per-segment rendering sections.
/// This is a **view-local layout helper**, NOT a domain model.
struct DaySection: Identifiable {
    let id: String
    let dateLabel: String
    let localTimeLabel: String
    let startHour: Double
    let endHour: Double
    let blocks: [PositionedBlock]
    let divider: TimezoneDividerInfo?
}

// MARK: - Timeline Boundaries
//
// Doc: 04_ALGORITHM.md Section 9 / 05_DESIGN_SYSTEM.md Section 5.
//
// The timeline is divided into segments by "boundary instants" computed independently of
// any block — NOT by grouping blocks by their startTime's calendar day. Grouping by
// block.startTime silently hid a bug: a block crossing a boundary (e.g. a Sleep block
// spanning midnight) was never split, so the midnight divider for that span never appeared.

/// Why a segment begins: the very first instant of the trip, a local midnight with no
/// timezone change, or a flight arrival into a genuinely different timezone.
enum BoundaryKind: Equatable {
    case tripStart
    case midnight
    case timezoneArrival(cityName: String)
}

struct TimelineBoundary: Equatable {
    let kind: BoundaryKind
    let instant: Date
    let timeZone: TimeZone
}

/// Returns the timezone that is actually "in effect" at a given instant along the trip:
/// the origin airport's timezone before the first departure, and the destination airport's
/// timezone from the moment that leg arrives onward. This mirrors the same logic
/// `CircadianEngine` already uses internally, so the timeline renders in the same local
/// time the algorithm reasoned about — never the device's own timezone.
func activeTimeZone(at date: Date, flights: [FlightLeg]) -> TimeZone {
    guard let firstFlight = flights.first else { return .current }
    var tz = TimeZone(identifier: firstFlight.originTimeZoneID) ?? .current
    for flight in flights.sorted(by: { $0.arrival < $1.arrival }) {
        if date >= flight.arrival, let destinationTZ = TimeZone(identifier: flight.destinationTimeZoneID) {
            tz = destinationTZ
        }
    }
    return tz
}

/// Computes every boundary instant that should split the timeline into segments, per
/// 04_ALGORITHM.md Section 9: a genuine timezone-changing flight arrival, or local
/// midnight (evaluated in whichever timezone is active at that point — never the device's).
/// Computed purely from `flights` + the trip's overall time range, independent of
/// individual block start/end times, so a block overlapping a boundary gets split later
/// rather than hiding the boundary.
func computeBoundaries(tripStart: Date, tripEnd: Date, flights: [FlightLeg]) -> [TimelineBoundary] {
    guard tripEnd > tripStart else { return [] }

    // Flight arrivals that genuinely change the active timezone, clipped to the trip range.
    let tzChanges: [(instant: Date, cityName: String, timeZone: TimeZone)] = flights.compactMap { flight in
        guard let originTZ = TimeZone(identifier: flight.originTimeZoneID),
              let destinationTZ = TimeZone(identifier: flight.destinationTimeZoneID),
              originTZ.identifier != destinationTZ.identifier,
              flight.arrival > tripStart, flight.arrival < tripEnd
        else { return nil }
        return (flight.arrival, flight.destination, destinationTZ)
    }.sorted { $0.instant < $1.instant }

    var boundaries: [TimelineBoundary] = [
        TimelineBoundary(kind: .tripStart, instant: tripStart, timeZone: activeTimeZone(at: tripStart, flights: flights))
    ]
    boundaries += tzChanges.map {
        TimelineBoundary(kind: .timezoneArrival(cityName: $0.cityName), instant: $0.instant, timeZone: $0.timeZone)
    }

    // Each tz-change instant closes one contiguous "same timezone" span and opens the next.
    // Walk each span separately so every midnight boundary is computed in the ONE timezone
    // that's actually active throughout that span (never the device's).
    let spanStarts = [tripStart] + tzChanges.map(\.instant) + [tripEnd]
    for i in 0..<(spanStarts.count - 1) {
        let spanStart = spanStarts[i]
        let spanEnd = spanStarts[i + 1]
        let tz = activeTimeZone(at: spanStart, flights: flights)
        var calendar = Calendar.current
        calendar.timeZone = tz

        var cursor = spanStart
        while let nextMidnight = calendar.nextDate(
            after: cursor,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ), nextMidnight < spanEnd {
            boundaries.append(TimelineBoundary(kind: .midnight, instant: nextMidnight, timeZone: tz))
            cursor = nextMidnight
        }
    }

    let sortedBoundaries = boundaries.sorted { $0.instant < $1.instant }

    // TEMPORARY DEBUG — remove after investigation.
    print("🐛 [computeBoundaries] flights (\(flights.count)):")
    for flight in flights {
        print("""
        🐛   \(flight.origin) → \(flight.destination) \
        | originTZ=\(flight.originTimeZoneID) destTZ=\(flight.destinationTimeZoneID) \
        | departure(UTC)=\(debugUTC(flight.departure)) arrival(UTC)=\(debugUTC(flight.arrival))
        """)
    }
    print("🐛 [computeBoundaries] boundaries (\(sortedBoundaries.count)), sorted:")
    for boundary in sortedBoundaries {
        print("🐛   instant(UTC)=\(debugUTC(boundary.instant)) kind=\(boundary.kind) timeZone=\(boundary.timeZone.identifier)")
    }

    return sortedBoundaries
}

/// Converts `[TimelineBlock]` into `[DaySection]` for timeline rendering. Segments are
/// defined by `computeBoundaries`, not by grouping blocks — any block overlapping more
/// than one segment (e.g. a Sleep block spanning midnight) is split into one
/// `PositionedBlock` piece per segment it touches, clipped to that segment's hour range.
func buildSections(from blocks: [TimelineBlock], flights: [FlightLeg]) -> [DaySection] {
    guard !blocks.isEmpty,
          let tripStart = blocks.map(\.startTime).min(),
          let tripEnd = blocks.map(\.endTime).max()
    else { return [] }

    // TEMPORARY DEBUG — remove after investigation.
    print("🐛 [buildSections] tripStart(UTC)=\(debugUTC(tripStart)) tripEnd(UTC)=\(debugUTC(tripEnd)) totalBlocks=\(blocks.count)")
    print("🐛 [buildSections] first 5 blocks (of \(blocks.count)), sorted by startTime:")
    let sortedForDebug = blocks.sorted { $0.startTime < $1.startTime }
    for block in sortedForDebug.prefix(5) {
        print("🐛   type=\(block.type) startTime(UTC)=\(debugUTC(block.startTime)) endTime(UTC)=\(debugUTC(block.endTime))")
    }

    let boundaries = computeBoundaries(tripStart: tripStart, tripEnd: tripEnd, flights: flights)
    guard !boundaries.isEmpty else { return [] }

    var sections: [DaySection] = []

    for (index, boundary) in boundaries.enumerated() {
        let segmentStart = boundary.instant
        let segmentEnd = index + 1 < boundaries.count ? boundaries[index + 1].instant : tripEnd
        guard segmentEnd > segmentStart else { continue }

        let positioned: [PositionedBlock] = blocks.compactMap { block in
            let pieceStart = max(block.startTime, segmentStart)
            let pieceEnd = min(block.endTime, segmentEnd)
            guard pieceEnd > pieceStart else { return nil }
            return PositionedBlock(
                id: UUID(),
                sourceBlockID: block.id,
                block: block,
                startHour: pieceStart.timeIntervalSince(segmentStart) / 3600.0,
                durationHours: pieceEnd.timeIntervalSince(pieceStart) / 3600.0
            )
        }
        guard !positioned.isEmpty else { continue }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM"
        dateFormatter.timeZone = boundary.timeZone

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.timeZone = boundary.timeZone

        let minHour = positioned.map(\.startHour).min() ?? 0
        let maxHour = positioned.map(\.endHour).max() ?? 1
        let sectionStartHour = floor(minHour)
        let sectionEndHour = ceil(maxHour)

        sections.append(DaySection(
            id: "\(index)-\(Int(boundary.instant.timeIntervalSince1970))",
            dateLabel: dateFormatter.string(from: segmentStart),
            localTimeLabel: timeFormatter.string(from: segmentStart),
            startHour: sectionStartHour,
            endHour: max(sectionEndHour, sectionStartHour + 1), // at least 1 hour range
            blocks: positioned,
            divider: dividerInfo(for: boundary)
        ))
    }

    return sections
}

/// Every segment always has a header (date + local time — rendered unconditionally by
/// `SectionHeader` in `ScheduleView`). The additional `TimezoneDividerView` badge is shown
/// ONLY when this segment was opened by a genuine timezone-changing arrival — never for a
/// plain midnight boundary, and never for the very first segment (which isn't a boundary
/// the person "crossed", it's just where the trip starts).
func dividerInfo(for boundary: TimelineBoundary) -> TimezoneDividerInfo? {
    switch boundary.kind {
    case .tripStart:
        return nil
    case .midnight:
        return TimezoneDividerInfo(date: boundary.instant, timeZone: boundary.timeZone, cityName: nil)
    case .timezoneArrival(let cityName):
        return TimezoneDividerInfo(date: boundary.instant, timeZone: boundary.timeZone, cityName: cityName)
    }
}
