import SwiftUI
import ServiceManagement
import UniformTypeIdentifiers

struct PreferencesView: View {
    @ObservedObject var favoritesManager = FavoritesManager.shared
    @State private var selection: Set<String> = []
    @State private var startAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Favorites")
                .font(.headline)

            VStack(spacing: 0) {
                List(selection: $selection) {
                    ForEach(favoritesManager.favorites, id: \.self) { path in
                        HStack(spacing: 8) {
                            Image(systemName: isDirectory(path) ? "folder.fill" : "doc.fill")
                                .foregroundColor(.secondary)
                                .frame(width: 16)
                            Text(path)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                    .onMove { source, destination in
                        favoritesManager.move(fromOffsets: source, toOffset: destination)
                    }
                    .onDelete { offsets in
                        for index in offsets.sorted().reversed() {
                            let path = favoritesManager.favorites[index]
                            favoritesManager.remove(path)
                        }
                    }
                }
                .listStyle(.bordered(alternatesRowBackgrounds: true))
                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                    for provider in providers {
                        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, _ in
                            guard let data = data as? Data,
                                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                            DispatchQueue.main.async {
                                favoritesManager.add(url.path)
                            }
                        }
                    }
                    return true
                }
                .frame(height: 200)

                HStack(spacing: 4) {
                    Button(action: addItems) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderless)

                    Button(action: removeSelected) {
                        Image(systemName: "minus")
                    }
                    .buttonStyle(.borderless)
                    .disabled(selection.isEmpty)

                    Spacer()

                    Button("Remove All") {
                        removeAllFavorites()
                    }
                    .buttonStyle(.borderless)
                    .disabled(favoritesManager.favorites.isEmpty)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }

            Divider()

            Toggle("Start at Login", isOn: $startAtLogin)
                .onChange(of: startAtLogin) { _, newValue in
                    toggleLoginItem(enabled: newValue)
                }
        }
        .padding(16)
        .frame(width: 500)
    }

    private func addItems() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.message = "Select files or folders to add to Quick Access"
        panel.prompt = "Add"

        if panel.runModal() == .OK {
            for url in panel.urls {
                favoritesManager.add(url.path)
            }
        }
    }

    private func removeSelected() {
        for path in selection {
            favoritesManager.remove(path)
        }
        selection.removeAll()
    }

    private func removeAllFavorites() {
        let alert = NSAlert()
        alert.messageText = "Remove all favorites?"
        alert.informativeText = "This cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Remove All")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            favoritesManager.removeAll()
            selection.removeAll()
        }
    }

    private func toggleLoginItem(enabled: Bool) {
        let service = SMAppService.mainApp
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            startAtLogin = service.status == .enabled
        }
    }

    private func isDirectory(_ path: String) -> Bool {
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
    }
}
