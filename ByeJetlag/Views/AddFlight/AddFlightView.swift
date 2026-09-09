import SwiftUI
import Combine

// MARK: - Flow Page
enum FlowPage: Equatable {
    case flightDetails, itinerary
    case personalizeIntro, qMelatonin, qNotifications, qSleep, qWake, qSex
    case loading
}

// MARK: - Add Flight Container
struct AddFlightView: View {
    let onComplete: (Trip) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appState = AppState.shared

    @State private var pageIndex = 0
    @State private var needsPersonalization = false
    @State private var showConfirmation = false

    // Flight data
    @State private var flights: [FlightLeg] = [FlightLeg(
        origin: "", destination: "",
        departure: Date(), arrival: Date().addingTimeInterval(3600 * 8)
    )]
    @State private var selectedOrigin: Airport? = nil
    @State private var selectedDest: Airport? = nil

    // Personalization
    @State private var useMelatonin = false
    @State private var useCaffeine = true
    @State private var receiveNotifications = true
    @State private var sleepTime = Calendar.current.date(from: DateComponents(hour: 22)) ?? Date()
    @State private var wakeTime = Calendar.current.date(from: DateComponents(hour: 6)) ?? Date()
    @State private var sex = "Other"
    @State private var loadingProgress: Double = 0

    private var pages: [FlowPage] {
        var p: [FlowPage] = [.flightDetails, .itinerary]
        if needsPersonalization {
            p += [.personalizeIntro, .qMelatonin, .qNotifications, .qSleep, .qWake, .qSex]
        }
        p.append(.loading)
        return p
    }

    private var currentPage: FlowPage { pages[min(pageIndex, pages.count - 1)] }
    private var isLoading: Bool { currentPage == .loading }
    private var isAutoAdvancePage: Bool {
        [.qMelatonin, .qNotifications, .qSex].contains(currentPage)
    }

    @State private var editingFlightIndex = 0

    private var isStep0Valid: Bool {
        flights.allSatisfy { !$0.origin.isEmpty && !$0.destination.isEmpty }
    }

