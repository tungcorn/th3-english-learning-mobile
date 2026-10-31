# Bước 1: Thử app trên điện thoại Android thật

Mục đích: xác nhận nhận dạng giọng nói và luồng đọc, chấm điểm chạy được với giọng thật (checklist mục 2, 3, 4, 5). Trên máy ảo chưa kiểm tra được phần này.

## Chuẩn bị

- Điện thoại Android có micro và Internet.
- Có ứng dụng Google hoặc dịch vụ nhận dạng giọng nói của Google.
- Máy tính đã cài Flutter, cáp USB.

## Cài app

Cách 1, cắm cáp và chạy trực tiếp:

1. Trên điện thoại, bật **Tùy chọn nhà phát triển** và **Gỡ lỗi USB**.
2. Cắm cáp, chọn **Cho phép** khi điện thoại hỏi.
3. Chạy trong thư mục dự án:

```bash
flutter devices
flutter run --release
```

Cách 2, gửi file APK:

```bash
flutter build apk --release
```

File nằm ở `build/app/outputs/flutter-apk/app-release.apk`. Gửi sang điện thoại rồi mở để cài. Điện thoại có thể yêu cầu cho phép cài từ nguồn không xác định.

## Các bước kiểm tra

Đánh dấu từng dòng sau khi làm:

- [ ] Tạo hồ sơ mới, app chuyển sang màn **Hôm nay**.
- [ ] Mở một bài, nhấn micro, chọn **Cho phép** khi app xin quyền micro.
- [ ] Đọc đúng câu mẫu: chữ hiện dần khi đang nghe, sau đó có điểm cao.
- [ ] Đọc sai có chủ ý, ví dụ đọc "think" thành "sink": điểm giảm, âm /θ/ được đánh dấu, có mẹo sửa và bài tập gợi ý.
- [ ] Bỏ qua một từ: từ đó hiện **Chưa nghe thấy từ này**.
- [ ] Nhấn micro rồi im lặng: app báo chưa nghe rõ và không lưu điểm.
- [ ] Nhấn nút dừng khi đang đọc: app vẫn chấm phần đã nghe được.
- [ ] Bấm vào bài tập gợi ý: mở đúng bài đó.
- [ ] Quay lại **Hôm nay**: streak thành 1 ngày và số phút tăng sau khi đã luyện đủ một phút.
- [ ] Mở **Tiến độ**: có thời gian học, số lần đọc, điểm trung bình, biểu đồ và lần đọc vừa rồi.
- [ ] Mở **Bài luyện**: danh sách đủ 3 mức, cuộn không lỗi hiển thị.
- [ ] Trong **Cài đặt**, đổi mục tiêu: màn **Hôm nay** cập nhật theo.
- [ ] Tắt hẳn rồi mở lại app: vẫn vào đúng hồ sơ, dữ liệu còn nguyên.
- [ ] Tạo hồ sơ thứ hai qua **Đổi hồ sơ**: hồ sơ mới không thấy dữ liệu của hồ sơ đầu.

Streak qua nhiều ngày chỉ kiểm tra được bằng cách luyện vào ngày hôm sau. Chỉnh lùi đồng hồ điện thoại có thể làm sai dữ liệu thử.

## Khi gặp lỗi

| Hiện tượng | Cách xử lý |
| --- | --- |
| Báo không dùng được nhận dạng giọng nói | Cài hoặc cập nhật ứng dụng Google, đặt làm dịch vụ nhận dạng mặc định |
| Báo micro bị chặn | Nhấn **Mở cài đặt** và bật quyền micro cho app |
| Báo không kết nối được dịch vụ | Kiểm tra Internet |
| Luôn báo chưa nghe rõ | Nói to hơn, thử nơi yên tĩnh, kiểm tra micro bằng ứng dụng khác |
| App đóng đột ngột | Cắm cáp, chạy `flutter run` để xem lỗi và lưu lại nội dung lỗi |

Ghi lại model máy, phiên bản Android và lỗi gặp phải để đưa vào báo cáo.
