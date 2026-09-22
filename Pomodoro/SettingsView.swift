import SwiftUI
import AppKit

struct SettingsView: View {
    @Environment(PomodoroModel.self) private var model

    var body: some View {
        @Bindable var bindableModel = model

        NavigationSplitView {
            List(selection: $bindableModel.settingsSelection) {
                Label("General", systemImage: "gearshape")
                    .tag("General")
                Label("Sessions", systemImage: "rectangle.stack")
                    .tag("Sessions")
            }
            .navigationSplitViewColumnWidth(min: 145, ideal: 145, max: 145)
            .toolbar(removing: .sidebarToggle)
        } detail: {
            if model.settingsSelection == "Sessions" {
                SessionsSettingsView()
            } else {
                GeneralSettingsView()
            }
        }
        .frame(width: 720, height: 600)
    }
}

private struct GeneralSettingsView: View {
    @Environment(PomodoroModel.self) private var model

    private let icons = ["timer", "clock", "hourglass", "alarm", "stopwatch", "circle.dashed"]
    private let sounds = ["Ping", "Glass", "Basso", "Blow", "Bottle", "Frog", "Tink"]

    var body: some View {
        @Bindable var bindableModel = model

        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 26) {
                Text("General")
                    .font(.largeTitle.bold())

                settingsSection("Appearance", subtitle: "Choose the accent color and menu bar icon.") {
                    HStack(spacing: 14) {
                        ColorPicker("Accent color", selection: $bindableModel.accentColor, supportsOpacity: false)
                            .frame(maxWidth: 180, alignment: .leading)

                        Divider().frame(height: 24)

                        HStack(spacing: 7) {
                            ForEach(icons, id: \.self) { icon in
                                Button {
                                    model.menuIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.system(size: 15, weight: .medium))
                                        .frame(width: 32, height: 32)
                                        .background(
                                            model.menuIcon == icon
                                                ? model.accentColor.opacity(0.18)
                                                : Color.primary.opacity(0.045),
                                            in: RoundedRectangle(cornerRadius: 8)
                                        )
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(model.menuIcon == icon ? model.accentColor : .clear, lineWidth: 1.5)
                                        }
                                }
                                .buttonStyle(.plain)
                                .help(icon.capitalized)
                            }
                        }
                    }
                }

                Divider()

                settingsSection("Presets & Limits", subtitle: "Set the scale limit and your quick-start timers.") {
                    HStack(spacing: 18) {
                        HStack(spacing: 6) {
                            Text("Scale limit")
                            TextField("Minutes", value: $bindableModel.maxCustomTime, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 58)
                            Text("min")
                                .foregroundStyle(.secondary)
                        }

                        Divider().frame(height: 28)

                        HStack(spacing: 8) {
                            ForEach(0..<4, id: \.self) { slot in
                                if slot < model.presets.count {
                                    PresetEditCircle(index: slot)
                                } else {
                                    AddPresetCircle(slot: slot)
                                }
                            }
                        }
                    }
                }

                Divider()

                settingsSection("Alarm Sound", subtitle: "Hover over an option to preview it before selecting.") {
                    SoundPicker(
                        selection: $bindableModel.alarmSound,
                        sounds: sounds,
                        onPreview: { model.playSoundPreview(name: $0) }
                    )
                    .frame(width: 180, height: 26)
                }

                Divider()

                Text("Pomodoro 1.5.0")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(30)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollIndicators(.visible)
    }

    private func settingsSection<Content: View>(
        _ title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.title3.bold())
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            content()
        }
    }
}

private struct PresetEditCircle: View {
    @Environment(PomodoroModel.self) private var model
    @State private var isHovering = false
    let index: Int

    private var presetValue: Binding<Double> {
        Binding(
            get: {
                guard model.presets.indices.contains(index) else { return 0 }
                return model.presets[index]
            },
            set: { newValue in
                guard model.presets.indices.contains(index) else { return }
                model.presets[index] = newValue
            }
        )
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TextField("", value: presetValue, format: .number)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .frame(width: 38, height: 38)
                .background(.ultraThinMaterial, in: Circle())
                .overlay {
                    Circle().strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.55), .clear, .black.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                }