    var body: some View {
        VStack(spacing: 0) {
            if !isLoading {
                StepProgressBar(currentStep: pageIndex, totalSteps: pages.count - 1)
                    .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 20)
            }

            Group {
                switch currentPage {
                case .flightDetails:
                    AddFlightStep1(flights: $flights, selectedOrigin: $selectedOrigin, selectedDest: $selectedDest, editingIndex: editingFlightIndex)
                case .itinerary:
                    AddFlightStep2(flights: $flights, selectedOrigin: selectedOrigin, selectedDest: selectedDest, onAddFlight: { addNewFlight() })
                case .personalizeIntro:
                    PersonalizationIntro()
                case .qMelatonin:
                    QuestionYesNo(title: "Would you like to use melatonin to timeshift faster and sleep better?", value: $useMelatonin) { withAnimation { pageIndex += 1 } }
                case .qNotifications:
                    QuestionYesNo(title: "Get advice delivered as notifications", value: $receiveNotifications) { withAnimation { pageIndex += 1 } }
                case .qSleep:
                    QuestionTimePicker(title: "When do you normally fall asleep?", selection: $sleepTime)
                case .qWake:
                    QuestionTimePicker(title: "When do you normally wake up?", selection: $wakeTime)
                case .qSex:
                    QuestionOptions(title: "What's your sex?", options: ["Female", "Male", "Other"], selected: $sex) { saveProfileAndFinish() }
                case .loading:
                    LoadingView(progress: loadingProgress)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom button (hidden for yes/no & option questions — they auto-advance)
            if !isLoading && !isAutoAdvancePage {
                VStack(spacing: 12) {
                    if currentPage == .personalizeIntro {
                        PrimaryButton(title: "Let's do it", action: { withAnimation { pageIndex += 1 } })
                    } else if currentPage == .itinerary {
                        PrimaryButton(title: "Next", action: { showConfirmation = true })
                    } else if currentPage == .flightDetails {
                        PrimaryButton(title: "Next", action: { withAnimation { pageIndex += 1 } }, isDisabled: !isStep0Valid)
                    } else {
                        PrimaryButton(title: "Next", action: { withAnimation { pageIndex += 1 } })
                    }
                }
                .padding(.horizontal, 20).padding(.vertical, 20)
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle(stepTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    if pageIndex > 0 { withAnimation { pageIndex -= 1 } }
                    else { dismiss() }
                } label: {
                    Image(systemName: "chevron.left").fontWeight(.semibold).foregroundStyle(AppTheme.primary)
                }
            }
        }
        .alert("Are you entering all flight correctly?", isPresented: $showConfirmation) {
            Button("Yes, create plan") { handleConfirm() }
            Button("No, let me complete", role: .cancel) { pageIndex = 0 }
        } message: {
            Text("Including all stopover, transit, and your return flights?")
        }
        .onReceive(Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()) { _ in
            guard isLoading, loadingProgress < 1.0 else { return }
            loadingProgress = min(loadingProgress + 0.015, 1.0)
            if loadingProgress >= 1.0 { finishCreation() }
        }
    }

    private var stepTitle: String {
        switch currentPage {
        case .flightDetails: return "Fill your flight detail"
        case .itinerary: return "Itenary list"
        case .personalizeIntro, .qMelatonin, .qNotifications, .qSleep, .qWake, .qSex:
            return "Personalize your Profile"
        case .loading: return ""
        }
    }

    private func addNewFlight() {
        flights.append(FlightLeg(
            origin: flights.last?.destination ?? "", destination: "",
            departure: flights.last?.arrival ?? Date(),
            arrival: (flights.last?.arrival ?? Date()).addingTimeInterval(3600 * 8)
        ))
        editingFlightIndex = flights.count - 1
        selectedOrigin = AirportStore.shared.airports.first(where: { $0.iata_code == flights.last?.origin })
        selectedDest = nil
        pageIndex = 0  // go back to flight details to fill new flight
    }

    private func handleConfirm() {
        if appState.hasCompletedProfile {
            startLoading()
        } else {
            needsPersonalization = true
            pageIndex = 2
        }
    }

    private func startLoading() {
        loadingProgress = 0
        pageIndex = pages.firstIndex(of: .loading) ?? (pages.count - 1)
    }

    private func saveProfileAndFinish() {
        appState.profile.useMelatonin = useMelatonin
        appState.profile.useCaffeine = useCaffeine
        appState.profile.receiveNotifications = receiveNotifications
        appState.profile.sleepTime = sleepTime
        appState.profile.wakeTime = wakeTime
        appState.profile.sex = sex
        appState.hasCompletedProfile = true
        startLoading()
    }

    private func finishCreation() {
        var trip = Trip(flights: flights, blocks: [])
        trip.blocks = appState.generateBlocks(for: trip)
        if let o = AirportStore.shared.airports.first(where: { $0.iata_code == flights.first?.origin }) { trip.originCity = o.city }
        if let d = AirportStore.shared.airports.first(where: { $0.iata_code == flights.last?.destination }) { trip.destinationCity = d.city }
        onComplete(trip)
        dismiss()
    }
}

// MARK: - Step 1: Flight Details
struct AddFlightStep1: View {
    @Binding var flights: [FlightLeg]
    @Binding var selectedOrigin: Airport?
    @Binding var selectedDest: Airport?
    var editingIndex: Int = 0
    @State private var showOriginPicker = false
    @State private var showDestPicker = false

    private var idx: Int { min(editingIndex, flights.count - 1) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Route").font(.headline)
                    Button { showOriginPicker = true } label: {
                        AirportInputRow(airport: selectedOrigin, placeholder: "Choose airport departure")
                    }
                    .buttonStyle(.plain)
                    .onChange(of: selectedOrigin) { _, new in if let a = new { flights[idx].origin = a.iata_code } }

                    HStack { Spacer(); Image(systemName: "arrow.down").font(.caption).foregroundStyle(.secondary); Spacer() }

                    Button { showDestPicker = true } label: {
                        AirportInputRow(airport: selectedDest, placeholder: "Choose airport arrival")
                    }
                    .buttonStyle(.plain)
                    .onChange(of: selectedDest) { _, new in if let a = new { flights[idx].destination = a.iata_code } }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Schedule").font(.headline)
                    Text("Pick date and time same as your ticket").font(.caption).foregroundStyle(.secondary)
                    VStack(spacing: 0) {
                        DatePickerRow(label: "Departure", icon: "airplane.departure", selection: $flights[idx].departure)
                        Divider().padding(.leading, 56)
                        DatePickerRow(label: "Arrival", icon: "airplane.arrival", selection: $flights[idx].arrival)
                    }
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                QuickNoteCard()
            }
            .padding(20)
        }
        .sheet(isPresented: $showOriginPicker) { AirportPickerView(title: "Search airport departure", selectedAirport: $selectedOrigin) }
        .sheet(isPresented: $showDestPicker) { AirportPickerView(title: "Search airport arrival", selectedAirport: $selectedDest) }
    }
}

