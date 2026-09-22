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
        popover.contentSize = NSSize(width: 250, height: 200)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateMenuIcon()
        statusItem.button?.action = #selector(togglePopover)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateMenuIcon), name: NSNotification.Name("UpdateMenuIcon"), object: nil)
    }
    
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
