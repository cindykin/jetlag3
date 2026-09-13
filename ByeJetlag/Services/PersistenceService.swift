import Foundation

/// Local persistence for `trips` and `profile` via `Codable` + `UserDefaults`, per
/// `02_ARCHITECTURE.md` Section 2.C. No backend, no external storage — matches the
/// "local only" scope decided for v1 (see `01_PRODUCT.md`).
///
/// Unlike `CircadianEngine` (pure static functions, no state of its own), this wraps a
/// genuinely stateful resource — a `UserDefaults` instance — so it's instance-based rather
/// than static. That's what makes `init(defaults:)` possible below: tests inject an
/// isolated, throwaway suite instead of touching `.standard` (the real app's data).
struct PersistenceService {
    private let defaults: UserDefaults

    private let tripsKey = "com.byejetlag.trips"
    private let profileKey = "com.byejetlag.profile"
    private let hasCompletedProfileKey = "com.byejetlag.hasCompletedProfile"

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Trips

    /// Encodes `trips` as JSON and writes it to UserDefaults. Failures are logged, not
    /// thrown or crashed on — there's no user-facing error surface for persistence
    /// failures in v1 (see 06_CURRENT_STATE.md), and losing a save silently is far less
    /// harmful than crashing the app over it.
    func saveTrips(_ trips: [Trip]) {
        do {
            let data = try encoder.encode(trips)
            defaults.set(data, forKey: tripsKey)
        } catch {
            print("⚠️ PersistenceService: failed to save trips — \(error)")
        }
    }

    /// Returns the saved trips, or `[]` if nothing has been saved yet (first launch) or if
    /// decoding fails for any reason (e.g. a future migration changes `Trip`'s shape).
    func loadTrips() -> [Trip] {
        guard let data = defaults.data(forKey: tripsKey) else { return [] }
        do {
            return try decoder.decode([Trip].self, from: data)
        } catch {
            print("⚠️ PersistenceService: failed to load trips — \(error)")
            return []
        }
    }

    // MARK: - Profile

    func saveProfile(_ profile: UserProfile) {
        do {
            let data = try encoder.encode(profile)
            defaults.set(data, forKey: profileKey)
        } catch {
            print("⚠️ PersistenceService: failed to save profile — \(error)")
        }
    }

    /// Returns the saved profile, or `nil` if nothing has been saved yet — the caller
    /// (`AppState.init`) decides the first-launch default (`UserProfile()`), not this type.
    func loadProfile() -> UserProfile? {
        guard let data = defaults.data(forKey: profileKey) else { return nil }
        do {
            return try decoder.decode(UserProfile.self, from: data)
        } catch {
            print("⚠️ PersistenceService: failed to load profile — \(error)")
            return nil
        }
    }

    // MARK: - hasCompletedProfile
    //
    // Not explicitly requested in the persistence task, but included alongside trips/profile:
    // without it, a returning user's profile answers would persist correctly but the app
    // would still think onboarding/personalize was never completed, re-triggering that flow
    // incorrectly. A plain Bool doesn't need JSON encoding — stored directly.

    func saveHasCompletedProfile(_ value: Bool) {
        defaults.set(value, forKey: hasCompletedProfileKey)
    }

    func loadHasCompletedProfile() -> Bool {
        defaults.bool(forKey: hasCompletedProfileKey)
    }
}
