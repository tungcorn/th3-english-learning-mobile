# Báo cáo Kiến trúc Công nghệ theo Checklist (TH3)

Tài liệu này trình bày chi tiết công nghệ, thư viện, thuật toán và vị trí mã nguồn tương ứng với **7 mục trong Checklist của đề bài TH3**.

---

## Bảng tổng hợp nhanh

| Mục Checklist | Công nghệ / Thư viện chính | Vị trí mã nguồn chính | File Test liên quan |
| :--- | :--- | :--- | :--- |
| **1. Cơ sở dữ liệu** | SQLite (`sqflite`), Path Provider | `lib/data/database/`, `lib/data/repositories/` | `test/data/repositories_test.dart` |
| **2. Theo dõi tiến độ & Mục tiêu** | `Stopwatch`, `AppLifecycleListener`, `fl_chart`, Provider | `lib/domain/progress/`, `lib/ui/widgets/minutes_chart.dart` | `test/domain/streak_calculator_test.dart` |
| **3. Nhận dạng giọng nói (API)** | `speech_to_text` (Google Speech Services), `permission_handler` | `lib/services/speech_service.dart`, `practice_screen.dart` | Kiểm thử trên thiết bị thật |
| **4. Thuật toán AI so sánh âm vị** | CMU Pronouncing Dictionary, ARPAbet, Needleman-Wunsch (2 cấp) | `lib/domain/phoneme/` | `test/domain/phoneme_aligner_test.dart`, `accent_simulation_test.dart` |
| **5. Module phản hồi & Gợi ý** | Bảng ký âm IPA, Từ điển khẩu hình tiếng Việt, Engine gợi ý | `lib/domain/feedback/`, `lib/ui/widgets/result_panel.dart` | `test/domain/feedback_engine_test.dart`, `result_panel_test.dart` |
| **6. Thông báo & Giao diện tiến độ** | `flutter_local_notifications`, `timezone`, BootReceiver | `lib/services/notification_service.dart`, `progress_screen.dart` | `test/services/reminder_time_test.dart` |
| **7. Kiểm thử đa người dùng** | Multi-Profile Architecture, Trích xuất CSV, Accent Simulation | `lib/domain/evaluation/attempt_csv.dart`, `ProfileScreen` | `test/domain/accent_simulation_test.dart` |

---

## Chi tiết từng mục Checklist

### Mục 1: Thiết kế cơ sở dữ liệu (Database)

> **Yêu cầu**: Thiết kế cơ sở dữ liệu để lưu trữ thông tin người dùng, lịch sử luyện tập và kết quả phân tích phát âm.

#### 1. Công nghệ sử dụng
* **Hệ quản trị CSDL**: SQLite thông qua thư viện native `sqflite: ^2.4.5`.
* **Mô hình truy xuất dữ liệu**: Repository Pattern kết hợp DAO (Data Access Object) quản lý phiên giao dịch (Transactions).

#### 2. Vị trí mã nguồn
* [`lib/data/database/app_database.dart`](../lib/data/database/app_database.dart):
  * Khởi tạo file CSDL `speak_daily.db`.
  * Bật ràng buộc toàn vẹn khóa ngoại: `PRAGMA foreign_keys = ON`.
  * Hàm `createSchema()` tạo 4 bảng có liên kết chặt chẽ:
    1. `users`: Thông tin người học, mục tiêu học hằng ngày (`daily_goal_minutes`), cấu hình giờ nhắc nhở (`reminder_hour`, `reminder_minute`).
    2. `practice_sessions`: Phiên học, lưu thời gian luyện tập thực tế (`duration_seconds`), ngày theo giờ địa phương (`local_date`) để tính streak không phụ thuộc múi giờ UTC.
    3. `pronunciation_attempts`: Kết quả từng lần đọc (câu mẫu, câu nhận dạng, điểm số 0-100, độ chính xác âm vị, độ tin cậy `confidence`).
    4. `phoneme_errors`: Chi tiết từng âm sai (`expected_phoneme`, `actual_phoneme`).
  * Khóa ngoại sử dụng `ON DELETE CASCADE`: Khi xóa hồ sơ người dùng sẽ tự động xóa sạch toàn bộ lịch sử và lỗi âm vị của người đó.
  * Chỉ mục tăng tốc truy vấn: `idx_sessions_user_date`, `idx_attempts_session`, `idx_errors_attempt`.
