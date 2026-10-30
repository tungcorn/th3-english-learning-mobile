# Speak Daily

Ứng dụng Flutter giúp luyện phát âm tiếng Anh hằng ngày: đọc câu mẫu, nhận điểm theo từng âm, xem gợi ý sửa lỗi và theo dõi chuỗi ngày luyện tập.

## Chạy ứng dụng

```bash
flutter pub get
flutter run        # cần thiết bị hoặc máy ảo Android/iOS
flutter test
flutter analyze
```

Nhận dạng giọng nói dùng dịch vụ có sẵn trên máy. Máy cần có micro, dịch vụ nhận dạng (như Google trên Android) và thường cần Internet.

## Đáp ứng yêu cầu đề bài

| Yêu cầu | Vị trí |
| --- | --- |
| Cơ sở dữ liệu | `lib/data/`, `docs/DATABASE.md` |
| Streak, thời gian học, mục tiêu ngày | `lib/domain/progress/`, `lib/data/repositories/progress_repository.dart` |
| Nhận dạng giọng nói | `lib/services/speech_service.dart`, `lib/ui/screens/practice_screen.dart` |
| So sánh âm vị và chấm điểm | `lib/domain/phoneme/` |
| Điểm số, đánh dấu âm sai, đề xuất bài tập | `lib/domain/feedback/`, `lib/ui/widgets/result_panel.dart` |
| Thông báo nhắc nhở, giao diện tiến độ | `lib/services/notification_service.dart`, `lib/ui/screens/progress_screen.dart` |
| Kiểm thử nhiều người và giọng nói | `docs/KIEM_THU.md` (cần nhóm thực hiện) |

## Cách chấm điểm

1. Dịch vụ nhận dạng giọng nói chuyển lời đọc thành văn bản.
2. Câu mẫu và văn bản nghe được được đổi sang âm vị bằng CMU Pronouncing Dictionary. Từ không có trong từ điển dùng quy tắc chữ sang âm.
3. Thuật toán Needleman-Wunsch căn chỉnh theo từ rồi theo âm. Âm giống nhau được 1 điểm, âm dễ nhầm được 0,6, âm cùng nhóm được 0,3.
4. Mức khớp gồm 60% độ khớp âm vị và 40% tỷ lệ từ đọc đúng hoàn toàn.
5. Điểm cuối gồm 85% mức khớp và 15% độ tin cậy của dịch vụ nhận dạng, nếu máy có trả về độ tin cậy. Nếu không có độ tin cậy, điểm cuối chính là mức khớp.

Giới hạn: app chấm từ văn bản nhận dạng, không phân tích trực tiếp sóng âm, nên lỗi nhẹ có thể bị dịch vụ tự sửa và không bị phát hiện.

## Tự chỉnh sửa

| Muốn đổi | Sửa ở đâu |
| --- | --- |
| Thêm hoặc sửa bài luyện | `lib/domain/exercises/exercise_catalog.dart` |
| Mẹo phát âm | `lib/domain/feedback/phoneme_tips.dart` |
| Cách tính điểm, các cặp âm dễ nhầm | `lib/domain/phoneme/arpabet.dart`, `pronunciation_scorer.dart` |
| Màu sắc, kiểu chữ | `lib/ui/theme.dart` |
| Nội dung các màn hình | `lib/ui/screens/` |
| Thêm cột hoặc bảng dữ liệu | `lib/data/database/app_database.dart` (tăng `schemaVersion` và thêm `onUpgrade`) |

Sau khi sửa, chạy `flutter analyze` và `flutter test` để kiểm tra.

## Việc cần làm trước khi nộp

Làm theo thứ tự:

1. [Thử trên điện thoại thật](docs/huong-dan/01_THU_TREN_DIEN_THOAI.md)
2. [Kiểm tra thông báo](docs/huong-dan/02_KIEM_TRA_THONG_BAO.md)
3. [Kiểm thử với nhiều người và giọng nói](docs/KIEM_THU.md)

## Nguồn dữ liệu

`assets/data/cmudict.dict` lấy từ [CMU Pronouncing Dictionary](https://github.com/cmusphinx/cmudict), giấy phép BSD.
