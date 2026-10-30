import SwiftUI

struct SavedPlacesView: View {
    @ObservedObject var store: BookmarkStore
    let select: (SavedPlace) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var filteredPlaces: [SavedPlace] {
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let sorted = store.places.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
        guard !keyword.isEmpty else { return sorted }
        return sorted.filter { $0.name.localizedStandardContains(keyword) ||
            $0.coordinateText.localizedStandardContains(keyword) }
    }

    var body: some View {
        NavigationView {
            List {
                if filteredPlaces.isEmpty {
                    Text(store.places.isEmpty ? "Chưa có địa điểm nào được lưu." : "Không tìm thấy địa điểm.")
                        .foregroundColor(.secondary)
                }
                ForEach(filteredPlaces) { place in
                    HStack(spacing: 8) {
                        Button {
                            select(place)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(place.name).font(.headline)
                                Text(place.coordinateText).font(.caption).foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Button(role: .destructive) { store.remove(place.id) } label: {
                            Image(systemName: "trash").foregroundColor(.red)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("Xóa \(place.name)")
                    }
                }
            }
            .navigationTitle("Địa điểm đã lưu")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Tìm theo tên hoặc tọa độ")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) {
                Button("Đóng") { dismiss() }
            }}
        }
        .navigationViewStyle(.stack)
    }
}
