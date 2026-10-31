# Kế hoạch kiểm thử với người dùng thật

Mục tiêu: đánh giá điểm của ứng dụng có khớp với nhận xét của con người trên nhiều người nói và giọng khác nhau hay không.

**Trạng thái: chưa thực hiện.** Các test tự động trong `test/` chỉ kiểm tra logic chấm điểm bằng câu viết tay, không thay thế được phần này.

## Cách làm

1. Chọn ít nhất 6 người nói, đa dạng về giới tính, vùng miền và trình độ tiếng Anh.
2. Mỗi người tạo một hồ sơ riêng trong ứng dụng.
3. Mỗi người đọc 10 bài sau trong mục **Bài luyện**, mỗi bài 2 lần, trong phòng yên tĩnh: Chào hỏi; Giới thiệu bản thân; Âm /θ/ trong "think"; Âm /ð/ trong "this"; /ɪ/ và /i/: ship - sheep; Âm cuối /t/ và /d/; Âm cuối /s/ và /z/; /ʃ/ và /s/; /l/ và /r/; Hội thoại hằng ngày.
4. Một người nghe khác chấm mỗi lần đọc từ 0 đến 100 mà không xem điểm của ứng dụng.
5. Lặp lại 3 bài ở nơi ồn để so sánh.
6. Vào **Cài đặt > Sao chép nhật ký kiểm thử** rồi dán CSV vào file kết quả.

## Mẫu kết quả

Sao chép `docs/test-results/MAU_KET_QUA.md` thành `docs/test-results/<ten-nguoi-kiem-thu>.md` rồi điền kết quả. Khi đủ dữ liệu, tổng hợp vào `docs/test-results/TONG_HOP.md`.

## Đánh giá

- Sai lệch trung bình tuyệt đối giữa điểm app và điểm người nghe, tính theo từng người nói.
- Tỷ lệ âm app đánh dấu sai mà người nghe cũng đồng ý là sai.
- Ghi rõ những giọng hoặc môi trường mà app chấm lệch nhiều.

## Giới hạn đã biết

App chấm từ văn bản do dịch vụ nhận dạng giọng nói trả về, không phân tích trực tiếp sóng âm. Dịch vụ này có xu hướng tự sửa về từ có nghĩa, nên một số lỗi phát âm nhẹ có thể không bị phát hiện. Cần ghi nhận điều này trong báo cáo.
