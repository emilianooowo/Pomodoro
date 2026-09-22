import SwiftUI
import AppKit

struct SettingsView: View {
    var body: some View {
        GeneralSettingsView()
            .frame(width: 620, height: 560)
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
                            ForEach(Array(model.presets.indices), id: \.self) { index in
                                PresetEditCircle(index: index)
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

                Text("Pomodoro 1.4.0")
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
    let index: Int

    var body: some View {
        TextField("", value: Bindable(model).presets[index], format: .number)
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
