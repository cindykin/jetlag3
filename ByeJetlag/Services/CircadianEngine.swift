import Foundation

enum Direction: Equatable {
    case eastward
    case westward
}

struct CircadianEngine {
    struct LightWindows {
        let seekLight: DateInterval
        let avoidLight: DateInterval
    }

    static func cbtMin(from wakeTime: Date) -> Date {
        wakeTime.addingTimeInterval(-2.5 * 60 * 60)
    }

    static func shiftDaily(totalGapHours: Double, preparationDays: Int) -> Double {
        guard preparationDays > 0 else { return 0 }
        return min(abs(totalGapHours) / Double(min(preparationDays, 3)), 1)
    }

    static func direction(originUTCOffset: Int, destinationUTCOffset: Int) -> Direction {
        let rawGapHours = Double(destinationUTCOffset - originUTCOffset) / 3_600
        let adjustedGapHours = adjustedOffsetGap(hours: rawGapHours)
        return adjustedGapHours >= 0 ? .eastward : .westward
    }

    static func adjustedOffsetGap(hours rawGapHours: Double) -> Double {
        guard abs(rawGapHours) > 12 else { return rawGapHours }
        return rawGapHours > 0 ? rawGapHours - 24 : rawGapHours + 24
    }

    static func lightWindows(cbtMin: Date, direction: Direction) -> LightWindows {
        switch direction {
        case .eastward:
            return LightWindows(
                seekLight: DateInterval(start: cbtMin, end: cbtMin.addingTimeInterval(4 * 60 * 60)),
                avoidLight: DateInterval(start: cbtMin.addingTimeInterval(-3 * 60 * 60), end: cbtMin)
            )
        case .westward:
            return LightWindows(
                seekLight: DateInterval(start: cbtMin.addingTimeInterval(-4 * 60 * 60), end: cbtMin),
                avoidLight: DateInterval(start: cbtMin, end: cbtMin.addingTimeInterval(3 * 60 * 60))
            )
        }
    }

    static func caffeineCutoff(targetSleep: Date) -> Date {
        targetSleep.addingTimeInterval(-8 * 60 * 60)
    }

    static func generateBlocks(
        for flights: [FlightLeg],
        profile: UserProfile,
        originTimeZone: TimeZone,
        destinationTimeZone: TimeZone,
        now: Date = Date()
    ) -> [TimelineBlock] {
        guard let firstFlight = flights.first, let lastFlight = flights.last else { return [] }

        let originOffset = originTimeZone.secondsFromGMT(for: firstFlight.departure)
        let destinationOffset = destinationTimeZone.secondsFromGMT(for: lastFlight.arrival)
        let travelDirection = direction(
            originUTCOffset: originOffset,
            destinationUTCOffset: destinationOffset
        )
        let gapHours = adjustedOffsetGap(hours: Double(destinationOffset - originOffset) / 3_600)
        let preparationDays = daysUntil(firstFlight.departure, from: now, in: originTimeZone)
        let dailyShift = shiftDaily(totalGapHours: gapHours, preparationDays: preparationDays)
        let recoveryDays = Int(ceil(abs(gapHours) / adaptationRate(for: travelDirection)))

        var blocks: [TimelineBlock] = []
        for dayOffset in -preparationDays...recoveryDays {
            let timeZone = dayOffset < 0 ? originTimeZone : destinationTimeZone
            let day = addingDays(dayOffset, to: firstFlight.departure, in: timeZone)
            let completedShiftDays = min(max(dayOffset + preparationDays, 0), preparationDays)
            let signedShift = Double(completedShiftDays) * dailyShift * (travelDirection == .eastward ? -1 : 1)
            let sleepStart = localTime(
                on: day,
                matching: profile.sleepTime,
                in: timeZone,
                referenceTimeZone: originTimeZone
            )
                .addingTimeInterval(signedShift * 60 * 60)
            let duration = sleepDuration(profile: profile)
            let sleepEnd = sleepStart.addingTimeInterval(duration)
            let wakeTime = sleepStart.addingTimeInterval(-(24 * 60 * 60 - duration))
            let cbt = cbtMin(from: wakeTime)
            let light = lightWindows(cbtMin: cbt, direction: travelDirection)
            let cutoff = caffeineCutoff(targetSleep: sleepStart)
            let napStart = time(on: day, hour: 13, minute: 0, in: destinationTimeZone)
            let sleepType: BlockType = profile.useMelatonin ? .melatonin : .sleep
            let sleepTitle = profile.useMelatonin ? "Take Melatonin & Go to Sleep" : "Go to Sleep"

            var dailyBlocks = [
                TimelineBlock(type: sleepType, startTime: sleepStart, endTime: sleepEnd, title: sleepTitle),
                TimelineBlock(type: .seekLight, startTime: light.seekLight.start, endTime: light.seekLight.end, title: "Seek Light"),
                TimelineBlock(type: .avoidLight, startTime: light.avoidLight.start, endTime: light.avoidLight.end, title: "Avoid Light"),
                TimelineBlock(type: .nap, startTime: napStart, endTime: napStart.addingTimeInterval(30 * 60), title: "Take a Nap"),
                TimelineBlock(type: .noCaffeine, startTime: cutoff, endTime: sleepStart, title: "No Caffeine")
            ]

            if profile.useCaffeine, wakeTime < cutoff {
                dailyBlocks.append(
                    TimelineBlock(type: .caffeine, startTime: wakeTime, endTime: cutoff, title: "Caffeine")
                )
            }
            blocks += dailyBlocks
        }

        blocks += flights.map {
            TimelineBlock(type: .flight, startTime: $0.departure, endTime: $0.arrival, title: "Flight \($0.origin) → \($0.destination)")
        }

        return enforcingSleepExclusivity(blocks)
    }

