# Sửa lỗi bản đồ zoom out - lần 2

Nguồn lỗi: `updateUIView` vẫn có lệnh `setRegion` với `latitudeDelta/longitudeDelta = 0.012` khi mục tiêu đổi và trạng thái coordinator chưa đồng bộ.

Thay đổi: chỉ dùng `setRegion` khi lần đầu đặt mục tiêu. Các lần sau dùng `setCenter` để giữ nguyên `region.span` hiện tại. Khi chạm/nhấn giữ bản đồ, `previousTarget` được đặt trước khi binding thay đổi nên không gọi bất kỳ lệnh dịch chuyển camera nào.

Giữ nguyên quyền, GPS và GitHub Actions từ bản trước. Chưa build hoặc kiểm thử thực tế trên iPhone.
