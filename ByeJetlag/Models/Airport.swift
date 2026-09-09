import Foundation
import Combine

struct Airport: Codable, Identifiable, Hashable {
    var id: String { iata_code }
    let name: String
    let iata_code: String
    let icao_code: String
    let city: String
    let country: String
    let latitude: Double
    let longitude: Double
    let timezone: String
    let utc_offset: String

    var displayName: String { "\(iata_code) – \(city)" }
    var fullDisplay: String { "\(name)\n\(iata_code) · \(city), \(country)" }

    var flagEmoji: String {
        let code = Airport.countryToCode(country)
        guard code.count == 2 else { return "✈️" }
        return code.uppercased().unicodeScalars
            .compactMap { Unicode.Scalar(127397 + $0.value) }
            .map { String($0) }
            .joined()
    }

    static func countryToCode(_ country: String) -> String {
        let locale = Locale(identifier: "en_US")
        for code in Locale.isoRegionCodes {
            if let name = locale.localizedString(forRegionCode: code),
               name.lowercased() == country.lowercased() {
                return code
            }
        }
        return ""
    }
}

struct AirportDatabase: Codable {
    let airports: [Airport]
}

// MARK: - Airport Store
class AirportStore: ObservableObject {
    @Published var airports: [Airport] = []

    static let shared = AirportStore()

    private init() { load() }

    private func load() {
        guard let url = Bundle.main.url(forResource: "global_airports", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let db = try? JSONDecoder().decode(AirportDatabase.self, from: data)
        else {
            airports = Airport.fallback
            return
        }
        airports = db.airports
    }

    func search(_ query: String) -> [Airport] {
        guard !query.isEmpty else { return Array(airports.prefix(30)) }
        let q = query.uppercased()
        return airports.filter {
            $0.iata_code.contains(q) ||
            $0.city.uppercased().contains(q) ||
            $0.name.uppercased().contains(query.uppercased()) ||
            $0.country.uppercased().contains(q)
        }.prefix(40).map { $0 }
    }
}

extension Airport {
    static let fallback: [Airport] = [
        Airport(name: "Soekarno-Hatta International Airport", iata_code: "CGK", icao_code: "WIII",
                city: "Jakarta", country: "Indonesia", latitude: -6.1256, longitude: 106.6559,
                timezone: "Asia/Jakarta", utc_offset: "+07:00"),
        Airport(name: "Charles de Gaulle Airport", iata_code: "CDG", icao_code: "LFPG",
                city: "Paris", country: "France", latitude: 49.0097, longitude: 2.5479,
                timezone: "Europe/Paris", utc_offset: "+02:00"),
        Airport(name: "Doha International Airport", iata_code: "DOH", icao_code: "OTBD",
                city: "Doha", country: "Qatar", latitude: 25.2731, longitude: 51.6081,
                timezone: "Asia/Qatar", utc_offset: "+03:00"),
        Airport(name: "Heathrow Airport", iata_code: "LHR", icao_code: "EGLL",
                city: "London", country: "United Kingdom", latitude: 51.4706, longitude: -0.4619,
                timezone: "Europe/London", utc_offset: "+01:00"),
        Airport(name: "John F. Kennedy International Airport", iata_code: "JFK", icao_code: "KJFK",
                city: "New York", country: "United States", latitude: 40.6413, longitude: -73.7781,
                timezone: "America/New_York", utc_offset: "-04:00"),
        Airport(name: "Dubai International Airport", iata_code: "DXB", icao_code: "OMDB",
                city: "Dubai", country: "United Arab Emirates", latitude: 25.2532, longitude: 55.3657,
                timezone: "Asia/Dubai", utc_offset: "+04:00"),
        Airport(name: "Singapore Changi Airport", iata_code: "SIN", icao_code: "WSSS",
                city: "Singapore", country: "Singapore", latitude: 1.3644, longitude: 103.9915,
                timezone: "Asia/Singapore", utc_offset: "+08:00"),
        Airport(name: "Narita International Airport", iata_code: "NRT", icao_code: "RJAA",
                city: "Tokyo", country: "Japan", latitude: 35.7647, longitude: 140.3864,
                timezone: "Asia/Tokyo", utc_offset: "+09:00"),
        Airport(name: "Los Angeles International Airport", iata_code: "LAX", icao_code: "KLAX",
                city: "Los Angeles", country: "United States", latitude: 33.9425, longitude: -118.4081,
                timezone: "America/Los_Angeles", utc_offset: "-07:00"),
        Airport(name: "Sydney Kingsford Smith Airport", iata_code: "SYD", icao_code: "YSSY",
                city: "Sydney", country: "Australia", latitude: -33.9461, longitude: 151.1772,
                timezone: "Australia/Sydney", utc_offset: "+10:00"),
    ]
}
