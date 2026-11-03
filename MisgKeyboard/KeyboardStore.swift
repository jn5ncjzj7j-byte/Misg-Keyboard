import Foundation

struct KeyboardClip: Identifiable, Codable, Equatable {
    var id: UUID
    var text: String
    var createdAt: Date
    var pinned: Bool

    init(text: String, pinned: Bool = false) {
        self.id = UUID()
        self.text = text
        self.createdAt = Date()
        self.pinned = pinned
    }
}

final class KeyboardStore: ObservableObject {
    static let shared = KeyboardStore()
    static let groupID = "group.app.misg.keyboard"
    private let key = "savedClips"
    private let defaults = UserDefaults(suiteName: groupID) ?? .standard

    @Published private(set) var clips: [KeyboardClip] = []

    private init() {
        load()
    }

    func load() {
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode([KeyboardClip].self, from: data) else {
            clips = []
            return
        }
        clips = decoded.sorted { $0.pinned == $1.pinned ? $0.createdAt > $1.createdAt : $0.pinned && !$1.pinned }
    }

    func add(_ text: String) {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        clips.insert(KeyboardClip(text: value), at: 0)
        save()
    }

    func togglePin(_ clip: KeyboardClip) {
        guard let index = clips.firstIndex(where: { $0.id == clip.id }) else { return }
        clips[index].pinned.toggle()
        save()
    }

    func delete(_ clip: KeyboardClip) {
        clips.removeAll { $0.id == clip.id }
        save()
    }

    private func save() {
        clips.sort { $0.pinned == $1.pinned ? $0.createdAt > $1.createdAt : $0.pinned && !$1.pinned }
        if let data = try? JSONEncoder().encode(clips) {
            defaults.set(data, forKey: key)
        }
        objectWillChange.send()
    }
}
