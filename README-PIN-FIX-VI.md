# Sửa ghim đỏ khi chọn trên bản đồ

Đây là **toàn bộ project LocSim độc lập** dựa trên bản LocSim-Independent-Map-Entitlements-Fix chạy được bản đồ và GPS.

- Chạm ngắn hoặc nhấn giữ khoảng 0,45 giây vào bản đồ sẽ đặt lại ghim đỏ ngay tại điểm chọn.
- Tọa độ trong ô nhập được cập nhật theo điểm chọn, và lệnh GPS giả lập hiện tại vẫn được gọi như trước.
- Khi nhập tọa độ bằng tay và bấm mô phỏng, ghim vẫn chuyển theo tọa độ nhập.
- Không thay đổi `entitlements.plist`, `project.yml` hoặc GitHub Actions; giữ nguyên cấu hình GPS/bản đồ đang chạy.

Giải nén rồi đưa toàn bộ nội dung vào repo GitHub, chạy workflow cũ `Build LocSim Standalone TIPA`.

Chưa kiểm thử biên dịch và chạy thực tế trên iPhone. Nếu chọn trong lãnh thổ Trung Quốc, sự khác biệt giữa hệ tọa độ bản đồ và GPS có thể làm ghim lệch nhẹ, cần kiểm tra riêng nếu gặp tình huống này.
