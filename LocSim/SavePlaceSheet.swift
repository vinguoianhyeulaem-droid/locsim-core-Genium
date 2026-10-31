import SwiftUI
import CoreLocation

// A sheet instead of a SwiftUI alert: iOS 15 may not render a TextField in an alert reliably.
struct SavePlaceSheet: View {
    let coordinate: CLLocationCoordinate2D
    let onSave: (String, CLLocationCoordinate2D) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var placeName = ""

    private var cleanName: String {
        placeName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Tên địa điểm")) {
                    TextField("Ví dụ: Nhà riêng, Công ty", text: $placeName)
                        .autocapitalization(.words)
                        .disableAutocorrection(false)
                }
                Section(header: Text("Tọa độ sẽ lưu")) {
                    Text(String(format: "%.7f,%.7f", coordinate.latitude, coordinate.longitude))
                        .font(.footnote.monospacedDigit())
                }
            }
            .navigationTitle("Lưu vị trí")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lưu") {
                        guard !cleanName.isEmpty else { return }
                        onSave(cleanName, coordinate)
                        dismiss()
                    }
                    .disabled(cleanName.isEmpty)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
