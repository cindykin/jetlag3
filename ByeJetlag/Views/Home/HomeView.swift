import SwiftUI
import Combine

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showAddFlight = false
    @State private var showProfile = false
    @State private var showGuide = false
    @State private var selectedTrip: Trip? = nil
    @State private var expandedTripID: UUID? = nil

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color(.systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Complete profile banner
                            if !appState.hasCompletedProfile {
                                Button { showProfile = true } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3).foregroundStyle(AppTheme.primary)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Complete your profile!")
                                                .font(.subheadline).fontWeight(.semibold)
                                                .foregroundStyle(.primary)
                                            Text("Get a personalized jet lag plan")
                                                .font(.caption).foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption).foregroundStyle(.tertiary)
                                    }
                                    .padding(14)
                                    .background(AppTheme.primary.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                                .padding(.bottom, 16)
                            }

                            if appState.trips.isEmpty {
                                // Empty state — no FAB, just inline button
                                VStack(spacing: 0) {
                                    Spacer(minLength: 60)
                                    EmptyStateView(
                                        symbol: "airplane.cloud",
                                        title: "No active travel plan recorded",
                                        subtitle: "Start your journey by add new flight plan",
                                        action: { showAddFlight = true },
                                        actionLabel: "Add Flight"
                                    )
                                    Spacer(minLength: 60)
                                }
                            } else {
                                // Trip list — single row per trip
                                VStack(spacing: 0) {
                                    ForEach(appState.trips) { trip in
                                        TripRow(
                                            trip: trip,
                                            isExpanded: expandedTripID == trip.id,
                                            onTap: {
                                                withAnimation(.spring(response: 0.35)) {
                                                    expandedTripID = expandedTripID == trip.id ? nil : trip.id
                                                }
                                            },
                                            onViewSchedule: { selectedTrip = trip }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }

                            Spacer(minLength: appState.trips.isEmpty ? 20 : 100)
                        }
                    }

                    // Guide always at bottom
                    Button { showGuide = true } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "questionmark.circle")
                                .foregroundStyle(AppTheme.primary)
                            Text("How to manage jetlag?")
                                .font(.caption).fontWeight(.medium)
                                .foregroundStyle(AppTheme.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2).foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 12)
                        .background(AppTheme.primary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }

                // FAB — only when trips exist
                if !appState.trips.isEmpty {
                    Button { showAddFlight = true } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(AppTheme.primary)
                            .clipShape(Circle())
                            .shadow(color: AppTheme.primary.opacity(0.5), radius: 12, x: 0, y: 6)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 56)
                }
            }
            .navigationTitle("Travel Plans")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showProfile = true } label: {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 28))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(AppTheme.primary)
                    }
                }
            }
            .navigationDestination(isPresented: $showAddFlight) {
                AddFlightView { newTrip in appState.addTrip(newTrip) }
            }
            .sheet(isPresented: $showProfile) { ProfileView() }
            .sheet(isPresented: $showGuide) { NavigationStack { OnboardingView() } }
            .navigationDestination(item: $selectedTrip) { trip in ScheduleView(trip: trip) }
        }
    }
}

// MARK: - Trip Row (single row per trip, matching design)
struct TripRow: View {
    let trip: Trip
    let isExpanded: Bool
    let onTap: () -> Void
    let onViewSchedule: () -> Void

    private let dateFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d MMMM yyyy"; return f
    }()

    private func flagFor(_ iata: String) -> String {
        AirportStore.shared.airports.first(where: { $0.iata_code == iata })?.flagEmoji ?? "✈️"
    }

    private func cityFor(_ iata: String, fallback: String) -> String {
        if !fallback.isEmpty { return fallback }
        return AirportStore.shared.airports.first(where: { $0.iata_code == iata })?.city ?? iata
    }

    var body: some View {
        VStack(spacing: 0) {
            // Compact row: chevron + flag + city + date
            Button(action: onTap) {
                HStack(spacing: 10) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption2).fontWeight(.semibold)
                        .foregroundStyle(.tertiary)
                        .frame(width: 10)
                    Text(flagFor(trip.originCode))
                    Text(cityFor(trip.originCode, fallback: trip.originCity))
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(dateFmt.string(from: trip.departureDate))
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)

            // Expanded content
            if isExpanded {
                VStack(spacing: 12) {
                    // Active trip recommendation
                    if trip.isActive {
                        ActiveTripBanner()
                    }

                    // View full plans
                    Button(action: onViewSchedule) {
                        HStack(spacing: 4) {
                            Text("View Full Plans")
                                .font(.subheadline).fontWeight(.semibold)
                                .foregroundStyle(AppTheme.primary)
                            Image(systemName: "chevron.right")
                                .font(.caption2).foregroundStyle(AppTheme.primary)
                        }
                    }
                    .padding(.bottom, 4)
                }
            }

            Divider()
        }
    }
}

// MARK: - Active Trip Banner
struct ActiveTripBanner: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("You need to seek light, take caffeine and prepare for flight now")
                .font(.caption).fontWeight(.medium).foregroundStyle(.white)
                .multilineTextAlignment(.center)
            HStack(spacing: 16) {
                ActionIcon(icon: "sun.max.fill", label: "Seek\nLight")
                ActionIcon(icon: "cup.and.saucer.fill", label: "Caffeine")
                ActionIcon(icon: "airplane", label: "Flight")
            }
        }
        .padding(16).frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [AppTheme.primary, AppTheme.primary.opacity(0.85)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Action Icon
struct ActionIcon: View {
    let icon: String; let label: String
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title3).foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Preview
#Preview("Empty") {
    HomeView()
        .environmentObject(AppState())
}

#Preview("With trips") {
    let state = AppState()
    let leg = FlightLeg(
        origin: "CGK", destination: "CDG",
        departure: Date(), arrival: Date().addingTimeInterval(3600 * 14)
    )
    var trip = Trip(flights: [leg], blocks: [])
    trip.originCity = "Jakarta"
    trip.destinationCity = "Paris"
    state.trips = [trip]

    HomeView()
        .environmentObject(state)
}