            if isHovering && model.presets.count > 1 {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        model.removePreset(at: index)
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .red)
                }
                .buttonStyle(.plain)
                .offset(x: 4, y: -4)
            }
        }
        .frame(width: 42, height: 42)
        .onHover { isHovering = $0 }
    }
}

private struct AddPresetCircle: View {
    @Environment(PomodoroModel.self) private var model
    let slot: Int

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                model.addPreset(at: slot)
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 38, height: 38)
                .overlay {
                    Circle()
                        .strokeBorder(
                            Color.secondary.opacity(0.5),
                            style: StrokeStyle(lineWidth: 1.4, dash: [4, 3])
                        )
                }
        }
        .buttonStyle(.plain)
        .frame(width: 42, height: 42)
        .help("Add preset")
    }
}

private struct SessionsSettingsView: View {
    @Environment(PomodoroModel.self) private var model

    var body: some View {
        @Bindable var bindableModel = model

        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sessions")
                            .font(.largeTitle.bold())
                        Text("Alternate focused intervals and breaks automatically.")
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            model.addSession()
                        }
                    } label: {
                        Label("New Session", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(model.accentColor)
                }

                if model.sessions.isEmpty {
                    ContentUnavailableView(
                        "No Sessions",
                        systemImage: "rectangle.stack.badge.plus",
                        description: Text("Create a session to combine focus intervals with automatic breaks.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 360)
                } else {
                    ForEach(Array(model.sessions.enumerated()), id: \.element.id) { index, session in
                        SessionEditorCard(
                            session: $bindableModel.sessions[index],
                            onDelete: { model.removeSession(id: session.id) }
                        )
                    }
                }
            }
            .padding(30)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct SessionEditorCard: View {
    @Binding var session: FocusSession
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                TextField("Session name", text: $session.name)
                    .textFieldStyle(.plain)
                    .font(.title3.bold())

                Spacer()

                ColorPicker(
                    "Session accent",
                    selection: Binding(
                        get: { session.accentColor },
                        set: { session.setAccentColor($0) }
                    ),
                    supportsOpacity: false
                )
                .labelsHidden()
                .help("Session accent color")

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Delete session")
            }

            HStack(spacing: 18) {
                Stepper(value: $session.intervalCount, in: 1...24) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Intervals")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(session.intervalCount)")
                            .monospacedDigit()
                    }
                }
                .frame(width: 130)

                sessionDurationField("Focus", value: $session.focusMinutes)
                sessionDurationField("Break", value: $session.breakMinutes)
            }
        }
        .padding(18)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(session.accentColor.opacity(0.5), lineWidth: 1.5)
        }
    }

    private func sessionDurationField(_ title: String, value: Binding<Double>) -> some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Minutes", value: value, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 62)
            }
            Text("min")
                .foregroundStyle(.secondary)
                .padding(.top, 15)
        }
    }
}

private struct SoundPicker: NSViewRepresentable {
    @Binding var selection: String
    let sounds: [String]
    let onPreview: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSPopUpButton {
        let picker = NSPopUpButton(frame: .zero, pullsDown: false)
        picker.controlSize = .small
        picker.addItems(withTitles: sounds)
        picker.selectItem(withTitle: selection)
        picker.target = context.coordinator
        picker.action = #selector(Coordinator.didSelect(_:))
        picker.menu?.delegate = context.coordinator
        return picker
    }

    func updateNSView(_ picker: NSPopUpButton, context: Context) {
        context.coordinator.parent = self

        if picker.itemTitles != sounds {
            picker.removeAllItems()
            picker.addItems(withTitles: sounds)
        }
        if picker.titleOfSelectedItem != selection {
            picker.selectItem(withTitle: selection)
        }
        picker.menu?.delegate = context.coordinator
    }

    final class Coordinator: NSObject, NSMenuDelegate {
        var parent: SoundPicker

        init(parent: SoundPicker) {
            self.parent = parent
        }

        @objc func didSelect(_ sender: NSPopUpButton) {
            guard let selectedSound = sender.titleOfSelectedItem else { return }
            parent.selection = selectedSound
        }

        func menu(_ menu: NSMenu, willHighlight item: NSMenuItem?) {
            guard let sound = item?.title, parent.sounds.contains(sound) else { return }
            parent.onPreview(sound)
        }
    }
}
