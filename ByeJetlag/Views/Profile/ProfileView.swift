import SwiftUI
import Combine

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            List {
                // Avatar + Name section
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.primary.opacity(0.15))
                                .frame(width: 72, height: 72)
                            Text(appState.profile.name.prefix(1).uppercased())
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(AppTheme.primary)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appState.profile.name)
                                .font(.title3)
                                .fontWeight(.bold)
                            Button("✏️ Edit Profile") { showEditProfile = true }
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.primary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                // My Details
                Section("My Details") {
                    ProfileDetailRow(label: "Gender", value: appState.profile.sex) {
                        // edit
                    }
                    ProfileDetailRow(label: "Total Sleep", value: appState.profile.totalSleep) {
                        // info
                    }
                    ProfileDetailRow(label: "Average Sleep Pattern", value: appState.profile.sleepPattern) {
                        // edit
                    }
                }

                // Toggles
                Section("Preferences") {
                    HStack {
                        Label("Notifications", systemImage: "bell.fill")
                            .foregroundStyle(.primary)
                        Spacer()
                        Toggle("", isOn: $appState.profile.receiveNotifications)
                            .tint(AppTheme.primary)
                    }
                    HStack {
                        Label("Use Caffeine", systemImage: "cup.and.saucer.fill")
                            .foregroundStyle(.primary)
                        Spacer()
                        Toggle("", isOn: $appState.profile.useCaffeine)
                            .tint(AppTheme.primary)
                    }
                    HStack {
                        Label("Use Melatonin", systemImage: "pills.fill")
                            .foregroundStyle(.primary)
                        Spacer()
                        Toggle("", isOn: $appState.profile.useMelatonin)
                            .tint(AppTheme.primary)
                    }
                }

                // Legal
                Section {
                    NavigationLink {
                        PlaceholderDetailView(title: "Terms of Use")
                    } label: {
                        Label("Terms of Use", systemImage: "doc.text.fill")
                    }
                    NavigationLink {
                        PlaceholderDetailView(title: "Privacy Policy")
                    } label: {
                        Label("Privacy Policy", systemImage: "lock.shield.fill")
                    }
                    NavigationLink {
                        PlaceholderDetailView(title: "Contact Us")
                    } label: {
                        Label("Contact Us", systemImage: "envelope.fill")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile and Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.primary)
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
        }
    }
}

// MARK: - Profile Detail Row
struct ProfileDetailRow: View {
    let label: String
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .foregroundStyle(.primary)
                Spacer()
                Text(value)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var showNameBinding = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    // Avatar
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(AppTheme.primary.opacity(0.15))
                                .frame(width: 96, height: 96)
                            Text(name.prefix(1).uppercased().isEmpty ? "N" : name.prefix(1).uppercased())
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(AppTheme.primary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                }

                Section("Name") {
                    TextField("Your name", text: $name)
                }

                Section {
                    HStack {
                        Text("@Binding var name: String")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Toggle")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    HStack {
                        Text("@Binding var isPresented: Bool")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                } header: {
                    Text("@State vars")
                }

                // Winding up / unwound tool
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Winding up: @Presented Bool")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Winding up: name: String")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Binding info")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.primary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        if !name.isEmpty {
                            appState.profile.name = name
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.primary)
                }
            }
            .onAppear { name = appState.profile.name }
        }
    }
}

// MARK: - Placeholder Detail View
struct PlaceholderDetailView: View {
    let title: String
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "doc.text")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(AppTheme.primary.opacity(0.5))
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Content coming soon.")
                    .foregroundStyle(.secondary)
            }
            .padding(40)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview
#Preview {
    ProfileView()
        .environmentObject(AppState())
}
