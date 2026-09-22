import SwiftUI
import AppKit

@main
struct PomoBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
                .environment(PomodoroModel.shared)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentView = ContentView().environment(PomodoroModel.shared)
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 260, height: 200)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateMenuIcon()
        
        // 1. Escuchar Clicks Izquierdos Y Derechos
        if let button = statusItem.button {
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.action = #selector(handleStatusItemClick(_:))
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateMenuIcon), name: NSNotification.Name("UpdateMenuIcon"), object: nil)
    }
    
    // 2. Discriminador de Clicks
    @objc func handleStatusItemClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            showContextMenu(sender)
        } else {
            togglePopover(sender)
        }
    }
    
    // 3. El Menú Nativo (Click Derecho)
    func showContextMenu(_ sender: NSStatusBarButton) {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "What's New", action: #selector(openWhatsNew), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Pomodoro", action: #selector(quitApp), keyEquivalent: "q"))
        
        // Si el popover estaba abierto, ciérralo
        if popover.isShown { popover.performClose(nil) }
        
        // Muestra el menú debajo del icono
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 5), in: sender)
    }
    
    // MARK: - Acciones del Menú
        @objc func openSettings() {
            PomodoroModel.shared.settingsSelection = "Appearance"
            // Usamos NSSelectorFromString para evitar la advertencia de SwiftUI
            NSApp.sendAction(NSSelectorFromString("showSettingsWindow:"), to: nil, from: nil)
        }
        
        @objc func openWhatsNew() {
            PomodoroModel.shared.settingsSelection = "WhatsNew"
            NSApp.sendAction(NSSelectorFromString("showSettingsWindow:"), to: nil, from: nil)
        }
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    // MARK: - Lógica Anterior
    @objc func updateMenuIcon() {
        guard let button = statusItem.button else { return }
        let model = PomodoroModel.shared
        let currentProgress = model.state == .idle ? 0.0 : model.progress
        button.image = generateProgressIcon(iconName: model.menuIcon, progress: currentProgress)
    }
    
    func generateProgressIcon(iconName: String, progress: Double) -> NSImage {
        let fillRatio = 1.0 - progress
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        guard let baseImage = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)?.withSymbolConfiguration(config) else { return NSImage() }
        let size = baseImage.size
        let image = NSImage(size: size)
        image.lockFocus()
        baseImage.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .sourceOver, fraction: 0.3)
        let clipHeight = size.height * CGFloat(fillRatio)
        let clipRect = NSRect(x: 0, y: 0, width: size.width, height: clipHeight)
        NSGraphicsContext.current?.saveGraphicsState()
        NSBezierPath.clip(clipRect)
        baseImage.draw(in: NSRect(origin: .zero, size: size), from: .zero, operation: .sourceOver, fraction: 1.0)
        NSGraphicsContext.current?.restoreGraphicsState()
        image.unlockFocus()
        image.isTemplate = true
        return image
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}