    static func enforcingSleepExclusivity(_ blocks: [TimelineBlock]) -> [TimelineBlock] {
        let sleepWindows = blocks
            .filter { isSleepEquivalent($0.type) }
            .map { DateInterval(start: $0.startTime, end: $0.endTime) }

        let resolved = blocks.flatMap { block -> [TimelineBlock] in
            guard !isSleepEquivalent(block.type) else { return [block] }
            var remaining = [DateInterval(start: block.startTime, end: block.endTime)]
            for sleep in sleepWindows {
                remaining = remaining.flatMap { subtract(sleep, from: $0) }
            }
            return remaining.map {
                TimelineBlock(type: block.type, startTime: $0.start, endTime: $0.end, title: block.title)
            }
        }

        return resolved.sorted { $0.startTime < $1.startTime }
    }

    private static func adaptationRate(for direction: Direction) -> Double {
        direction == .eastward ? 0.95 : 1.53
    }

    private static func daysUntil(_ departure: Date, from now: Date, in timeZone: TimeZone) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: departure)).day ?? 0
        return min(max(days, 0), 3)
    }

    private static func addingDays(_ days: Int, to date: Date, in timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(byAdding: .day, value: days, to: date) ?? date
    }

    private static func localTime(
        on day: Date,
        matching time: Date,
        in timeZone: TimeZone,
        referenceTimeZone: TimeZone
    ) -> Date {
        var referenceCalendar = Calendar(identifier: .gregorian)
        referenceCalendar.timeZone = referenceTimeZone
        let timeComponents = referenceCalendar.dateComponents([.hour, .minute], from: time)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(
            bySettingHour: timeComponents.hour ?? 0,
            minute: timeComponents.minute ?? 0,
            second: 0,
            of: day
        ) ?? day
    }

    private static func time(on day: Date, hour: Int, minute: Int, in timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    private static func sleepDuration(profile: UserProfile) -> TimeInterval {
        var duration = profile.wakeTime.timeIntervalSince(profile.sleepTime)
        if duration <= 0 { duration += 24 * 60 * 60 }
        return duration
    }

    private static func isSleepEquivalent(_ type: BlockType) -> Bool {
        type == .sleep || type == .melatonin
    }

    private static func subtract(_ excluded: DateInterval, from interval: DateInterval) -> [DateInterval] {
        guard interval.intersects(excluded) else { return [interval] }
        var result: [DateInterval] = []
        if interval.start < excluded.start {
            result.append(DateInterval(start: interval.start, end: min(interval.end, excluded.start)))
        }
        if interval.end > excluded.end {
            result.append(DateInterval(start: max(interval.start, excluded.end), end: interval.end))
        }
        return result.filter { $0.duration > 0 }
    }
}