// MARK: - Airport Input Row
struct AirportInputRow: View {
    let airport: Airport?
    let placeholder: String
    var body: some View {
        HStack(spacing: 12) {
            if let airport {
                Text(airport.flagEmoji).font(.title2)
                    .frame(width: 36, height: 36)
                    .background(Color(.systemGray6)).clipShape(RoundedRectangle(cornerRadius: 8))
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(airport.iata_code) - \(airport.city)").font(.subheadline).fontWeight(.semibold).foregroundStyle(.primary)
                    Text(airport.name).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            } else {
                Image(systemName: "airplane").foregroundStyle(.secondary).frame(width: 20)
                Text(placeholder).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(airport != nil ? Color(.systemBackground) : Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: airport != nil ? .black.opacity(0.06) : .clear, radius: 8, x: 0, y: 2)
    }
}

// MARK: - Quick Note
struct QuickNoteCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Quick Note", systemImage: "lightbulb.fill").font(.subheadline).fontWeight(.semibold).foregroundStyle(AppTheme.primary)
            Text("To get the best results, start using this app at least 3 days before your flight. It works even better for trips longer than 6 days.").font(.caption).foregroundStyle(.secondary)
            Text("If you connect your wearable, your data stays private and is only used to improve your experience.").font(.caption).foregroundStyle(.secondary)
        }
        .padding(16).background(AppTheme.primary.opacity(0.06)).clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Date Picker Row
struct DatePickerRow: View {
    let label: String; let icon: String; @Binding var selection: Date
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).foregroundStyle(AppTheme.primary).frame(width: 24)
            Text(label).font(.callout).fontWeight(.medium)
            Spacer()
            DatePicker("", selection: $selection, displayedComponents: [.date, .hourAndMinute])
                .labelsHidden().datePickerStyle(.compact).tint(AppTheme.primary)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}

// MARK: - Step 2: Itinerary List
struct AddFlightStep2: View {
    @Binding var flights: [FlightLeg]
    let selectedOrigin: Airport?; let selectedDest: Airport?; let onAddFlight: () -> Void
    private let dateFmt: DateFormatter = { let f = DateFormatter(); f.dateFormat = "d MMM"; return f }()
    private let timeFmt: DateFormatter = { let f = DateFormatter(); f.dateFormat = "HH:mm"; return f }()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 0) {
                    ForEach(Array(flights.enumerated()), id: \.offset) { idx, leg in
                        ItineraryLegRow(leg: leg, originAirport: idx == 0 ? selectedOrigin : nil,
                                        destAirport: idx == flights.count - 1 ? selectedDest : nil,
                                        dateFmt: dateFmt, timeFmt: timeFmt, isLast: idx == flights.count - 1)
                    }
                }
                .padding(16).background(Color(.secondarySystemBackground)).clipShape(RoundedRectangle(cornerRadius: 16))

                Text("Time is the local time on the local airport").font(.caption2).foregroundStyle(.tertiary)

                Button(action: onAddFlight) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill").foregroundStyle(AppTheme.primary)
                        Text("+ Add other flight").font(.subheadline).fontWeight(.medium).foregroundStyle(AppTheme.primary)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(AppTheme.primary.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(20)
        }
    }
}

struct ItineraryLegRow: View {
    let leg: FlightLeg; let originAirport: Airport?; let destAirport: Airport?
    let dateFmt: DateFormatter; let timeFmt: DateFormatter; let isLast: Bool
    private func city(_ iata: String, _ ap: Airport?) -> String {
        ap?.city ?? AirportStore.shared.airports.first(where: { $0.iata_code == iata })?.city ?? iata
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack { Text(city(leg.origin, originAirport)).font(.subheadline).fontWeight(.medium); Spacer()
                Text(dateFmt.string(from: leg.departure)).font(.caption).foregroundStyle(.secondary)
                Text(timeFmt.string(from: leg.departure)).font(.caption).foregroundStyle(.secondary) }
            .padding(.vertical, 8)
            HStack { Image(systemName: "arrow.down").font(.caption2).foregroundStyle(.tertiary); Spacer() }.padding(.vertical, 4)
            HStack { Text(city(leg.destination, destAirport)).font(.subheadline).fontWeight(.medium); Spacer()
                Text(dateFmt.string(from: leg.arrival)).font(.caption).foregroundStyle(.secondary)
                Text(timeFmt.string(from: leg.arrival)).font(.caption).foregroundStyle(.secondary) }
            .padding(.vertical, 8)
            if !isLast { Divider().padding(.vertical, 8) }
        }
    }
}

