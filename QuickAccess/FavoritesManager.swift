import Foundation

class FavoritesManager {
    static let shared = FavoritesManager()
    static let didChangeNotification = Notification.Name("FavoritesDidChange")

    private let key = "favorites"

    var favorites: [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }

    func add(_ path: String) {
        var current = favorites
        guard !current.contains(path) else { return }
        current.append(path)
        save(current)
    }

    func remove(_ path: String) {
        var current = favorites
        current.removeAll { $0 == path }
        save(current)
    }

    func removeAll() {
        save([])
    }

    private func save(_ items: [String]) {
        UserDefaults.standard.set(items, forKey: key)
        NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
    }
}
