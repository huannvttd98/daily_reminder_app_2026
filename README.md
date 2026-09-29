# Nhắc lịch mỗi ngày

App Flutter nhắc lịch tập luyện, bữa ăn / uống nước và việc trong ngày. Dữ liệu lưu trên máy (SQLite), không cần server.

## 1. Cài môi trường (một lần)

1. Cài Flutter SDK (stable): https://docs.flutter.dev/get-started/install/windows/mobile, rồi thêm `flutter\bin` vào PATH.
2. Cài Android Studio → mở SDK Manager, cài Android SDK + Command-line Tools → tạo một máy ảo trong Device Manager (hoặc cắm điện thoại Android đã bật USB debugging).
3. Chạy `flutter doctor --android-licenses`, rồi `flutter doctor` cho tới khi mục Android báo ✓.

> Build iOS cần máy Mac. Trên Windows chỉ chạy được Android.

## 2. Sinh thư mục nền tảng (một lần)

Mã nguồn (`lib/`, `pubspec.yaml`) đã có sẵn. Chạy lệnh sau trong thư mục này để sinh `android/` và `ios/`. Lệnh này không ghi đè file đã có:

```bash
flutter create --project-name daily_reminder_app --org com.example --platforms android,ios .
flutter pub get
```

Xóa file test mẫu (nó gọi tới `MyApp`, class không tồn tại trong app này):

```bash
del test\widget_test.dart
```

## 3. Cấu hình Android cho thông báo

### `android/app/src/main/AndroidManifest.xml`

Thêm ngay trên thẻ `<application>`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

Thêm vào bên trong `<application>`:

```xml
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

### `android/app/build.gradle.kts`

`flutter_local_notifications` cần bật desugaring:

```kotlin
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        // giữ nguyên các dòng sourceCompatibility / targetCompatibility có sẵn
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

## 4. Chạy

```bash
flutter analyze
flutter run
```

## Cấu trúc

```
lib/
  main.dart                     khởi tạo DB, múi giờ, thông báo; 4 tab
  models/                       ReminderItem, Completion / Occurrence / DayStat
  data/database.dart            SQLite: items, completions, settings
  data/sample_data.dart         dữ liệu gợi ý cho lần mở đầu tiên
  services/notification_service.dart   lên lịch / hủy thông báo
  providers/reminder_provider.dart     state chung + thống kê
  screens/                      Hôm nay, Kế hoạch, Thống kê, Cài đặt, Thêm/Sửa
  widgets/                      icon theo loại, dòng lịch có ô tick
```

## Giới hạn đã biết

- iOS chỉ cho tối đa 64 thông báo đang chờ. Nếu đặt nhắc uống nước quá dày, một số lần nhắc sẽ không được đặt lịch.
- Nếu không cấp quyền "nhắc đúng giờ" (Cài đặt → Nhắc đúng giờ), Android có thể nhắc trễ vài phút.
- Khi tắt một lịch nhắc, nó biến mất khỏi Hôm nay / Kế hoạch / Thống kê, kể cả các ngày đã qua.
