import SwiftUI
import AppKit
import ServiceManagement

@main
struct QuickAccessApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    let favoritesManager = FavoritesManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = makeMenuBarIcon()
        }

        rebuildMenu()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(favoritesChanged),
            name: FavoritesManager.didChangeNotification,
            object: nil
        )
    }

    @objc func favoritesChanged() {
        rebuildMenu()
    }

    func rebuildMenu() {
        let menu = NSMenu()

        let favorites = favoritesManager.favorites

        if favorites.isEmpty {
            let emptyItem = NSMenuItem(title: "No favorites yet", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for (index, path) in favorites.enumerated() {
                let isDir = isDirectory(atPath: path)
                let icon = isDir ? "folder.fill" : "doc.fill"

                let item = NSMenuItem(title: path, action: #selector(openFavorite(_:)), keyEquivalent: "")
                item.target = self
                item.tag = index
                if let img = NSImage(systemSymbolName: icon, accessibilityDescription: nil) {
                    img.isTemplate = true
                    item.image = img
                }
                menu.addItem(item)
            }
        }

        menu.addItem(NSMenuItem.separator())

        let addItem = NSMenuItem(title: "Add File or Folder…", action: #selector(addFavorite), keyEquivalent: "a")
        addItem.target = self
        menu.addItem(addItem)

        if !favorites.isEmpty {
            let removeSubmenu = NSMenu()
            for (index, path) in favorites.enumerated() {
                let item = NSMenuItem(title: path, action: #selector(removeFavorite(_:)), keyEquivalent: "")
                item.target = self
                item.tag = index
                removeSubmenu.addItem(item)
            }
            removeSubmenu.addItem(NSMenuItem.separator())
            let removeAllItem = NSMenuItem(title: "Remove All", action: #selector(removeAllFavorites), keyEquivalent: "")
            removeAllItem.target = self
            removeSubmenu.addItem(removeAllItem)

            let removeItem = NSMenuItem(title: "Remove…", action: nil, keyEquivalent: "")
            removeItem.submenu = removeSubmenu
            menu.addItem(removeItem)
        }

        menu.addItem(NSMenuItem.separator())

        let loginItem = NSMenuItem(title: "Start at Login", action: #selector(toggleLoginItem(_:)), keyEquivalent: "")
        loginItem.target = self
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(NSMenuItem.separator())

        let aboutItem = NSMenuItem(title: "About Quick Access", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        let quitItem = NSMenuItem(title: "Quit Quick Access", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc func openFavorite(_ sender: NSMenuItem) {
        let path = favoritesManager.favorites[sender.tag]
        let url = URL(fileURLWithPath: path)

        if isDirectory(atPath: path) {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
        } else {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func addFavorite() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.message = "Select files or folders to add to Quick Access"
        panel.prompt = "Add"

        NSApp.activate(ignoringOtherApps: true)

        if panel.runModal() == .OK {
            for url in panel.urls {
                favoritesManager.add(url.path)
            }
        }
    }

    @objc func removeFavorite(_ sender: NSMenuItem) {
        let path = favoritesManager.favorites[sender.tag]
        favoritesManager.remove(path)
    }

    @objc func removeAllFavorites() {
        let alert = NSAlert()
        alert.messageText = "Remove all favorites?"
        alert.informativeText = "This cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Remove All")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            favoritesManager.removeAll()
        }
    }

    @objc func toggleLoginItem(_ sender: NSMenuItem) {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Could not update login item"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            NSApp.activate(ignoringOtherApps: true)
            alert.runModal()
        }
        rebuildMenu()
    }

    @objc func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "Quick Access"
        alert.informativeText = "Version 1.0\n\nA menu bar app for quick access to your favourite files and folders.\n\n© 2026 pzac.net"
        alert.alertStyle = .informational
        if let icon = NSImage(named: "AppIcon") ?? NSApp.applicationIconImage {
            alert.icon = icon
        }
        alert.runModal()
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }

    private func isDirectory(atPath path: String) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }

    private func makeMenuBarIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            NSGraphicsContext.current?.cgContext.translateBy(x: 0, y: 0)
            let path = Self.starPath(in: rect.insetBy(dx: 1, dy: 1))
            NSColor.black.setFill()
            path.fill()
            return true
        }
        image.isTemplate = true
        return image
    }

    static func starPath(in rect: NSRect) -> NSBezierPath {
        let cx = rect.midX
        let cy = rect.midY
        let outerRadius = min(rect.width, rect.height) / 2.0
        let innerRadius = outerRadius * 0.38
        let points = 5
        let path = NSBezierPath()

        for i in 0..<(points * 2) {
            let radius = (i % 2 == 0) ? outerRadius : innerRadius
            let angle = (CGFloat(i) * .pi / CGFloat(points)) - (.pi / 2)
            let x = cx + radius * cos(angle)
            let y = cy + radius * sin(angle)
            if i == 0 {
                path.move(to: NSPoint(x: x, y: y))
            } else {
                path.line(to: NSPoint(x: x, y: y))
            }
        }
        path.close()
        return path
    }
}
