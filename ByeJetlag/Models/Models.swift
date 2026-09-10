import SwiftUI
import Combine

// MARK: - Block Type
enum BlockType: String, CaseIterable, Codable {
    case seekLight = "Seek Light"
    case avoidLight = "Avoid Light"
    case sleep = "Go to Sleep"
    case nap = "Take a Nap"
    case caffeine = "Caffeine"
    case noCaffeine = "No Caffeine"
    case melatonin = "Take Melatonin"
    case flight = "Flight"

    var icons: [String] {
        switch self {
        case .seekLight:   return ["sun.max.fill"]
        case .avoidLight:  return ["sun.max.fill", "x.circle"]
        case .sleep:       return ["bed.double.fill"]
        case .nap:         return ["bed.double.fill", "sun.max.fill"]
        case .caffeine:    return ["cup.and.saucer.fill"]
        case .noCaffeine:  return ["cup.and.saucer.fill", "x.circle"]
        case .melatonin:   return ["bed.double.fill", "pill.fill"]
        case .flight:      return ["airplane.up.right"]
        }
    }

    var color: Color {
        switch self {
        case .seekLight:   return Color(hex: "#FFBE00")
        case .avoidLight:  return Color(hex: "#808080")
        case .sleep:       return Color(hex: "#1D57AF")
        case .nap:         return Color(hex: "#1D7DAF")
        case .caffeine:    return Color(hex: "#855216")
        case .noCaffeine:  return Color(hex: "#808080")
        case .melatonin:   return Color(hex: "#1D57AF")
        case .flight:      return Color(hex: "#111111")
        }
    }

    var backgroundColor: Color {
        switch self {
        case .seekLight:   return Color(hex: "#FFF9EC")
        case .avoidLight:  return Color(hex: "#F2F2F2")
        case .sleep:       return Color(hex: "#EDF3FC")
        case .nap:         return Color(hex: "#EEF7FC")
        case .caffeine:    return Color(hex: "#FCF5ED")
        case .noCaffeine:  return Color(hex: "#F2F2F2")
        case .melatonin:   return Color(hex: "#EDF3FC")
        case .flight:      return Color(hex: "#F2F2F2")
        }
    }

    var whatToDo: String {
        switch self {
        case .seekLight:
            return "Get as much bright light as possible. Go outside, open curtains, or use a light therapy lamp."
        case .avoidLight:
            return "Dim your environment. Wear blue-light blocking glasses, close curtains, and avoid bright screens."
        case .sleep:
            return "Keep your room cool, dark, and quiet. Use a sleep mask or earplugs if needed. Try a warm shower or light stretching before bed."
        case .nap:
            return "Take a short nap of 20–30 minutes if possible. Set an alarm so you don't oversleep and disrupt your schedule."
        case .caffeine:
            return "Have a coffee, tea, or another caffeinated drink now to boost alertness and help you stay awake."
        case .noCaffeine:
            return "Avoid caffeine completely during this window. It will interfere with your sleep schedule and slow adaptation."
        case .melatonin:
            return "Take 0.5–3mg of melatonin now. This helps signal to your body that it's time to prepare for sleep."
        case .flight:
            return "You are on your flight. Try to align your sleep and light exposure with your destination time zone."
        }
    }

    var alternatives: String {
        switch self {
        case .seekLight:
            return "If you can't go outside, sit near a window or use a 10,000 lux light therapy lamp for 20–30 minutes."
        case .avoidLight:
            return "Use blackout curtains or a sleep mask. Switch phone to night mode or maximum warm color temperature."
        case .sleep:
            return "Listen to calming music or a short meditation. Read a book (avoid screens). Try slow breathing exercises."
        case .nap:
            return "If you can't sleep, just close your eyes and rest quietly. Even 10 minutes of rest helps recovery."
        case .caffeine:
            return "Green tea or matcha is a gentler alternative if you're sensitive to coffee. Energy drinks are not recommended."
        case .noCaffeine:
            return "Drink water or herbal tea instead. Physical movement like a short walk can boost alertness naturally."
        case .melatonin:
            return "If you don't have melatonin, try keeping the room very dark and cool to naturally boost melatonin production."
        case .flight:
            return "Use an eye mask and earplugs if flying overnight. Ask for a blanket and adjust your watch to destination time."
        }
    }

