import SwiftUI
import MapKit
import CoreLocation

struct LocSimView: View {
    @State private var coordinates = ""
    @State private var tappedCoordinate: EquatableCoordinate?
    @State private var mapTarget: EquatableCoordinate?
    @State private var isSimulating = false
    @State private var showError = false
    @StateObject private var bookmarks = BookmarkStore()
    @State private var showBookmarkMenu = false
    @State private var bookmarkQuery = ""
    @State private var showSavePlace = false
    @State private var showMissingCoordinate = false
    @State private var showDisclaimer = false
    @State private var activeText = ""
    @State private var showCoordinateBar = false
    @FocusState private var coordFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                // Bản đồ chiếm toàn màn hình.
                CustomMapView(tappedCoordinate: $tappedCoordinate, targetCoordinate: $mapTarget)
                    .ignoresSafeArea(edges: .bottom)

                // Công tắc giả lập nổi ở dưới cùng
                VStack {
                    Spacer()
                    simulationPill
                        .padding(.bottom, 16)
                }

                // Thanh nhập tọa độ (mở bằng biểu tượng kính lúp)
                if showCoordinateBar {
                    VStack {
                        coordinateBar
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Bảng địa chỉ đã lưu (mở bằng biểu tượng bookmark)
                if showBookmarkMenu {
                    // Chạm ra ngoài để đóng
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { closeBookmarkMenu() }
                    VStack {
                        HStack {
                            Spacer()
                            bookmarkPanel
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 8)
                        Spacer()
                    }
                    .transition(.scale(scale: 0.92, anchor: .topTrailing).combined(with: .opacity))
                }
            }
            .navigationTitle("TNG Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
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
                    Button {
                        toggleCoordinateBar()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .accessibilityLabel("Nhập tọa độ")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismissKeyboard()
                        if showCoordinateBar { closeCoordinateBar() }
                        withAnimation(.easeOut(duration: 0.18)) { showBookmarkMenu.toggle() }
                    } label: {
                        Image(systemName: showBookmarkMenu ? "bookmark.fill" : "bookmark")
                            .accessibilityLabel("Địa chỉ đã lưu")
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
            .sheet(isPresented: $showSavePlace) {
                if let point = parsedCoordinates() {
                    SavePlaceSheet(coordinate: point) { name, savedPoint in
                        bookmarks.add(name: name, coordinate: savedPoint, altitude: 0)
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

    /// Thanh nhập tọa độ: ô nhập + nút dán + nút Go.
    private var coordinateBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "mappin.and.ellipse")
                .foregroundColor(.accentColor)
            TextField("21.5595306,105.2776417", text: $coordinates)
                .keyboardType(.numbersAndPunctuation)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .submitLabel(.go)
                .focused($coordFocused)
                .onSubmit { goToCoordinates() }
                .accessibilityLabel("Tọa độ vĩ độ, kinh độ")
            Button(action: { coordinates = UIPasteboard.general.string ?? "" }) {
                Image(systemName: "doc.on.clipboard")
            }
            .accessibilityLabel("Dán tọa độ")
            Button(action: goToCoordinates) {
                Text("Go").font(.subheadline.weight(.bold))
                    .padding(.horizontal, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(0.18), radius: 8, y: 3)
        )
    }

    /// Viên thuốc nổi ở dưới bản đồ: trạng thái + công tắc xanh (bật) / đỏ (tắt).
    private var simulationPill: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(isSimulating ? "Đang giả lập" : "Đã dừng")
                    .font(.subheadline.weight(.semibold))
                if isSimulating, !activeText.isEmpty {
                    Text(activeText)
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                }
            }
            GPSSwitch(isOn: simulationBinding)
        }
        .padding(.leading, 18)
        .padding(.trailing, 10)
        .padding(.vertical, 9)
        .background(
            Capsule().fill(.regularMaterial)
                .shadow(color: Color.black.opacity(0.18), radius: 8, y: 3)
        )
    }

    /// Bật: giả lập tại tọa độ đang có (chưa có thì mở ô nhập). Tắt: dừng GPS.
    private var simulationBinding: Binding<Bool> {
        Binding(
            get: { isSimulating },
            set: { turnOn in
                if turnOn {
                    if parsedCoordinates() == nil {
                        openCoordinateBar()
                    } else {
                        applyCoordinates()
                    }
                } else {
                    stopSimulation()
                }
            }
        )
    }

    private func goToCoordinates() {
        if applyCoordinates() { closeCoordinateBar() }
    }

    private func toggleCoordinateBar() {
        if showCoordinateBar { closeCoordinateBar() } else { openCoordinateBar() }
    }

    private func openCoordinateBar() {
        if showBookmarkMenu { closeBookmarkMenu() }
        withAnimation(.easeOut(duration: 0.18)) { showCoordinateBar = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { coordFocused = true }
    }

    private func closeCoordinateBar() {
        coordFocused = false
        dismissKeyboard()
        withAnimation(.easeOut(duration: 0.18)) { showCoordinateBar = false }
    }

    private var filteredPlaces: [SavedPlace] {
        let keyword = bookmarkQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let sorted = bookmarks.places.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
        guard !keyword.isEmpty else { return sorted }
        return sorted.filter { $0.name.localizedStandardContains(keyword) ||
            $0.coordinateText.localizedStandardContains(keyword) }
    }

    private var bookmarkPanel: some View {
        VStack(spacing: 0) {
            // Dòng thêm địa chỉ
            Button {
                closeBookmarkMenu()
                if parsedCoordinates() == nil { showMissingCoordinate = true }
                else { showSavePlace = true }
            } label: {
                Label("Thêm địa chỉ", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider()

            // Thanh tìm kiếm
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                TextField("Tìm theo tên hoặc tọa độ", text: $bookmarkQuery)
                    .font(.subheadline)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                if !bookmarkQuery.isEmpty {
                    Button { bookmarkQuery = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Xóa nội dung tìm kiếm")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
            .padding(10)

            Divider()

            // Danh sách địa chỉ đã lưu
            ScrollView {
                LazyVStack(spacing: 0) {
                    if filteredPlaces.isEmpty {
                        Text(bookmarks.places.isEmpty ? "Chưa có địa chỉ nào được lưu." : "Không tìm thấy địa chỉ.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                    }
                    ForEach(filteredPlaces) { place in
                        HStack(spacing: 8) {
                            Button {
                                selectSavedPlace(place)
                                closeBookmarkMenu()
                            } label: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(place.name).font(.subheadline.weight(.semibold))
                                    Text(place.coordinateText).font(.caption).foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            Button(role: .destructive) { bookmarks.remove(place.id) } label: {
                                Image(systemName: "trash").foregroundColor(.red)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Xóa \(place.name)")
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        Divider().padding(.leading, 14)
                    }
                }
            }
            .frame(maxHeight: 260)
        }
        .frame(width: 300)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(0.2), radius: 12, y: 4)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func closeBookmarkMenu() {
        dismissKeyboard()
        withAnimation(.easeOut(duration: 0.18)) { showBookmarkMenu = false }
        bookmarkQuery = ""
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
        mapTarget = EquatableCoordinate(coordinate: place.coordinate)
        // One tap on a bookmark selects the location AND starts simulation.
        // Preserve map behavior: targetCoordinate only changes for saved coordinates.
        simulate(place.coordinate)
    }

    @discardableResult
    private func applyCoordinates() -> Bool {
        let parts = coordinates.split(separator: ",", omittingEmptySubsequences: false)
        guard parts.count == 2,
              let latitude = Double(parts[0].trimmingCharacters(in: .whitespacesAndNewlines)),
              let longitude = Double(parts[1].trimmingCharacters(in: .whitespacesAndNewlines)),
              latitude.isFinite, longitude.isFinite,
              (-90.0...90.0).contains(latitude), (-180.0...180.0).contains(longitude) else {
            showError = true
            return false
        }
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        mapTarget = EquatableCoordinate(coordinate: coordinate)
        simulate(coordinate)
        return true
    }

    private func simulate(_ coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(coordinate: coordinate, altitude: 0,
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


/// Công tắc gạt: bật = xanh, tắt = đỏ.
private struct GPSSwitch: View {
    @Binding var isOn: Bool

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            isOn.toggle()
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule().fill(isOn ? Color.green : Color.red)
                Circle()
                    .fill(Color.white)
                    .padding(3)
                    .shadow(color: Color.black.opacity(0.25), radius: 1.5, y: 1)
            }
            .frame(width: 64, height: 34)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isOn)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Giả lập GPS")
        .accessibilityValue(isOn ? "Bật" : "Tắt")
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
