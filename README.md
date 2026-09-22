# Pomodoro

A compact Pomodoro timer that lives in the macOS menu bar. Built with SwiftUI and AppKit.

<p>
  <img src="pomodoroicon.png" width="128" alt="Pomodoro app icon">
</p>

Pomodoro stays out of the way while keeping the controls you need close at hand. Choose a duration, start a quick preset, or run a complete focus session with automatic breaks.

## Download

1. Open the [latest release](https://github.com/emilianooowo/Pomodoro/releases/latest).
2. Under **Assets**, download `Pomodoro.zip`.
3. Double-click the ZIP file to extract it.
4. Drag `Pomodoro.app` into your **Applications** folder.
5. Open Pomodoro. Its icon will appear in the macOS menu bar; the app does not appear in the Dock.

### If macOS blocks the first launch

Because Pomodoro is distributed outside the Mac App Store, Gatekeeper may ask for confirmation:

1. Control-click `Pomodoro.app` in Applications and choose **Open**.
2. If macOS still blocks it, open **System Settings → Privacy & Security**.
3. Scroll to the Security section and click **Open Anyway** next to Pomodoro.
4. Confirm by clicking **Open**.

You only need to do this for the first launch.

## Features

- **Menu bar app:** Runs without a Dock icon or permanent window.
- **Quick Pomodoro:** Select any duration from the minute scale or use a quick preset.
- **Focus sessions:** Create named sessions with multiple focus intervals and automatic breaks.
- **Custom session colors:** Give every saved session its own accent color.
- **Flexible presets:** Keep between one and four quick-start presets and edit them at any time.
- **Visual progress:** The popup background and menu bar icon show the remaining time.
- **Overtime alert:** The alarm increases gradually and the menu bar icon pulses when time is up.
- **Liquid Glass controls:** Compact native controls that adapt to light and dark mode.
- **Native sounds:** Choose a macOS system sound and preview it directly from Settings.

## Using Pomodoro

### Start a regular Pomodoro

- Move the pointer across the minute scale to preview a duration, then click to start.
- Alternatively, click a preset or select a duration and press Play.
- Use Pause to suspend the timer and Reset to stop it.

### Start a focus session

1. Open **Settings → Sessions**.
2. Create a session and choose its name, number of focus intervals, focus duration, break duration, and accent color.
3. Return to the popup and click the Sessions button.
4. Select the session you want to start.

A session automatically alternates between focus and rest. For example, a session with three focus intervals runs as:

`Focus 1 → Rest → Focus 2 → Rest → Focus 3 → Complete`

## Settings

### General

- App accent color
- Menu bar icon
- Minute-scale limit
- One to four quick presets
- Alarm sound with hover preview

### Sessions

- Create, edit, and delete focus sessions
- Configure focus intervals and breaks
- Assign an individual accent color to each session

## Build from source

1. Clone this repository.
2. Open `Pomodoro.xcodeproj` in Xcode.
3. Select the Pomodoro scheme and run the app.

Pomodoro uses SwiftUI, AppKit, `NSPopover`, and the `LSUIElement` app mode.

## Feedback

Use [GitHub Issues](https://github.com/emilianooowo/Pomodoro/issues) to report a bug or suggest an improvement.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