    var whyItMatters: String {
        switch self {
        case .seekLight:
            return "Light is the most powerful signal for your circadian clock. Timed light exposure directly shifts your body clock faster than any other method."
        case .avoidLight:
            return "Light at the wrong time can push your body clock in the wrong direction, making jet lag worse and prolonging adaptation."
        case .sleep:
            return "Sleep problems are the biggest complaint with jet lag. Sleeping at the right local time resets your circadian rhythm."
        case .nap:
            return "Strategic napping reduces sleep pressure and improves function without significantly delaying nighttime sleep."
        case .caffeine:
            return "Caffeine blocks adenosine receptors, reducing drowsiness and improving alertness when you need to stay awake."
        case .noCaffeine:
            return "Caffeine has a half-life of 5–6 hours. Consuming it too late will prevent you from falling asleep at the right time."
        case .melatonin:
            return "Melatonin is a chronobiotic — it helps shift your body clock to the new time zone, not just make you sleepy."
        case .flight:
            return "What you do during a flight significantly impacts how quickly you adapt. Light, sleep, and meals all matter in the air."
        }
    }
}

// MARK: - Timeline Block
struct TimelineBlock: Identifiable, Codable {
    var id = UUID()
    var type: BlockType
    var startTime: Date
    var endTime: Date
    var title: String
    var durationLabel: String {
        let diff = Calendar.current.dateComponents([.hour, .minute], from: startTime, to: endTime)
        let h = diff.hour ?? 0
        let m = diff.minute ?? 0
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h) hours" }
        return "\(m) min"
    }
}

// MARK: - Flight Leg
struct FlightLeg: Identifiable, Codable {
    var id = UUID()
    var origin: String
    var destination: String
    var originTimeZoneID: String = ""
    var destinationTimeZoneID: String = ""
    var departure: Date
    var arrival: Date
}

// MARK: - User Profile
struct UserProfile: Codable {
    var useMelatonin: Bool = false
    var useCaffeine: Bool = true
    var receiveNotifications: Bool = true
    var sleepTime: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    var wakeTime: Date = Calendar.current.date(from: DateComponents(hour: 6, minute: 0)) ?? Date()
    var sex: String = "Other"
    var name: String = "Name"
    var totalSleep: String = "8h 00m"
    var sleepPattern: String = "22:00 – 06:00"
}

// MARK: - Trip
struct Trip: Identifiable, Codable, Hashable {
    static func == (lhs: Trip, rhs: Trip) -> Bool {
        lhs.id == rhs.id
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    var id = UUID()
    var flights: [FlightLeg]
    var blocks: [TimelineBlock]
    var createdAt: Date = Date()

    var originCode: String { flights.first?.origin ?? "—" }
    var destinationCode: String { flights.last?.destination ?? "—" }
    var destinationCity: String = ""
    var originCity: String = ""
    var departureDate: Date { flights.first?.departure ?? Date() }
    var isActive: Bool {
        guard let last = flights.last else { return false }
        return last.arrival > Date()
    }
}

// MARK: - App State
class AppState: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var profile: UserProfile = UserProfile()
    @Published var hasCompletedProfile: Bool = false

    init() { loadSample() }

    func addTrip(_ trip: Trip) {
        trips.insert(trip, at: 0)
    }

    private func loadSample() {
        // Empty by default — user adds flights
    }

    func generateBlocks(for trip: Trip) -> [TimelineBlock] {
        guard
            let firstFlight = trip.flights.first,
            let lastFlight = trip.flights.last,
            let originTimeZone = TimeZone(identifier: firstFlight.originTimeZoneID),
            let destinationTimeZone = TimeZone(identifier: lastFlight.destinationTimeZoneID)
        else {
            return []
        }

        return CircadianEngine.generateBlocks(
            for: trip.flights,
            profile: profile,
            originTimeZone: originTimeZone,
            destinationTimeZone: destinationTimeZone
        )
    }
}
