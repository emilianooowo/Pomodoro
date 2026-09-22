import SwiftUI

// MARK: - Smart Modifiers
struct PresetGlassModifier: ViewModifier {
    var isActive: Bool
    var accentColor: Color
    
    func body(content: Content) -> some View {
        Group {
            if isActive {
                content
                    .background(accentColor.gradient)
                    .shadow(color: accentColor.opacity(0.4), radius: 6, x: 0, y: 3)
            } else {
                content
                    .background(.ultraThinMaterial)
                    .overlay( Circle().strokeBorder(LinearGradient(colors: [.white.opacity(0.6), .clear, .black.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1) )
                    .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
            }
        }
        .clipShape(Circle())
    }
}

// MARK: - Main View
struct ContentView: View {
    @Environment(PomodoroModel.self) var model
    
    @State private var customMinutes: Double = 0
    @State private var dragOffset: CGFloat = 0
    @State private var activePreset: Double? = nil
    @State private var isHoveringSlider: Bool = false
    
    var body: some View {
        VStack(spacing: 24) {
            
            // 1. TOP BAR (Pause/Reset, Play, Settings)
            ZStack {
                // Pause & Reset (Stop)
                HStack(spacing: 16) {
                    Button(action: { withAnimation { model.toggle() } }) {
                        Image(systemName: model.state == .paused ? "play.fill" : "pause.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(model.state == .idle ? .secondary.opacity(0.2) : .primary)
                    }
                    .buttonStyle(.plain)
                    .focusable(false) // Elimina el auto-focus del Tab
                    .disabled(model.state == .idle)
                    .onHover { h in if h && model.state != .idle { NSCursor.pointingHand.set() } }
                    
                    Button(action: { withAnimation { model.stop(); activePreset = nil } }) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(model.state == .idle ? .secondary.opacity(0.2) : .primary)
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .disabled(model.state == .idle)
                    .onHover { h in if h && model.state != .idle { NSCursor.pointingHand.set() } }
                    
                    Spacer()
                }
                
                // Play
                Button(action: {
                    if customMinutes > 0 && model.state == .idle {
                        withAnimation { activePreset = nil; model.start(minutes: customMinutes) }
                    }
                }) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor((customMinutes > 0 && model.state == .idle) ? .primary : .secondary.opacity(0.2))
                }
                .buttonStyle(.plain)
                .focusable(false)
                .disabled(customMinutes <= 0 || model.state != .idle)
                .onHover { h in if h && customMinutes > 0 && model.state == .idle { NSCursor.pointingHand.set() } }
                
                // Settings
                HStack {
                    Spacer()
                    Button(action: { NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .onHover { h in if h { NSCursor.pointingHand.set() } }
                }
            }
            .frame(height: 20)
            
            if model.state == .idle {
                // 2. SLIDER
                GeometryReader { geo in
                    let sliderWidth = geo.size.width - 24
                    let progress = customMinutes / model.maxCustomTime
                    let thumbX = progress * Double(sliderWidth)
                    
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.primary.opacity(0.1)).frame(height: 4)
                        Capsule().fill(model.accentColor).frame(width: max(0, CGFloat(thumbX) + 12), height: 4)
                        
                        Image(systemName: model.menuIcon)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(.ultraThinMaterial).shadow(radius: 2))
                            .offset(x: CGFloat(thumbX))
                    }
                    .contentShape(Rectangle())
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            isHoveringSlider = true
                            let newX = min(max(0, location.x - 12), sliderWidth)
                            customMinutes = round((newX / sliderWidth) * model.maxCustomTime)
                        case .ended:
                            isHoveringSlider = false
                        }
                    }
                }
                .frame(height: 24)
                .padding(.horizontal, 10)
                .transition(.opacity.combined(with: .scale(scale: 0.9))) // Se difumina y encoge al desaparecer
            }
            
            // 3. TIMER TEXT
            ZStack {
                if model.state == .idle {
                    HStack {
                        Image(systemName: "arrow.counterclockwise").foregroundColor(.red.opacity(dragOffset > 20 ? 1 : 0)).offset(x: 20)
                        Spacer()
                        Image(systemName: "play.fill").foregroundColor(.green.opacity(dragOffset < -20 ? 1 : 0)).offset(x: -20)
                    }
                }
                
                Text(model.state == .idle ? String(format: "%02d:00", Int(customMinutes)) : model.timeString)
                    .font(.system(size: 60, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(model.timeColor)
                    .opacity(model.state == .idle && isHoveringSlider ? 0.4 : 1.0)
                    .padding(.horizontal, 16)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThickMaterial).opacity(dragOffset == 0 ? 0 : 1))
                    .offset(x: dragOffset)
                    .gesture(
                        DragGesture(minimumDistance: 10)
                            .onChanged { value in
                                if model.state == .idle {
                                    let dx = value.translation.width
                                    if customMinutes > 0 || dx > 0 { dragOffset = dx > 0 ? min(dx, 60) : max(dx, -60) }
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    if model.state == .idle {
                                        if dragOffset > 40 { customMinutes = 0 }
                                        else if dragOffset < -40 && customMinutes > 0 { activePreset = nil; model.start(minutes: customMinutes) }
                                    }
                                    dragOffset = 0
                                }
                            }
                    )
            }
            .frame(height: 65)
            
            if model.state == .idle {
                // 4. PRESETS
                HStack(spacing: 12) {
                    ForEach(model.presets, id: \.self) { preset in
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                activePreset = preset
                                model.start(minutes: preset)
                            }
                        }) {
                            Text("\(Int(preset))")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                                .modifier(PresetGlassModifier(isActive: false, accentColor: model.accentColor))
                        }
                        .buttonStyle(.plain)
                        .focusable(false)
                        .onHover { h in if h { NSCursor.pointingHand.set() } }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 24)
        .frame(width: 260)
        .fixedSize()
        
        .background(
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Color.clear
                    
                    if model.state != .idle {
                        model.accentColor
                            .opacity(0.8)
                            .frame(width: geo.size.width * CGFloat(model.progress))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .animation(.linear(duration: 1.0), value: model.progress)
                            .transition(.opacity)
                    }
                }
            }
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: model.state)
        .focusable(false)
    }
}