* [`lib/data/repositories/`](../lib/data/repositories/):
  * `user_repository.dart`: Thêm, sửa cấu hình mục tiêu/giờ nhắc, xóa hồ sơ.
  * `practice_repository.dart`: Bắt đầu phiên, cập nhật thời gian, lưu kết quả đọc và lỗi âm vị trong một transaction duy nhất.
  * `progress_repository.dart`: Tổng hợp chuỗi ngày, biểu đồ 7 ngày, thống kê top âm yếu.
* **Tài liệu thiết kế**: [`docs/DATABASE.md`](DATABASE.md) (kèm sơ đồ Mermaid ERD chi tiết).
* **Test tự động**: [`test/data/repositories_test.dart`](../test/data/repositories_test.dart).

---

### Mục 2: Theo dõi tiến độ học tập & Đặt mục tiêu hàng ngày

> **Yêu cầu**: Xây dựng tính năng theo dõi tiến độ học tập: đếm số ngày luyện tập liên tiếp (streak), thống kê thời gian học, đặt mục tiêu hàng ngày.

#### 1. Công nghệ sử dụng
* **Đo thời gian học**: Lớp `Stopwatch` kết hợp `AppLifecycleListener` của Flutter (tự động tạm dừng đếm thời gian khi ứng dụng chuyển xuống nền).
* **Vẽ biểu đồ tiến độ**: Thư viện `fl_chart: ^1.3.0`.
* **Quản lý trạng thái**: `provider: ^6.1.5+1`.

#### 2. Vị trí mã nguồn
* [`lib/domain/progress/streak_calculator.dart`](../lib/domain/progress/streak_calculator.dart):
  * Hàm `calculateStreak()`: Nhận danh sách các ngày có luyện tập, chuẩn hóa về ngày UTC (`_dayOf()`).
  * Tính chuỗi ngày hiện tại (`current`) và chuỗi dài nhất trong lịch sử (`longest`).
  * Logic giữ streak: Nếu hôm nay chưa kịp luyện nhưng hôm qua có luyện (`gapToToday <= 1`), streak vẫn được bảo toàn để khuyến khích người học.
* [`lib/ui/widgets/minutes_chart.dart`](../lib/ui/widgets/minutes_chart.dart):
  * Widget `MinutesChart` dùng `BarChart` vẽ biểu đồ cột 7 ngày gần nhất.
  * Vẽ đường dóng nét đứt màu xám thể hiện mức mục tiêu hằng ngày (`goalMinutes`) để người dùng so sánh.
* [`lib/ui/screens/settings_screen.dart`](../lib/ui/screens/settings_screen.dart):
  * Cung cấp các mức chọn mục tiêu hằng ngày: 5, 10, 15, 20, 30 phút qua các thẻ `ChoiceChip`.
* [`lib/ui/screens/today_screen.dart`](../lib/ui/screens/today_screen.dart):
  * Hiển thị biểu tượng ngọn lửa chuỗi ngày (Streak).
  * Thanh `LinearProgressIndicator` hiển thị tiến độ hoàn thành mục tiêu ngày (ví dụ `0/5 phút`).
* **Test tự động**: [`test/domain/streak_calculator_test.dart`](../test/domain/streak_calculator_test.dart).

---

### Mục 3: Tích hợp API nhận dạng giọng nói (Speech Recognition)

> **Yêu cầu**: Tích hợp API nhận dạng giọng nói (speech recognition) để thu âm và xử lý phát âm của người dùng.

