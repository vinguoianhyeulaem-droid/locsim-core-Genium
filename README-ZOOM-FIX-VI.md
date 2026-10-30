# Sửa lỗi bản đồ tự thu nhỏ khi chọn điểm

Project này dựa trên bản **LocSim-Independent-LongPress-Pin-Fix** đã hoạt động.

Lỗi cũ: `CustomMapView.updateUIView` gọi `setRegion` với `latitudeDelta/longitudeDelta = 0.012` mỗi khi chọn điểm. Khi chạm hoặc nhấn giữ, tọa độ đổi làm SwiftUI cập nhật view và zoom quay lại mặc định.

Sửa: Trong `selectCoordinate`, ghi `previousTarget = selected` trước khi phát `tappedCoordinate`. Khi SwiftUI cập nhật `targetCoordinate` từ thao tác chọn ngay trên bản đồ, `updateUIView` nhận ra ghim đã xử lý và không gọi `setRegion` nữa.

- Chạm và nhấn giữ: tọa độ và ghim đổi tại điểm được chọn, giữ nguyên zoom và khung nhìn.
- Nhập tọa độ bằng tay rồi nhấn nút: bản đồ vẫn di chuyển tới tọa độ nhập.
- Không thay đổi GPS, `project.yml`, entitlements hay workflow.

Giải nén toàn bộ vào repo GitHub hiện tại rồi build lại workflow như trước. Chưa kiểm thử trên iPhone thực tế.
