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
    @State private var showDisclaimer = false
    @State private var activeText = ""

    var body: some View {
        NavigationView {
            ZStack {
                // Bản đồ chiếm toàn màn hình, các điều khiển nổi phía trên.
                CustomMapView(tappedCoordinate: $tappedCoordinate, targetCoordinate: $mapTarget)
                    .ignoresSafeArea(edges: .bottom)

                VStack(spacing: 0) {
                    HStack {
                        statusChip
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    Spacer()
                    controlCard
                }
            }
            .navigationTitle("TNG Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            showDisclaimer = true
                        } label: {
                            Label("Giới thiệu & Miễn trừ trách nhiệm", systemImage: "info.circle")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .accessibilityLabel("Menu")
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Xong") { dismissKeyboard() }
                }
            }
            .sheet(isPresented: $showDisclaimer) {
                DisclaimerView()
            }
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

    // MARK: - Thành phần giao diện

    private var statusChip: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isSimulating ? Color.green : Color.red)
                .frame(width: 10, height: 10)
            Text(isSimulating ? "Đang giả lập" : "Đã dừng")
                .font(.subheadline.weight(.semibold))
            if isSimulating, !activeText.isEmpty {
                Text(activeText)
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Capsule().fill(.regularMaterial))
        .shadow(color: Color.black.opacity(0.12), radius: 6, y: 2)
        .accessibilityElement(children: .combine)
    }

    private var controlCard: some View {
        VStack(spacing: 12) {
            // Ô nhập tọa độ
            VStack(alignment: .leading, spacing: 6) {
                Text("Tọa độ Google Maps (vĩ độ, kinh độ)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                HStack(spacing: 10) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.accentColor)
                    TextField("21.5595306,105.2776417", text: $coordinates)
                        .keyboardType(.numbersAndPunctuation)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .accessibilityLabel("Tọa độ")
                    Button(action: { coordinates = UIPasteboard.general.string ?? "" }) {
                        Image(systemName: "doc.on.clipboard")
                    }
                    .accessibilityLabel("Dán tọa độ")
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            }

            // Độ cao
            HStack(spacing: 10) {
                Image(systemName: "mountain.2")
                    .foregroundColor(.secondary)
                Text("Độ cao (m)")
                Spacer()
                TextField("0", text: $altitude)
                    .keyboardType(.numbersAndPunctuation)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))

            // Nút chính + nút dừng
            HStack(spacing: 10) {
                Button(action: applyCoordinates) {
                    Label(isSimulating ? "Cập nhật vị trí" : "Bắt đầu giả lập",
                          systemImage: isSimulating ? "location.fill" : "location")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(role: .destructive, action: stopSimulation) {
                    Image(systemName: "stop.fill")
                        .frame(width: 24)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.red)
                .disabled(!isSimulating)
                .accessibilityLabel("Dừng GPS")
            }

            // Lưu / Đã lưu
            HStack(spacing: 10) {
                Button {
                    if parsedCoordinates() == nil { showMissingCoordinate = true }
                    else { showSavePlace = true }
                } label: {
                    Label("Lưu vị trí", systemImage: "bookmark.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                Button { showBookmarks = true } label: {
                    Label("Đã lưu", systemImage: "bookmark.fill")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(0.15), radius: 10, y: -2)
                .padding(.bottom, -40) // giấu hai góc bo phía dưới
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
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
        // One tap on a bookmark selects the location AND starts simulation.
        // Preserve map behavior: targetCoordinate only changes for saved coordinates.
        simulate(place.coordinate)
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
        activeText = String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude)
    }

    private func stopSimulation() {
        LocSimManager.stopLocSim()
        isSimulating = false
        activeText = ""
    }
}


private struct DisclaimerView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Giới thiệu")
                        .font(.title2).bold()
                    Text("LoTNG là công cụ thử nghiệm mô phỏng vị trí dành cho mục đích nghiên cứu, học tập, phát triển và kiểm tra ứng dụng trên thiết bị do người dùng quản lý.")
                    Text("Miễn trừ trách nhiệm")
                        .font(.title2).bold()
                    Text("Người dùng tự chịu trách nhiệm về việc lựa chọn vị trí, cách sử dụng và việc tuân thủ pháp luật cũng như điều khoản của các dịch vụ liên quan. Không sử dụng ứng dụng để giả mạo nhằm lừa đảo, xâm phạm quyền riêng tư, né tránh các biện pháp bảo vệ hay gây thiệt hại cho người khác.")
                    Text("Ứng dụng được cung cấp theo hiện trạng, không bảo đảm phù hợp với mọi thiết bị hoặc dịch vụ. Hãy chỉ thử nghiệm khi được phép và không dùng vị trí giả lập trong những tình huống liên quan đến an toàn, khẩn cấp hay cần xác định vị trí chính xác.")
                    Text("Version 1.2.0")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle("Thông tin ứng dụng")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
