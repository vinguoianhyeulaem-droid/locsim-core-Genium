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
    @StateObject private var bookmarks = BookmarkStore()
    @State private var showBookmarks = false
    @State private var showSavePlace = false
    @State private var showMissingCoordinate = false

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
                    HStack(spacing: 12) {
                        Button {
                            if parsedCoordinates() == nil { showMissingCoordinate = true }
                            else { showSavePlace = true }
                        } label: {
                            Label("Lưu vị trí", systemImage: "bookmark.badge.plus")
                        }
                        Button { showBookmarks = true } label: {
                            Label("Đã lưu", systemImage: "bookmark.fill")
                        }
                    }
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)
                }.padding(.horizontal)
                CustomMapView(tappedCoordinate: $tappedCoordinate, targetCoordinate: $mapTarget)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 12)
                HStack {
                    Text("Version 1.1.1")
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
                // MKMapView provides CLLocationCoordinate2D. Use this exact coordinate
                // for the input and the simulated GPS, so the map pin and GPS agree.
                // Do not update mapTarget: that would move the camera after a manual tap
                // and can also trigger a zoom/camera jump in updateUIView.
                let point = selected.coordinate
                coordinates = String(format: "%.7f,%.7f", point.latitude, point.longitude)
                simulate(point)
            }
            .sheet(isPresented: $showBookmarks) {
                SavedPlacesView(store: bookmarks, select: selectSavedPlace)
            }
            .sheet(isPresented: $showSavePlace) {
                if let point = parsedCoordinates() {
                    SavePlaceSheet(coordinate: point, altitude: Double(altitude) ?? 0) { name, savedPoint, savedAltitude in
                        bookmarks.add(name: name, coordinate: savedPoint, altitude: savedAltitude)
                    }
                }
            }
            .alert("Chưa có tọa độ hợp lệ", isPresented: $showMissingCoordinate) {
                Button("Đóng", role: .cancel) {}
            } message: {
                Text("Hãy chọn điểm trên bản đồ hoặc nhập tọa độ trước khi lưu.")
            }
            .alert("Tọa độ không hợp lệ", isPresented: $showError) {
                Button("Đóng", role: .cancel) {}
            } message: {
                Text("Nhập theo dạng vĩ độ,kinh độ. Ví dụ: 21.5595306,105.2776417")
            }
        }.navigationViewStyle(.stack)
    }

    private func parsedCoordinates() -> CLLocationCoordinate2D? {
        let parts = coordinates.split(separator: ",", omittingEmptySubsequences: false)
        guard parts.count == 2,
              let latitude = Double(parts[0].trimmingCharacters(in: .whitespacesAndNewlines)),
              let longitude = Double(parts[1].trimmingCharacters(in: .whitespacesAndNewlines)),
              latitude.isFinite, longitude.isFinite,
              (-90.0...90.0).contains(latitude), (-180.0...180.0).contains(longitude) else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private func selectSavedPlace(_ place: SavedPlace) {
        coordinates = place.coordinateText
        altitude = String(format: "%g", place.altitude)
        mapTarget = EquatableCoordinate(coordinate: place.coordinate)
        // Selecting a bookmark only navigates the map. Tap Chạy to simulate GPS.
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
