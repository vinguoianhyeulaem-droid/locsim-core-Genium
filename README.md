# LocSim Independent — tách từ Geranium

Project **chỉ gồm LocSim** (không có Cleaner, Daemon Manager, Supervise, RootHelper hay Share Extension).
Giữ `CustomMapView`, `CoordTransform`, `LocSimManager` và private CoreLocation headers của Geranium; giao diện SwiftUI độc lập hỗ trợ kéo/chạm bản đồ và dán `vĩ độ,kinh độ`.

## Build

Giải nén, upload **nội dung bên trong** vào repo mới (không gộp vào repo Geranium). Vào Actions → Build LocSim Standalone TIPA → Run workflow. Tải artifact `.tipa`, cài qua TrollStore trên thiết bị tương thích.

**Lưu ý**: đây là project tách độc lập mới, chưa được build trên macOS và chưa thử trên iPhone. Quyền ký được giữ ở mức các quyền chính đã dùng để mô phỏng GPS; các thành phần hệ thống khác của Geranium không được đưa theo. Nếu app báo thành công nhưng Google Maps không nhận GPS, cần đối chiếu entitlement thực tế và nhật ký `locationd` với bản Geranium hoạt động, không kết luận chỉ từ dòng trạng thái. Lỗi Apple Maps trống ở các bản LocSimStandalone cũ cũng có thể phát sinh do cấu hình bản mới — cần thử thực tế.

Tác phẩm phái sinh từ Geranium (c22dev) và thành phần LocSim. Giữ ghi nhận và giấy phép nguồn gốc theo file LICENSE.md.
