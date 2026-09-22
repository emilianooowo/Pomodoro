import SwiftUI

struct LiquidGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: Circle())
            .overlay {
                Circle().strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.55), .clear, .black.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            }
            .shadow(color: .black.opacity(0.14), radius: 3, x: 0, y: 1.5)
    }
}

extension View {
    func liquidGlass() -> some View { modifier(LiquidGlassModifier()) }
}

private struct GlassIcon: View {
    let name: String
    var color: Color = .primary
    var size: CGFloat = 27

    var body: some View {
        Image(systemName: name)
            .font(.system(size: size * 0.4, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .liquidGlass()
    }
}

private struct GlassResetIcon: View {
    let color: Color

    var body: some View {
        Image(systemName: "stop.fill")
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(color)
            .frame(width: 22, height: 22)
            .background(.ultraThinMaterial, in: Circle())
            .overlay {
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.55), .clear, .black.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
    }
}

private struct MinuteScale: View {
    let maximumMinutes: Int
    let accentColor: Color
    @Binding var selectedMinutes: Double
    @Binding var hoveredMinute: Int?
    let start: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let lastIndex = max(1, maximumMinutes - 1)

            ZStack {
                ForEach(1...maximumMinutes, id: \.self) { minute in
                    let isMajor = minute.isMultiple(of: 5)
                    let isHovered = hoveredMinute == minute
                    let usableWidth = max(0, geometry.size.width - 2)
                    let x = maximumMinutes == 1
                        ? geometry.size.width / 2
                        : 1 + CGFloat(minute - 1) / CGFloat(lastIndex) * usableWidth

                    Capsule()
                        .fill(minute <= Int(selectedMinutes) ? accentColor : Color.primary.opacity(0.22))
                        .frame(
                            width: 1.8,
                            height: (isMajor ? 11 : 8) + (isHovered ? 3 : 0)
                        )
                        .scaleEffect(isHovered ? 1.16 : 1, anchor: .bottom)
                        .position(x: x, y: geometry.size.height / 2)
                }
            }
            .contentShape(Rectangle())
            .animation(.spring(response: 0.2, dampingFraction: 0.72), value: hoveredMinute)
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    let width = max(1, geometry.size.width)
                    let ratio = min(max(0, location.x / width), 1)
                    let minute = Int(round(ratio * CGFloat(lastIndex))) + 1
                    hoveredMinute = min(maximumMinutes, max(1, minute))
                    selectedMinutes = Double(hoveredMinute ?? 1)
                    NSCursor.pointingHand.set()
                case .ended:
                    hoveredMinute = nil
                    NSCursor.arrow.set()
                }
            }
            .onTapGesture(perform: start)
            .accessibilityLabel("Timer duration")
            .accessibilityValue("\(Int(selectedMinutes)) minutes")
            .accessibilityHint("Move over the scale to preview a duration, then click to start")
        }
    }
}

struct ContentView: View {
    @Environment(PomodoroModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme

    @State private var customMinutes: Double = 0
    @State private var hoveredMinute: Int?

    private var isIdle: Bool { model.state == .idle }
    private var canStart: Bool { isIdle && customMinutes > 0 }
    private var maximumMinutes: Int { max(1, Int(model.maxCustomTime.rounded())) }

    private var timerForeground: Color {
        if model.state == .overtime { return .red }
        return model.progress > 0.72 ? model.timerAccentForegroundColor : .primary
    }

    private var controlForeground: Color {
        if model.state == .overtime { return .red }
        return model.progress > 0.23 ? model.timerAccentForegroundColor : .primary
    }

    private var timerShadowColor: Color {
        if model.progress > 0.72 { return model.timerAccentOpposingColor.opacity(0.32) }
        return colorScheme == .light ? .white.opacity(0.42) : .black.opacity(0.35)
    }

    private func startTimer(minutes: Double? = nil) {
        let duration = minutes ?? customMinutes
        guard duration > 0, isIdle else { return }

        withAnimation(.easeInOut(duration: 0.24)) {
            customMinutes = duration
            model.start(minutes: duration)
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            if isIdle {
                MinuteScale(
                    maximumMinutes: maximumMinutes,
                    accentColor: model.accentColor,
                    selectedMinutes: $customMinutes,
                    hoveredMinute: $hoveredMinute,
                    start: { startTimer() }
                )
                .frame(height: 20)
                .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
            }

            if !isIdle, let sessionStatus = model.sessionStatusText {
                Text(sessionStatus)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(timerForeground.opacity(0.88))
                    .lineLimit(1)
                    .frame(height: 12)
                    .transition(.opacity)
            }

            timerRow
                .zIndex(1)

            if isIdle {
                bottomBar
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, isIdle ? 12 : 10)
        .frame(width: 230)
        .fixedSize(horizontal: true, vertical: true)
        .background(timerProgressBackground)
        .animation(.easeInOut(duration: 0.24), value: model.state)
        .onChange(of: model.maxCustomTime) { _, newLimit in
            customMinutes = min(customMinutes, max(1, newLimit))
        }
        .focusable(false)
    }

    private var timerRow: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Button {
                    if isIdle {
                        startTimer()
                    } else {
                        withAnimation(.easeInOut(duration: 0.18)) { model.toggle() }
                    }
                } label: {
                    GlassIcon(name: primaryControlIcon, color: primaryControlColor, size: 35)
                }
                .buttonStyle(.plain)
                .focusable(false)
                .disabled(isIdle && !canStart)
                .help(primaryControlHelp)

                if model.state == .running || model.state == .paused {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            model.stop()
                        }
                    } label: {
                        GlassResetIcon(color: controlForeground)
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .help("Reset timer")
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }
            }

