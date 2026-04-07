# food_delivery_frontend

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Run On Android Automatically

In VS Code, choose the `frontend` launch profile and start debugging. It now:

- uses a running Android emulator if one already exists
- otherwise starts a preferred emulator such as `Pixel_8_Pro`
- waits for it to finish booting
- resets any old `wm size` and `wm density` overrides so the UI matches the device profile
- runs the app on `emulator-5554` automatically

You can also run it manually from the workspace root:

From the workspace root, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\run-frontend-android.ps1
```

That launcher will:

- reuse the current Android emulator when one is already open
- otherwise start a preferred Android emulator automatically
- wait for the emulator to finish booting
- reset stale display overrides from previous sessions
- run `flutter run` against the detected Android device automatically

If you renamed your emulator, pass a different AVD name:

```powershell
powershell -ExecutionPolicy Bypass -File .\run-frontend-android.ps1 -AvdName YourEmulatorName
```

If you intentionally want to test a custom Android display size, pass both a size and a matching density override. Example:

```powershell
powershell -ExecutionPolicy Bypass -File .\run-frontend-android.ps1 -AndroidDisplaySize 376x612 -AndroidDisplayDensity 140
```

For an exact `376x612` device shape, prefer creating a custom AVD instead of forcing that size on an existing emulator.

## Open The App Quickly

If the app is already installed and you just want to open it on the current emulator, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\open-frontend-app.ps1
```

That command will:

- start the emulator if needed
- bring the emulator window to the front
- open the installed app on that device
- fall back to `flutter run` if the app is not installed yet

## Run On A Physical Device

For a real Android phone on the same Wi-Fi as this PC, run from the workspace root:

```powershell
powershell -ExecutionPolicy Bypass -File .\run-frontend-physical.ps1
```

That launcher will:

- detect this PC's private IPv4 address
- pass it to Flutter as `API_BASE_URL`
- keep the existing web and emulator defaults unchanged

If Flutter sees more than one connected device, pass a specific device id:

```powershell
powershell -ExecutionPolicy Bypass -File .\run-frontend-physical.ps1 -DeviceId your-device-id
```

If auto-detect picks the wrong IP, pass the backend host manually:

```powershell
powershell -ExecutionPolicy Bypass -File .\run-frontend-physical.ps1 -BackendHost 192.168.1.50
```

Make sure:

- the phone and this PC are on the same network
- Apache and MySQL are running in XAMPP
- Windows Firewall allows Apache on your private network
