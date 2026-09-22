import SwiftUI

struct SettingsView: View {
    @Environment(PomodoroModel.self) var model
    
    var body: some View {
        @Bindable var bindableModel = model
        
        NavigationSplitView {
            List(selection: $bindableModel.settingsSelection) {
                Label("Appearance", systemImage: "paintpalette").tag("Appearance")
                Label("Presets & Limits", systemImage: "slider.horizontal.3").tag("Presets")
                Label("Sound", systemImage: "speaker.wave.2").tag("Alarm")
                
                Divider() // Un separador limpio
                
                Label("What's New", systemImage: "sparkles").tag("WhatsNew")
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 160, max: 160)
            .toolbar(removing: .sidebarToggle)
        } detail: {
            switch model.settingsSelection {
            case "Appearance": AppearanceSettings()
            case "Presets": PresetsSettings()
            case "Alarm": AlarmSettings()
            case "WhatsNew": WhatsNewView()
            default: Text("Select an option")
            }
        }
        .frame(width: 600, height: 420)
    }
}

struct WhatsNewView: View {
    @Environment(PomodoroModel.self) var model
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            
            Text("What's New").font(.largeTitle.bold())
            
            VStack(alignment: .leading, spacing: 24) {
                // Feature 1
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: "magicmouse.fill")
                        .font(.title)
                        .foregroundColor(model.accentColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Right-Click Menu").font(.headline)
                        Text("You can now right-click the menu bar icon to quickly access settings or safely quit the application.")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Feature 2
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: "drop.fill")
                        .font(.title)
                        .foregroundColor(model.accentColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Liquid Glass Settings").font(.headline)
                        Text("The settings button inside the popover now features a beautiful, translucent native material design.")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.top, 10)
            
            Spacer()
        }
        .padding(40)
    }
}

// MARK: - 1. Appearance Settings
struct AppearanceSettings: View {
    @Environment(PomodoroModel.self) var model
    
    // Time/Pomodoro related SF Symbols
    let icons = ["timer", "clock", "hourglass", "alarm", "stopwatch", "circle.dashed"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Accent Color").font(.title2.bold())
                Text("Choose the main color for the active states and sliders.").foregroundColor(.secondary)
                
                HStack {
                    ColorPicker("Select a custom color", selection: Bindable(model).accentColor, supportsOpacity: false)
                        .labelsHidden()
                        .frame(width: 44, height: 44)
                        .scaleEffect(1.2, anchor: .leading)
                    
                    Text("Click the circle to pick a color")
                        .foregroundColor(.secondary)
                        .font(.system(size: 13))
                        .padding(.leading, 8)
                }
                .padding(.top, 5)
            }
            
            Divider()
            
            // MENU BAR ICON
            VStack(alignment: .leading, spacing: 10) {
                Text("Menu Bar Icon").font(.title2.bold())
                Text("Fills from bottom to top as the timer progresses.").foregroundColor(.secondary)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 16) {
                    ForEach(icons, id: \.self) { icon in
                        Image(systemName: icon)
                            .font(.system(size: 24))
                            .frame(width: 60, height: 60)
                            .background(model.menuIcon == icon ? model.accentColor.opacity(0.2) : Color.primary.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay( RoundedRectangle(cornerRadius: 12).stroke(model.menuIcon == icon ? model.accentColor : Color.clear, lineWidth: 2) )
                            .onTapGesture { model.menuIcon = icon }
                            .onHover { h in if h { NSCursor.pointingHand.set() } }
                    }
                }
                .padding(.top, 10)
            }
            Spacer()
        }
        .padding(30)
    }
}

// MARK: - 2. Presets & Limits Settings
struct PresetsSettings: View {
    @Environment(PomodoroModel.self) var model
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Slider Limit").font(.title2.bold())
                HStack {
                    Text("Maximum draggable time:")
                    Spacer()
                    TextField("", value: Bindable(model).maxCustomTime, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                    Text("min")
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Quick Presets").font(.title2.bold())
                Text("Click a circle to edit its value.").foregroundColor(.secondary)
                
                HStack(spacing: 20) {
                    ForEach(0..<4, id: \.self) { index in
                        PresetEditCircle(index: index)
                    }
                }
                .padding(.top, 10)
            }
            Spacer()
        }
        .padding(30)
    }
}

struct PresetEditCircle: View {
    @Environment(PomodoroModel.self) var model
    let index: Int
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .overlay( Circle().strokeBorder(LinearGradient(colors: [.white.opacity(0.6), .clear, .black.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1) )
                .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
            
            TextField("", value: Bindable(model).presets[index], format: .number)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.center)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .frame(width: 50, height: 50)
        }
        .frame(width: 60, height: 60)
    }
}

// MARK: - 3. Alarm Settings
struct AlarmSettings: View {
    @Environment(PomodoroModel.self) var model
    let sounds = ["Ping", "Glass", "Basso", "Blow", "Bottle", "Frog", "Tink"]
    @State private var hoveredSound: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Alarm Sound").font(.title2.bold()).padding(30)
            
            List(sounds, id: \.self) { sound in
                HStack {
                    Text(sound).font(.system(size: 16))
                    Spacer()
                    if model.alarmSound == sound {
                        Image(systemName: "checkmark").foregroundColor(model.accentColor)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(model.alarmSound == sound ? model.accentColor.opacity(0.1) : (hoveredSound == sound ? Color.primary.opacity(0.05) : Color.clear))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
                .onHover { isHovered in
                    if isHovered {
                        hoveredSound = sound
                        NSCursor.pointingHand.set()
                        model.playSoundPreview(name: sound)
                    } else if hoveredSound == sound {
                        hoveredSound = nil
                    }
                }
                .onTapGesture { model.alarmSound = sound }
            }
            .listStyle(.plain)
            .padding(.horizontal, 14)
        }
    }
}
