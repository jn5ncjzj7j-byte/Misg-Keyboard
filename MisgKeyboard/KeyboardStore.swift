import Foundation
import Combine

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
        guard let data = defaults.data(forKey: key) else {
            clips = []
            return
        }
        do {
            let decoded = try JSONDecoder().decode([KeyboardClip].self, from: data)
            clips = ordered(decoded)
        } catch {
            return
        }
    }

    func add(_ text: String) {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        var updated = clips
        updated.insert(KeyboardClip(text: value), at: 0)
        persist(updated)
    }

    func togglePin(_ clip: KeyboardClip) {
        guard var current = clips.first(where: { $0.id == clip.id }) else { return }
        current.pinned.toggle()
        var updated = clips
        guard let index = updated.firstIndex(where: { $0.id == clip.id }) else { return }
        updated[index] = current
        persist(updated)
    }

    func delete(_ clip: KeyboardClip) {
        persist(clips.filter { $0.id != clip.id })
    }

    private func ordered(_ values: [KeyboardClip]) -> [KeyboardClip] {
        values.sorted {
            if $0.pinned != $1.pinned { return $0.pinned && !$1.pinned }
            return $0.createdAt > $1.createdAt
        }
    }

    private func persist(_ values: [KeyboardClip]) {
        let sorted = ordered(values)
        guard let data = try? JSONEncoder().encode(sorted) else { return }
        defaults.set(data, forKey: key)
        defaults.synchronize()
        clips = sorted
    }
}