// MARK: - Personalization Intro
struct PersonalizationIntro: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            CardView {
                ZStack {
                    RoundedRectangle(cornerRadius: 0).fill(AppTheme.primary)
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill.badge.checkmark")
                            .font(.system(size: 48)).foregroundStyle(.white)
                    }.padding(40)
                }
            }
            .frame(height: 160)
            .padding(.horizontal, 40)

            VStack(spacing: 12) {
                Text("In order to get to deliver personalized advice, we need to know about you better to setup your circadian profile. There is no right or wrong answer, choose the one most represent yourself.")
                    .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            Spacer()
        }
        .padding(20)
    }
}

// MARK: - Question: Yes/No (auto-advances on tap)
struct QuestionYesNo: View {
    let title: String
    @Binding var value: Bool
    var onSelect: (() -> Void)? = nil
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text(title).font(.title3).fontWeight(.semibold).multilineTextAlignment(.center).padding(.horizontal, 20)
            VStack(spacing: 12) {
                OptionButton(label: "Yes", isSelected: value) {
                    value = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onSelect?() }
                }
                OptionButton(label: "No", isSelected: !value) {
                    value = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onSelect?() }
                }
            }
            .padding(.horizontal, 40)
            Spacer()
        }
    }
}

// MARK: - Question: Time Picker
struct QuestionTimePicker: View {
    let title: String
    @Binding var selection: Date
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text(title).font(.title3).fontWeight(.semibold).multilineTextAlignment(.center).padding(.horizontal, 20)
            DatePicker("", selection: $selection, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel).labelsHidden().frame(height: 150).clipped()
            Spacer()
        }
    }
}

// MARK: - Question: Multiple Options (auto-advances on tap)
struct QuestionOptions: View {
    let title: String; let options: [String]; @Binding var selected: String
    var onSelect: (() -> Void)? = nil
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text(title).font(.title3).fontWeight(.semibold).multilineTextAlignment(.center).padding(.horizontal, 20)
            VStack(spacing: 12) {
                ForEach(options, id: \.self) { opt in
                    OptionButton(label: opt, isSelected: selected == opt) {
                        selected = opt
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onSelect?() }
                    }
                }
            }
            .padding(.horizontal, 40)
            Spacer()
        }
    }
}

// MARK: - Option Button
struct OptionButton: View {
    let label: String; let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline).fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .background(isSelected ? AppTheme.primary : Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    let progress: Double
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            CardView {
                ZStack {
                    RoundedRectangle(cornerRadius: 0).fill(AppTheme.primary)
                    VStack(spacing: 16) {
                        ZStack {
                            Circle().stroke(Color.white.opacity(0.3), lineWidth: 4).frame(width: 60, height: 60)
                            Circle().trim(from: 0, to: progress)
                                .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 60, height: 60).rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 0.1), value: progress)
                            Image(systemName: "airplane").font(.title2).foregroundStyle(.white)
                        }
                        Text("Creating perfect plan for you").font(.headline).foregroundStyle(.white)
                        Text("Processing and mixing your information").font(.caption).foregroundStyle(.white.opacity(0.8))
                    }
                    .padding(40)
                }
            }
            .padding(.horizontal, 40)
            Spacer()
        }
    }
}

// MARK: - How We Analyze Modal
struct HowWeAnalyzeModal: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    CardView {
                        ZStack {
                            RoundedRectangle(cornerRadius: 0).fill(AppTheme.primary.opacity(0.15))
                            VStack(spacing: 12) {
                                Image(systemName: "waveform.path.ecg").font(.system(size: 48)).foregroundStyle(AppTheme.primary)
                                Text("How we analyze").font(.title2).fontWeight(.bold)
                            }.padding(32)
                        }
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your circadian profile is built from your natural sleep patterns, preferences, and chronotype.").font(.body).foregroundStyle(.secondary)
                        Text("All data stays on your device and is only used to personalize your jet lag plan.").font(.subheadline).foregroundStyle(.tertiary)
                    }
                }.padding(20)
            }
            .navigationTitle("How We Analyze").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.fontWeight(.semibold).foregroundStyle(AppTheme.primary)
                }
            }
        }
    }
}

#Preview { NavigationStack { AddFlightView { _ in } } }
