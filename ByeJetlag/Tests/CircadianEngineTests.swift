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
}