            Spacer(minLength: 0)

            Text(isIdle ? String(format: "%02d:00", Int(customMinutes)) : model.timeString)
                .font(.system(size: isIdle ? 42 : 40, weight: .thin, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.62)
                .foregroundStyle(isIdle ? Color.primary : timerForeground)
                .shadow(
                    color: isIdle ? .clear : timerShadowColor,
                    radius: 1,
                    x: 0,
                    y: 1
                )
                .frame(minWidth: 132, maxWidth: .infinity, alignment: .trailing)
                .contentTransition(.numericText())
                .accessibilityLabel(isIdle ? "Selected duration" : "Time remaining")
        }
        .frame(height: 50)
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                ForEach(Array(model.presets.enumerated()), id: \.offset) { _, preset in
                    Button { startTimer(minutes: preset) } label: {
                        Text("\(Int(preset))")
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                            .frame(width: 28, height: 28)
                            .liquidGlass()
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .help("Start \(Int(preset)) minute timer")
                }
            }

            Spacer(minLength: 12)

            HStack(spacing: 6) {
                Menu {
                    if model.sessions.isEmpty {
                        Button("Create a Session…") {
                            model.settingsSelection = "Sessions"
                            NotificationCenter.default.post(name: .showPomodoroSettings, object: nil)
                        }
                    } else {
                        ForEach(model.sessions) { session in
                            Button {
                                withAnimation(.easeInOut(duration: 0.24)) {
                                    model.start(session: session)
                                }
                            } label: {
                                Text("\(session.name.isEmpty ? "Untitled Session" : session.name) · \(session.intervalCount)×")
                            }
                        }

                        Divider()

                        Button("Manage Sessions…") {
                            model.settingsSelection = "Sessions"
                            NotificationCenter.default.post(name: .showPomodoroSettings, object: nil)
                        }
                    }
                } label: {
                    GlassIcon(name: "rectangle.stack.fill", size: 28)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .help("Start a session")

                Button {
                    model.settingsSelection = "General"
                    NotificationCenter.default.post(name: .showPomodoroSettings, object: nil)
                } label: {
                    GlassIcon(name: "gearshape.fill", size: 28)
                }
                .buttonStyle(.plain)
                .focusable(false)
                .help("Settings")
            }
        }
        .frame(height: 28)
    }

    private var primaryControlIcon: String {
        switch model.state {
        case .idle, .paused: "play.fill"
        case .running: "pause.fill"
        case .overtime: "stop.fill"
        }
    }

    private var primaryControlColor: Color {
        if isIdle && !canStart { return .secondary.opacity(0.28) }
        return isIdle ? .primary : controlForeground
    }

    private var primaryControlHelp: String {
        switch model.state {
        case .idle: "Start timer"
        case .running: "Pause timer"
        case .paused: "Resume timer"
        case .overtime: "Stop alarm"
        }
    }

    private var timerProgressBackground: some View {
        GeometryReader { geometry in
            if !isIdle {
                model.timerAccentColor
                    .opacity(0.82)
                    .frame(width: geometry.size.width * CGFloat(model.progress))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .animation(.linear(duration: 1), value: model.progress)
                    .transition(.opacity)
            }
        }
    }
}
