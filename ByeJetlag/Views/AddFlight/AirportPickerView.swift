import SwiftUI

struct AirportPickerView: View {
    let title: String
    @Binding var selectedAirport: Airport?
    @Environment(\.dismiss) private var dismiss

    @StateObject private var store = AirportStore.shared
    @State private var searchText = ""

    private var results: [Airport] {
        store.search(searchText)
    }

    var body: some View {
        NavigationStack {
            List(results) { airport in
                Button {
                    selectedAirport = airport
                    dismiss()
                } label: {
                    AirportRow(airport: airport)
                }
                .buttonStyle(.plain)
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Search by airport or city name")
            .contentMargins(0.00001)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .overlay {
                if results.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
    }
}

#Preview {
    AirportPickerView(title: "Departure Airport", selectedAirport: .constant(nil))
}
