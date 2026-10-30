import SwiftUI
import MapKit
import CoreLocation

struct LocSimView: View {
    @State private var coordinates = ""
    @State private var altitude = "0"
    @State private var tappedCoordinate: EquatableCoordinate?
    @State private var mapTarget: EquatableCoordinate?
    @State private var isSimulating = false
    @State private var showError = false

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tọa độ Google Maps (vĩ độ, kinh độ)").font(.headline)
                    HStack {
                        TextField("21.5595306,105.2776417", text: $coordinates)
                            .keyboardType(.numbersAndPunctuation)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .accessibilityLabel("Tọa độ")
                        Button(action: { coordinates = UIPasteboard.general.string ?? "" }) {
                            Image(systemName: "doc.on.clipboard")
                        }
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    HStack {
                        Text("Độ cao (m)")
                        Spacer()
                        TextField("0", text: $altitude)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 85)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    Button(action: applyCoordinates) {
                        Label("Chạy", systemImage: "location.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isSimulating ? .green : .red)
                    .controlSize(.large)
                }.padding(.horizontal)
                CustomMapView(tappedCoordinate: $tappedCoordinate, targetCoordinate: $mapTarget)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 12)
                HStack {
                    Text("Version 1.0.0")
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(role: .destructive, action: stopSimulation) {
                        Label("Dừng GPS", systemImage: "location.slash")
                    }.buttonStyle(.bordered)
                }.padding([.horizontal, .bottom])
            }
            .padding(.top, 10)
            .navigationTitle("TNG Location")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: tappedCoordinate) { selected in
                guard let selected = selected else { return }
                let fixed = CoordTransform.gcj02ToWgs84(selected.coordinate)
                coordinates = String(format: "%.7f,%.7f", fixed.latitude, fixed.longitude)
                // Đồng bộ trạng thái ghim với lựa chọn vừa chạm/nhấn giữ.
                mapTarget = EquatableCoordinate(coordinate: selected.coordinate)
                simulate(fixed)
            }
            .alert("Tọa độ không hợp lệ", isPresented: $showError) {
                Button("Đóng", role: .cancel) {}
            } message: {
                Text("Nhập theo dạng vĩ độ,kinh độ. Ví dụ: 21.5595306,105.2776417")
            }
        }.navigationViewStyle(.stack)
    }

    private func applyCoordinates() {
        let parts = coordinates.split(separator: ",", omittingEmptySubsequences: false)
        guard parts.count == 2,
              let latitude = Double(parts[0].trimmingCharacters(in: .whitespacesAndNewlines)),
              let longitude = Double(parts[1].trimmingCharacters(in: .whitespacesAndNewlines)),
              latitude.isFinite, longitude.isFinite,
              (-90.0...90.0).contains(latitude), (-180.0...180.0).contains(longitude) else {
            showError = true
            return
        }
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        mapTarget = EquatableCoordinate(coordinate: coordinate)
        simulate(coordinate)
    }

    private func simulate(_ coordinate: CLLocationCoordinate2D) {
        let height = Double(altitude) ?? 0
        let location = CLLocation(coordinate: coordinate, altitude: height,
                                  horizontalAccuracy: 5, verticalAccuracy: 5, timestamp: Date())
        LocSimManager.startLocSim(location: location)
        isSimulating = true
    }

    private func stopSimulation() {
        LocSimManager.stopLocSim()
        isSimulating = false
    }
}
