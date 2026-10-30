# LocSim độc lập – thử sửa bản đồ không hiển thị

Bản này giữ nguyên mã nguồn LocSimIndependent đang sử dụng, chỉ bổ sung `com.apple.security.iokit-user-client-class` vào `entitlements.plist`, khôi phục ba mục có trong `entitlements.plist` Geranium gốc: `AGXDeviceUserClient`, `IOHDIXControllerUserClient`, `IOSurfaceRootUserClient`. Chúng liên quan đến quyền truy cập IOKit/đồ họa; chưa thể khẳng định là nguyên nhân khiến MapKit không vẽ bản đồ.

Thực hiện: giải nén toàn bộ ZIP, ghi đè mã nguồn của repository LocSim độc lập; kiểm tra `.github/workflows/build.yml` được giữ khi up GitHub (thư mục `.github` là thư mục ẩn); chạy lại workflow. Kiểm tra cả màn hình bản đồ lẫn Google Maps sau khi cài qua TrollStore.

Điểm cần kiểm chứng: Giao diện map có xuất hiện đường/phố không, đồng thời GPS toàn hệ thống còn đổi được không. Nếu vẫn trắng, cần lấy log thiết bị của `mapd`, `geod`, `Maps`, `locationd` và log ứng dụng để tìm lỗi cấp quyền hoặc tải tile; không thể chẩn đoán chắc qua ảnh.

**Chưa chạy build Xcode hoặc thử nghiệm trên iPhone.**
