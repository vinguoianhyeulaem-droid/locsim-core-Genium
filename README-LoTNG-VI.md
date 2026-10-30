# LoTNG · TNG Location v1.0.0

Dựa trên project LocSim độc lập phiên bản Zoom Fix v2 đã được người dùng xác nhận hoạt động.

- Icon cờ đỏ 🚩 (được vẽ lại dưới dạng icon app 1024×1024).
- Tên hiển thị trên màn hình iPhone: **LoTNG**.
- Tiêu đề trong app: **TNG Location**.
- Nút mô phỏng đổi thành **Chạy**; đỏ khi chưa chạy, xanh lá khi đang chạy.
- Giữ nút **Dừng GPS** cũ để tắt mô phỏng và đưa nút **Chạy** về màu đỏ.
- Xóa dòng thông báo phía trên bản đồ.
- Đổi dòng trạng thái dưới bản đồ thành **Version 1.0.0**.
- Giữ nguyên CustomMapView, cơ chế zoom, chọn điểm, quyền GPS và workflow GitHub Actions.

Giải nén toàn bộ mã nguồn vào repository, đảm bảo thư mục `LocSim/Assets.xcassets` được up đầy đủ. Trong Actions chọn **Build LocSim Standalone TIPA** để build như trước. Cài bản TIPA bằng TrollStore. Chưa kiểm thử trên iPhone; lưu bản đang hoạt động để có thể khôi phục.
