import SwiftUI
import AppKit

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
            if let img = NSImage(systemSymbolName: "folder.badge.star", accessibilityDescription: "Quick Access") {
                img.isTemplate = true
                button.image = img
            } else {
                button.title = "QA"
            }
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
            let removeItem = NSMenuItem(title: "Remove…", action: nil, keyEquivalent: "")
            removeItem.submenu = removeSubmenu
            menu.addItem(removeItem)
        }

        menu.addItem(NSMenuItem.separator())

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

    @objc func quit() {
        NSApp.terminate(nil)
    }

    private func isDirectory(atPath path: String) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }
}
