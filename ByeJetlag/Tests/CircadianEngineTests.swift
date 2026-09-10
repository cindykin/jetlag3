#if canImport(XCTest)
import Foundation
import XCTest
@testable import ByeJetlag

final class CircadianEngineTests: XCTestCase {
    func testCBTminIsTwoAndAHalfHoursBeforeWakeTime() {
        let wakeTime = Date(timeIntervalSinceReferenceDate: 100_000)

        XCTAssertEqual(
            CircadianEngine.cbtMin(from: wakeTime),
            wakeTime.addingTimeInterval(-2.5 * 60 * 60)
        )
    }

    func testShiftDailyCapsAtOneHourAndUsesPreparationDays() {
        XCTAssertEqual(CircadianEngine.shiftDaily(totalGapHours: 1.5, preparationDays: 3), 0.5)
        XCTAssertEqual(CircadianEngine.shiftDaily(totalGapHours: 9, preparationDays: 3), 1)
    }

    func testDirectionNormalizesOffsetGapsGreaterThanTwelveHours() {
        XCTAssertEqual(CircadianEngine.direction(originUTCOffset: 0, destinationUTCOffset: 9 * 3_600), .eastward)
        XCTAssertEqual(CircadianEngine.direction(originUTCOffset: 0, destinationUTCOffset: 15 * 3_600), .westward)
        XCTAssertEqual(CircadianEngine.direction(originUTCOffset: 0, destinationUTCOffset: -15 * 3_600), .eastward)
    }

    func testGenerateBlocksEastwardIncludesDestinationNapAndDailyCaffeineWindow() {
        // Input: GMT → Asia/Tokyo (+9h), departure 2026-01-10 10:00 GMT,
        // generated on departure day (0 preparation days), sleep 22:00–06:00 GMT.
        // Expected destination day-0: wake 06:00 JST; caffeine 06:00–14:00 JST
        // (sleep 22:00 JST minus 8h), nap 13:00–13:30 JST.
        let origin = TimeZone(secondsFromGMT: 0)!
        let destination = TimeZone(identifier: "Asia/Tokyo")!
        let departure = date(2026, 1, 10, 10, 0, in: origin)
        let profile = UserProfile(
            useCaffeine: true,
            sleepTime: date(2026, 1, 1, 22, 0, in: origin),
            wakeTime: date(2026, 1, 2, 6, 0, in: origin)
        )
        let blocks = CircadianEngine.generateBlocks(
            for: [FlightLeg(origin: "LON", destination: "TYO", departure: departure, arrival: departure.addingTimeInterval(12 * 60 * 60))],
            profile: profile,
            originTimeZone: origin,
            destinationTimeZone: destination,
            now: date(2026, 1, 10, 9, 0, in: origin)
        )

        XCTAssertTrue(blocks.contains { $0.type == .caffeine && $0.startTime == date(2026, 1, 10, 6, 0, in: destination) && $0.endTime == date(2026, 1, 10, 14, 0, in: destination) })
        XCTAssertTrue(blocks.contains { $0.type == .nap && $0.startTime == date(2026, 1, 10, 13, 0, in: destination) && $0.endTime == date(2026, 1, 10, 13, 30, in: destination) })
        XCTAssertTrue(blocks.filter { $0.type == .nap }.allSatisfy { $0.endTime.timeIntervalSince($0.startTime) <= 90 * 60 })
    }

    func testGenerateBlocksWestwardIncludesDestinationNapAndDailyCaffeineWindow() {
        // Input: Asia/Tokyo → GMT (-9h), departure 2026-01-10 10:00 JST,
        // generated on departure day (0 preparation days), sleep 22:00–06:00 JST.
        // Expected destination day-0: wake 06:00 GMT; caffeine 06:00–14:00 GMT
        // (sleep 22:00 GMT minus 8h), nap 13:00–13:30 GMT.
        let origin = TimeZone(identifier: "Asia/Tokyo")!
        let destination = TimeZone(secondsFromGMT: 0)!
        let departure = date(2026, 1, 10, 10, 0, in: origin)
        let profile = UserProfile(
            useCaffeine: true,
            sleepTime: date(2026, 1, 1, 22, 0, in: origin),
            wakeTime: date(2026, 1, 2, 6, 0, in: origin)
        )
        let blocks = CircadianEngine.generateBlocks(
            for: [FlightLeg(origin: "TYO", destination: "LON", departure: departure, arrival: departure.addingTimeInterval(12 * 60 * 60))],
            profile: profile,
            originTimeZone: origin,
            destinationTimeZone: destination,
            now: date(2026, 1, 10, 9, 0, in: origin)
        )

        XCTAssertTrue(blocks.contains { $0.type == .caffeine && $0.startTime == date(2026, 1, 10, 6, 0, in: destination) && $0.endTime == date(2026, 1, 10, 14, 0, in: destination) })
        XCTAssertTrue(blocks.contains { $0.type == .nap && $0.startTime == date(2026, 1, 10, 13, 0, in: destination) && $0.endTime == date(2026, 1, 10, 13, 30, in: destination) })
        XCTAssertTrue(blocks.filter { $0.type == .nap }.allSatisfy { $0.endTime.timeIntervalSince($0.startTime) <= 90 * 60 })
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, in timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
#endif