#### 1. Công nghệ sử dụng
* **Plugin**: `speech_to_text: ^7.5.0` (kết nối trực tiếp với dịch vụ Google Speech Recognition Engine native trên Android).
* **Quản lý quyền runtime**: `permission_handler: 12.0.1`.

#### 2. Vị trí mã nguồn
* [`lib/services/speech_service.dart`](../lib/services/speech_service.dart):
  * Lớp `SpeechService` bọc các API native:
    * `initialize()`: Khởi tạo engine nhận dạng.
    * `_englishLocale()`: Dò tìm ngôn ngữ nhận dạng, bắt buộc chọn locale tiếng Anh (`en-US` hoặc bất kỳ locale `en-*` nào của máy) để tránh nghe nhầm tiếng Việt.
    * `listen()`: Kích hoạt thu âm với `ListenMode.dictation`, `partialResults: true` (trả về văn bản theo thời gian thực khi người dùng đang nói).
    * Thiết lập `listenFor: Duration(seconds: 30)` và `pauseFor: Duration(seconds: 4)` (tự ngắt khi người dùng dừng nói 4s).
* [`lib/ui/screens/practice_screen.dart`](../lib/ui/screens/practice_screen.dart):
  * Quản lý trạng thái vòng đời thu âm: `_Phase.idle` $\rightarrow$ `_Phase.listening` $\rightarrow$ `_Phase.scoring`.
  * Bắt các mã lỗi nhận dạng chuẩn (`error_no_match`, `error_network`, `error_speech_timeout`, `error_audio_error`) và hiển thị thông báo tiếng Việt thân thiện.
  * Xử lý trường hợp micro bị chặn quyền vĩnh viễn với nút bấm điều hướng thẳng vào Cài đặt hệ điều hành (`openAppSettings()`).
* [`android/app/src/main/AndroidManifest.xml`](../android/app/src/main/AndroidManifest.xml):
  * Cấp quyền hệ thống: `RECORD_AUDIO`, `INTERNET`, `BLUETOOTH_CONNECT`.
  * Khai báo thẻ `<queries><intent><action android:name="android.speech.RecognitionService"/></intent></queries>` để đáp ứng chính sách bảo mật Package Visibility trên Android 11+ (API 30+).

---

### Mục 4: Mô hình AI & Thuật toán so sánh âm vị (Phoneme Comparison)

> **Yêu cầu**: Sử dụng mô hình AI hoặc thuật toán so sánh âm vị (phoneme comparison) để phân tích độ chính xác phát âm và chấm điểm.

#### 1. Công nghệ & Thuật toán sử dụng
* **Tập ký tự âm vị chuẩn**: Bảng mã **ARPAbet** (39 âm vị tiếng Anh chuẩn do CMU phát triển).
* **Từ điển ngữ âm**: **CMU Pronouncing Dictionary** (`cmudict.dict` chứa hơn 130.000 từ).
* **Thuật toán so khớp sinh học**: Quy hoạch động **Needleman-Wunsch Alignment** đa cấp (Two-level Dynamic Programming Alignment).
* **Quy tắc chữ sang âm dự phòng**: Grapheme-to-Phoneme (Rule-based FSM).

#### 2. Vị trí mã nguồn
* [`lib/domain/phoneme/phoneme_dictionary.dart`](../lib/domain/phoneme/phoneme_dictionary.dart):
  * Tải và phân tích từ điển `assets/data/cmudict.dict` trong Isolate chạy ngầm (`compute(parseCmuDict, raw)`).
  * Chuẩn hóa văn bản `normalizeWords()`: Chuyển chữ thường, bỏ dấu câu, chuyển số thành chữ (ví dụ số `4` $\rightarrow$ `four`).
  * Hỗ trợ lưu trữ đa biến thể phát âm cho cùng một từ (ví dụ từ "the" có 2 biến thể: `/ðə/` và `/ði/`).
