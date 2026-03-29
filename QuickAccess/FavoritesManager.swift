import Foundation

class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    static let didChangeNotification = Notification.Name("FavoritesDidChange")

    private let key = "favorites"

    @Published var favorites: [String] = []

    init() {
        favorites = UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    func add(_ path: String) {
        guard !favorites.contains(path) else { return }
        favorites.append(path)
        save()
    }

    func remove(_ path: String) {
        favorites.removeAll { $0 == path }
        save()
    }

    func removeAll() {
        favorites.removeAll()
        save()
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        favorites.move(fromOffsets: source, toOffset: destination)
        save()
    }

    private func save() {
        UserDefaults.standard.set(favorites, forKey: key)
        NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
    }
}
