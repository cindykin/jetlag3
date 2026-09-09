import SwiftUI

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false
    var icon: String? = nil

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(isDisabled ? Color(.systemGray4) : AppTheme.primary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isDisabled)
    }
}

// MARK: - Secondary Button
struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(AppTheme.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Card View
struct CardView<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let symbol: String
    let title: String
    let subtitle: String
    var action: (() -> Void)? = nil
    var actionLabel: String? = nil

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: symbol)
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(AppTheme.primary.opacity(0.6))
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            if let action, let label = actionLabel {
                Button(action: action) {
                    Label(label, systemImage: "plus")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(AppTheme.primary)
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
        }
        .padding(32)
    }
}

// MARK: - Timeline Block Row
struct TimelineBlockRow: View {
    let block: TimelineBlock
    let onTap: () -> Void

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f
    }()

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Time column
                VStack(alignment: .trailing, spacing: 2) {
                    Text(timeFormatter.string(from: block.startTime))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Text(timeFormatter.string(from: block.endTime))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .frame(width: 44)

                // Timeline stem
                VStack(spacing: 0) {
                    Circle()
                        .fill(block.type.color)
                        .frame(width: 12, height: 12)
                    Rectangle()
                        .fill(block.type.color.opacity(0.25))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
                .padding(.horizontal, 12)

                // Block card
                CardView {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(block.type.color.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: block.type.icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(block.type.color)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(block.type.rawValue)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Text(block.durationLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Block Detail Modal
struct BlockDetailModal: View {
    let block: TimelineBlock
    let onReschedule: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(block.type.color.opacity(0.15))
                                .frame(width: 60, height: 60)
                            Image(systemName: block.type.icon)
                                .font(.system(size: 28, weight: .medium))
                                .foregroundStyle(block.type.color)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(block.type.rawValue)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("\"\(block.type.rawValue) at your scheduled time\"")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .italic()
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(block.type.color.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                    // What to do
                    InfoSection(title: "What I should do?", icon: "checkmark.circle.fill", color: .green) {
                        Text(block.type.whatToDo)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Alternatives
                    InfoSection(title: "I can't do it, what should I do?", icon: "arrow.triangle.2.circlepath", color: AppTheme.accent) {
                        Text(block.type.alternatives)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Why it matters
                    InfoSection(title: "Why is this so important?", icon: "info.circle.fill", color: AppTheme.primary) {
                        Text(block.type.whyItMatters)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if block.type != .flight {
                        Divider()
                        Button(action: onReschedule) {
                            Label("Reschedule", systemImage: "calendar.badge.clock")
                                .font(.headline)
                                .foregroundStyle(AppTheme.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(AppTheme.primary.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle(block.type.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.primary)
                }
            }
        }
    }
}

// MARK: - Info Section
struct InfoSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Reschedule Sheet
struct RescheduleSheet: View {
    @Binding var sleepStart: Date
    @Binding var sleepEnd: Date
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Warning banner
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Uh oh, you fell asleep?")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("We can reschedule your sleep schedule and all tasks, but just 2 times each trip flow.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(20)

                Form {
                    Section("Input your time of sleep") {
                        DatePicker("Sleep start", selection: $sleepStart, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                    }
                    Section("Wake up time") {
                        DatePicker("Sleep end", selection: $sleepEnd, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                    }
                }

                HStack(spacing: 12) {
                    Button("Cancel") { dismiss() }
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    Button("Reschedule") { onConfirm(); dismiss() }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(AppTheme.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Reschedule")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Progress Bar
struct StepProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i <= currentStep ? AppTheme.primary : Color(.systemGray4))
                    .frame(height: 4)
                    .animation(.spring(response: 0.4), value: currentStep)
            }
        }
    }
}

// MARK: - Flight Route Card
struct FlightRouteCard: View {
    let origin: String
    let destination: String
    let departure: Date
    let arrival: Date

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy · HH:mm"
        return f
    }()

    var body: some View {
        CardView {
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(origin)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(dateFormatter.string(from: departure))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(spacing: 4) {
                    Image(systemName: "airplane")
                        .foregroundStyle(AppTheme.primary)
                    Rectangle()
                        .fill(AppTheme.primary.opacity(0.3))
                        .frame(height: 1)
                        .frame(width: 60)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(destination)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(dateFormatter.string(from: arrival))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Airport Row
struct AirportRow: View {
    let airport: Airport

    var body: some View {
        HStack(spacing: 12) {
            Text(airport.flagEmoji)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(airport.iata_code) - \(airport.city)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(airport.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}