* [`lib/domain/phoneme/grapheme_to_phoneme.dart`](../lib/domain/phoneme/grapheme_to_phoneme.dart):
  * Chuyển đổi ký tự sang âm vị bằng máy trạng thái cho những từ mới hoặc tên riêng không có trong từ điển CMU (nhận diện các cụm phụ âm đôi "th", "sh", "ch", nguyên âm ghép...).
* [`lib/domain/phoneme/arpabet.dart`](../lib/domain/phoneme/arpabet.dart):
  * Chuyển đổi mã ARPAbet sang ký hiệu phiên âm quốc tế IPA (`arpabetToIpa`).
  * Bảng ma trận tương đồng âm vị [`phonemeSimilarity()`](../lib/domain/phoneme/arpabet.dart#L100):
    * Trùng khớp hoàn toàn: **1.0 điểm**.
    * Thuộc 23 cặp âm dễ nhầm lẫn phổ biến (ví dụ: `/θ/` - `/s/`, `/i/` - `/ɪ/`, `/t/` - `/d/`, `/l/` - `/r/`...): **0.6 điểm** (tính là near miss).
    * Cùng loại (cùng nguyên âm hoặc cùng phụ âm): **0.3 điểm**.
    * Khác loại: **0 điểm**.
* [`lib/domain/phoneme/phoneme_aligner.dart`](../lib/domain/phoneme/phoneme_aligner.dart):
  * Triển khai thuật toán **Needleman-Wunsch** căn chỉnh chuỗi âm vị tối ưu giữa âm mẫu và âm nghe được với điểm thưởng khớp và điểm phạt chèn/xóa (gap score).
* [`lib/domain/phoneme/pronunciation_scorer.dart`](../lib/domain/phoneme/pronunciation_scorer.dart):
  * **Căn chỉnh 2 cấp**: 
    1. Căn chỉnh mức từ (`_alignWords`) trước: Giúp việc người dùng đọc thiếu hoặc thừa 1 từ không làm xô lệch các từ phía sau.
    2. Căn chỉnh mức âm vị (`_bestAlignment`): Thử tất cả biến thể phát âm trong từ điển để chọn cách đọc có điểm số cao nhất cho người học.
  * **Công thức chấm điểm**:
    $$\text{Match} = 60\% \times \text{PhonemeAccuracy} + 40\% \times \text{WordAccuracy}$$
    $$\text{Final Score (0 - 100)} = 85\% \times \text{Match} + 15\% \times \text{EngineConfidence}$$
* **Test tự động**: [`test/domain/phoneme_aligner_test.dart`](../test/domain/phoneme_aligner_test.dart), [`test/domain/pronunciation_scorer_test.dart`](../test/domain/pronunciation_scorer_test.dart), [`test/domain/accent_simulation_test.dart`](../test/domain/accent_simulation_test.dart).

---

### Mục 5: Module phản hồi, đánh dấu âm sai & đề xuất bài tập

> **Yêu cầu**: Xây dựng module phản hồi: hiển thị điểm số, đánh dấu các âm thanh phát âm sai, đề xuất bài tập cải thiện.

#### 1. Công nghệ sử dụng
* **Trực quan hóa UI (UI Components)**: Custom Widgets hiển thị dải âm vị IPA theo mã màu UX.
* **Cơ sở tri thức (Knowledge Base)**: Bộ từ điển mẹo khẩu hình miệng bằng tiếng Việt.
* **Thuật toán gợi ý**: Content-based Exercise Recommendation Engine dựa trên trọng số lỗi âm vị.

#### 2. Vị trí mã nguồn
* [`lib/domain/feedback/feedback_engine.dart`](../lib/domain/feedback/feedback_engine.dart):
  * Hàm `buildFeedback()`: Phân tích kết quả chấm điểm, gom nhóm các lỗi âm vị, đếm tần suất và xếp hạng để chọn ra **Top 3 âm sai nhiều nhất** (`SoundIssue`).
  * Hàm `headlineForScore()`: Tạo nhận xét tổng quan theo thang điểm (Xuất sắc $\ge 90$, Tốt lắm $\ge 75$, Khá ổn $\ge 50$, Cần luyện thêm $< 50$).
* [`lib/domain/feedback/phoneme_tips.dart`](../lib/domain/feedback/phoneme_tips.dart):
  * Bản đồ `phonemeTips` cung cấp hướng dẫn đặt lưỡi, môi, bật hơi bằng tiếng Việt chi tiết cho toàn bộ 39 âm vị (ví dụ âm `/θ/`: *"Đặt đầu lưỡi giữa hai hàm răng và thổi hơi nhẹ, không rung cổ họng. Tránh đọc thành 't' hoặc 's'"*).
* [`lib/domain/exercises/exercise_catalog.dart`](../lib/domain/exercises/exercise_catalog.dart):
  * Kho 23 bài luyện tập phân theo 3 cấp độ (Cơ bản, Trung bình, Nâng cao). Mỗi bài có trường `focus: Set<String>` đánh dấu các âm vị trọng tâm.
  * Hàm `recommendExercises()`: Nhận vào danh sách âm yếu vừa mắc lỗi $\rightarrow$ Quét kho bài tập $\rightarrow$ Lọc ra tối đa 3 bài tập rèn luyện đúng các âm đó (loại trừ bài vừa làm `excludeIds`).
* [`lib/ui/widgets/phoneme_strip.dart`](../lib/ui/widgets/phoneme_strip.dart):
  * Hiển thị từng từ, bên dưới là các ô âm vị tương ứng theo chuẩn IPA quốc tế.
  * Tô màu trực quan theo trạng thái `PhonemeStatus`:
    * **Xanh lá (`correct`)**: Phát âm đúng chuẩn.
    * **Vàng/Cam (`near`)**: Gần đúng (lỗi nhẹ).
    * **Đỏ (`wrong` / `missing`)**: Phát âm sai hoặc nuốt âm (có nhãn "thiếu" hoặc hiện âm nghe nhầm).
    * **Xám (`extra`)**: Âm đọc thừa.
* [`lib/ui/widgets/result_panel.dart`](../lib/ui/widgets/result_panel.dart):
  * Bảng tổng kết kết quả: Điểm số, câu nhận diện, dải âm vị màu, danh sách âm cần chỉnh kèm mẹo tiếng Việt, và danh sách bài tập gợi ý cho phép nhấn để chuyển bài ngay lập tức.
* **Test tự động**: [`test/domain/feedback_engine_test.dart`](../test/domain/feedback_engine_test.dart), [`test/ui/result_panel_test.dart`](../test/ui/result_panel_test.dart).

---

### Mục 6: Hệ thống thông báo nhắc nhở & Giao diện tiến độ

> **Yêu cầu**: Tạo hệ thống thông báo nhắc nhở luyện tập hàng ngày và giao diện hiển thị tiến độ học tập.

#### 1. Công nghệ sử dụng
* **Thông báo cục bộ**: `flutter_local_notifications: ^22.3.3`.
* **Xử lý múi giờ**: `timezone: ^0.11.2`, `flutter_timezone: ^5.1.1`.
* **Khởi động cùng hệ thống**: Android `BroadcastReceiver` bắt sự kiện `BOOT_COMPLETED`.

#### 2. Vị trí mã nguồn
* [`lib/services/notification_service.dart`](../lib/services/notification_service.dart):
  * Lớp `NotificationService`:
    * Khởi tạo kênh thông báo Android độ ưu tiên cao (`Importance.high`, `Priority.high`).
    * Lập lịch thông báo định kỳ hằng ngày bằng `zonedSchedule` với `DateTimeComponents.time`.
    * **Thuật toán nhắc nhở thông minh (`nextReminderTime`)**: Tích hợp cờ `skipToday: goalMetToday`. Nếu hôm nay người học đã hoàn thành mục tiêu ngày, hệ thống tự động dời lịch thông báo sang ngày mai để không làm phiền người dùng.
* [`lib/state/app_state.dart`](../lib/state/app_state.dart):
  * Tự động gọi `syncReminder()` mỗi khi đổi cài đặt giờ nhắc hoặc khi trạng thái đạt mục tiêu ngày thay đổi.
* [`android/app/src/main/AndroidManifest.xml`](../android/app/src/main/AndroidManifest.xml):
  * Đăng ký `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`.
  * Đăng ký 2 receiver của thư viện thông báo: `ScheduledNotificationReceiver` và `ScheduledNotificationBootReceiver` (đảm bảo lịch nhắc không bị mất khi điện thoại khởi động lại).
* [`lib/ui/screens/progress_screen.dart`](../lib/ui/screens/progress_screen.dart):
  * Màn hình Tiến độ hoàn chỉnh: Chuỗi hiện tại, chuỗi dài nhất, tổng thời gian học, số lần đọc, điểm trung bình, biểu đồ cột 7 ngày, top âm hay sai gần đây và danh sách 10 lần đọc mới nhất.
* **Test tự động**: [`test/services/reminder_time_test.dart`](../test/services/reminder_time_test.dart).

---

### Mục 7: Kiểm thử đa người dùng & Đánh giá độ chính xác

> **Yêu cầu**: Kiểm thử ứng dụng với nhiều người dùng và các giọng nói khác nhau để đảm bảo độ chính xác của phân tích AI.

#### 1. Công nghệ sử dụng
* **Kiến trúc Multi-Profile**: Lưu trữ tách biệt theo `user_id` trong SQLite.
* **Trích xuất dữ liệu thực nghiệm**: Parser xuất dữ liệu dạng chuẩn CSV (`RFC 4180`).
* **Test tự động mô phỏng giọng địa phương**: Accent Simulation Test Suite.

#### 2. Vị trí mã nguồn
* [`lib/ui/screens/profile_screen.dart`](../lib/ui/screens/profile_screen.dart):
  * Cho phép nhiều người dùng tạo hồ sơ riêng trên cùng một thiết bị để tiến hành thử nghiệm độc lập mà không bị trộn lẫn số liệu.
* [`lib/domain/evaluation/attempt_csv.dart`](../lib/domain/evaluation/attempt_csv.dart):
  * Hàm `attemptsToCsv()`: Định dạng toàn bộ lịch sử đọc của người dùng thành file CSV gồm các cột: `speaker,exercise,time,expected,recognized,score` (có xử lý ký tự trích dẫn RFC 4180).
  * Trong tab Cài đặt có nút **"Sao chép nhật ký kiểm thử"** để chép trực tiếp dữ liệu thô ra clipboard.
* [`test/domain/accent_simulation_test.dart`](../test/domain/accent_simulation_test.dart):
  * Bộ test tự động giả lập các lỗi phát âm phổ biến của người Việt (nuốt âm cuối `/t/`, `/d/`, đọc nhầm `/θ/` sang `/s/`, nhầm `/l/` và `/r/`...).
  * Kiểm chứng tính ổn định: Khi số lượng lỗi phát âm tăng lên thì điểm số luôn giảm đơn điệu, không xảy ra hiện tượng chấm điểm ngẫu nhiên.
* **Tài liệu kịch bản & kết quả kiểm thử thực tế**:
  * [`docs/KIEM_THU.md`](KIEM_THU.md): Kịch bản kiểm thử 10 bài mẫu trong môi trường yên tĩnh và ồn.
  * [`docs/test-results/MAU_KET_QUA.md`](test-results/MAU_KET_QUA.md): Biểu mẫu thu thập dữ liệu kiểm thử của từng cá nhân.
  * [`docs/test-results/TONG_HOP.md`](test-results/TONG_HOP.md): Bảng tổng hợp độ lệch trung bình giữa điểm AI và người nghe chấm.
