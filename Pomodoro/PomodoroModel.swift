import SwiftUI
import AVFoundation

@Observable
class PomodoroModel {
    static let shared = PomodoroModel()
    enum TimerState { case idle, running, paused, overtime }
    
    var state: TimerState = .idle { didSet { updateMenuIcon() } }
    var timeRemaining: TimeInterval = 0
    var totalDuration: TimeInterval = 0
    var overtime: TimeInterval = 0
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    var presets: [Double] = UserDefaults.standard.array(forKey: "presets") as? [Double] ?? [5, 15, 25, 50] {
        didSet { UserDefaults.standard.set(presets, forKey: "presets") }
    }
    var alarmSound: String = UserDefaults.standard.string(forKey: "alarmSound") ?? "Ping" {
        didSet { UserDefaults.standard.set(alarmSound, forKey: "alarmSound") }
    }
    var menuIcon: String = UserDefaults.standard.string(forKey: "menuIcon") ?? "timer" {
        didSet {
            UserDefaults.standard.set(menuIcon, forKey: "menuIcon")
            updateMenuIcon()
        }
    }
    var maxCustomTime: Double = UserDefaults.standard.double(forKey: "maxCustomTime") == 0 ? 60 : UserDefaults.standard.double(forKey: "maxCustomTime") {
        didSet { UserDefaults.standard.set(maxCustomTime, forKey: "maxCustomTime") }
    }
        var accentColor: Color = {
            if UserDefaults.standard.object(forKey: "accentColorR") != nil {
                let r = UserDefaults.standard.double(forKey: "accentColorR")
                let g = UserDefaults.standard.double(forKey: "accentColorG")
                let b = UserDefaults.standard.double(forKey: "accentColorB")
                return Color(red: r, green: g, blue: b)
            }
            return .blue
        }() {
            didSet {
                if let nsColor = NSColor(accentColor).usingColorSpace(.sRGB) {
                    UserDefaults.standard.set(nsColor.redComponent, forKey: "accentColorR")
                    UserDefaults.standard.set(nsColor.greenComponent, forKey: "accentColorG")
                    UserDefaults.standard.set(nsColor.blueComponent, forKey: "accentColorB")
                }
            }
        }
    
    // MARK: - Visual Logic
    var progress: Double {
        if totalDuration == 0 { return 1.0 }
        return max(0, timeRemaining / totalDuration)
    }
    
    var timeColor: Color {
            switch state {
            case .idle, .running, .paused:
                return .primary
            case .overtime:
                return .red
            }
        }
    
    var timeString: String {
        if state == .overtime { return "+\(formatTime(overtime))" }
        return formatTime(timeRemaining)
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Controls
    func start(minutes: Double) {
        totalDuration = minutes * 60
        timeRemaining = totalDuration
        overtime = 0
        state = .running
        stopAudio()
        startTimer()
    }
    func toggle() {
        switch state {
        case .running: state = .paused; timer?.invalidate()
        case .paused: state = .running; startTimer()
        case .overtime: stop()
        case .idle: break
        }
    }
    func stop() {
        timer?.invalidate()
        timer = nil
        state = .idle
        timeRemaining = 0
        overtime = 0
        stopAudio()
        updateMenuIcon()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in self?.tick() }
    }
    private func tick() {
        if state == .running {
            if timeRemaining > 0 {
                timeRemaining -= 1
                updateMenuIcon()
            } else {
                state = .overtime
                playProgressiveAlarm()
            }
        } else if state == .overtime {
            overtime += 1
        }
    }
    
    // MARK: - Alarm & Icon Logic
    private func updateMenuIcon() {
        NotificationCenter.default.post(name: NSNotification.Name("UpdateMenuIcon"), object: nil)
    }
    
    func playSoundPreview(name: String) { playSound(name: name, isPreview: true) }
    func playProgressiveAlarm() { playSound(name: alarmSound, isPreview: false) }
    
    private func playSound(name: String, isPreview: Bool) {
        let soundURL = URL(fileURLWithPath: "/System/Library/Sounds/\(name).aiff")
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            if isPreview {
                audioPlayer?.volume = 0.5
                audioPlayer?.play()
                return
            }
            audioPlayer?.volume = 0.1
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.play()
            
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] t in
                guard let self = self, self.state == .overtime, let player = self.audioPlayer else { t.invalidate(); return }
                if player.volume < 1.0 { player.volume += 0.15 } else { t.invalidate() }
            }
        } catch { print("Error playing \(name)") }
    }
    private func stopAudio() { audioPlayer?.stop(); audioPlayer = nil }
}
