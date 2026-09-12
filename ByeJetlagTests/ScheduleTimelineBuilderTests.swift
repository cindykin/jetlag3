import XCTest
import Foundation
@testable import ByeJetlag

final class ScheduleTimelineBuilderTests: XCTestCase {

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int, _ min: Int = 0, timeZoneID: String) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZoneID)!
        return calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    // MARK: - Bug #1: Sleep block crossing midnight must be split, not silently skipped

    /// A Sleep block spanning midnight, with no flight/timezone change involved, must be
    /// split into 2 `PositionedBlock` pieces landing in 2 different `DaySection`s — one
    /// before midnight, one after. This is exactly the case the old block.startTime-based
    /// grouping missed (04_ALGORITHM.md Section 9, condition 2).
    func testSleepBlockCrossingMidnightIsSplitAcrossTwoSegments() {
        let sleepStart = date(2026, 6, 10, 22, 0, timeZoneID: "UTC")
        let sleepEnd   = date(2026, 6, 11, 6, 0, timeZoneID: "UTC")
        let sleep = TimelineBlock(type: .sleep, startTime: sleepStart, endTime: sleepEnd, title: "Go to Sleep")

        let sections = buildSections(from: [sleep], flights: [])

        XCTAssertEqual(sections.count, 2, "Sleep block crossing midnight must produce 2 segments")

        guard sections.count == 2 else { return }
        let firstPieces = sections[0].blocks
        let secondPieces = sections[1].blocks

        XCTAssertEqual(firstPieces.count, 1)
        XCTAssertEqual(secondPieces.count, 1)

        // Both pieces must reference the SAME original block so tap-to-detail opens the
        // real, unsplit block — not a fragment.
        XCTAssertEqual(firstPieces[0].sourceBlockID, sleep.id)
        XCTAssertEqual(secondPieces[0].sourceBlockID, sleep.id)
        XCTAssertNotEqual(firstPieces[0].id, secondPieces[0].id, "Each visual piece needs its own identity")

        // The two clipped pieces must add up to the original 8-hour duration.
        XCTAssertEqual(firstPieces[0].durationHours + secondPieces[0].durationHours, 8, accuracy: 0.01)

        // Second segment opens at a plain midnight boundary -> divider with NO city badge.
        XCTAssertNotNil(sections[1].divider)
        XCTAssertNil(sections[1].divider?.cityName)

        // First segment is the trip-start segment, not a boundary the person "crossed" ->
        // no divider rendered above it.
        XCTAssertNil(sections[0].divider)
    }

    // MARK: - Bug #2: divider must not depend on a block starting exactly at flight.arrival

    /// A flight arriving into a genuinely different timezone must open a new segment whose
    /// divider carries the destination city's badge (Section 9, condition 1) — even when no
    /// block happens to start exactly at the arrival instant, which is the case the old
    /// "abs(flight.arrival - blockStart) < 1" check almost always missed.
    func testFlightArrivalIntoNewTimezoneProducesCityBadgeEvenWithoutABlockStartingThere() {
        let departure = date(2026, 6, 10, 17, 0, timeZoneID: "Asia/Jakarta")
        let arrival   = date(2026, 6, 11, 0, 0, timeZoneID: "Europe/Paris")

        let flight = FlightLeg(
            origin: "CGK",
            destination: "CDG",
            originTimeZoneID: "Asia/Jakarta",
            destinationTimeZoneID: "Europe/Paris",
            departure: departure,
            arrival: arrival
        )

        let flightBlock = TimelineBlock(type: .flight, startTime: departure, endTime: arrival, title: "Flight CGK → CDG")
        // Deliberately starts 3 hours AFTER arrival, not exactly at it.
        let laterStart = arrival.addingTimeInterval(3 * 3_600)
        let laterBlock = TimelineBlock(type: .seekLight, startTime: laterStart, endTime: laterStart.addingTimeInterval(3_600), title: "Seek Light")

        let sections = buildSections(from: [flightBlock, laterBlock], flights: [flight])

        let arrivalSection = sections.first { $0.divider?.cityName == "CDG" }
        XCTAssertNotNil(arrivalSection, "Expected a segment whose divider badge names the destination city")
    }

    /// Same-timezone flights (e.g. a domestic connecting leg) must NOT produce a city badge —
    /// only a genuine timezone change should (Section 9, condition 1 explicitly excludes this).
    func testConnectingFlightWithinSameTimezoneProducesNoCityBadge() {
        let departure = date(2026, 6, 10, 8, 0, timeZoneID: "Asia/Jakarta")
        let arrival   = date(2026, 6, 10, 10, 0, timeZoneID: "Asia/Jakarta")

        let domesticLeg = FlightLeg(
            origin: "CGK",
            destination: "DPS",
            originTimeZoneID: "Asia/Jakarta",
            destinationTimeZoneID: "Asia/Jakarta",
            departure: departure,
            arrival: arrival
        )

        let flightBlock = TimelineBlock(type: .flight, startTime: departure, endTime: arrival, title: "Flight CGK → DPS")
        let sections = buildSections(from: [flightBlock], flights: [domesticLeg])

        XCTAssertTrue(sections.allSatisfy { $0.divider?.cityName == nil }, "Same-timezone arrival must never show a city badge")
    }

    // MARK: - Every segment always has a header (dateLabel/localTimeLabel), badge is separate

    func testEverySegmentHasADateAndTimeLabelRegardlessOfDividerType() {
        let sleepStart = date(2026, 6, 10, 22, 0, timeZoneID: "UTC")
        let sleepEnd   = date(2026, 6, 11, 6, 0, timeZoneID: "UTC")
        let sleep = TimelineBlock(type: .sleep, startTime: sleepStart, endTime: sleepEnd, title: "Go to Sleep")

        let sections = buildSections(from: [sleep], flights: [])

        for section in sections {
            XCTAssertFalse(section.dateLabel.isEmpty)
            XCTAssertFalse(section.localTimeLabel.isEmpty)
        }
    }
}
