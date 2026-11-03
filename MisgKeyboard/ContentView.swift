import SwiftUI

struct ContentView: View {
    @StateObject private var store = KeyboardStore.shared
    @State private var newClip = ""
    @State private var search = ""
    @State private var darkMode = true

    private var filtered: [KeyboardClip] {
        let values = store.clips.filter {
            search.isEmpty || $0.text.localizedCaseInsensitiveContains(search)
        }
        return values.sorted { $0.pinned == $1.pinned ? $0.createdAt > $1.createdAt : $0.pinned && !$1.pinned }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                (darkMode ? Color(red: 0.035, green: 0.045, blue: 0.07) : Color(uiColor: .systemGroupedBackground))
                    .ignoresSafeArea()
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your clipboard").font(.title2.bold())
                        Text("Save phrases here and use them from your keyboard.")
                            .font(.subheadline).foregroundStyle(.secondary)
                        HStack {
                            TextField("Type something to save…", text: $newClip, axis: .vertical)
                                .textFieldStyle(.plain)
                                .lineLimit(1...4)
                            Button {
                                store.add(newClip)
                                newClip = ""
                            } label: {
                                Image(systemName: "plus")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(width: 42, height: 42)
                                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 13))
                            }
                            .disabled(newClip.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .padding(12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                    }
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                        TextField("Search saved clips", text: $search)
                    }
                    .padding(12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    List {
                        ForEach(filtered) { clip in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(clip.text).textSelection(.enabled)
                                HStack {
                                    Button {
                                        UIPasteboard.general.string = clip.text
                                    } label: {
                                        Label("Copy", systemImage: "doc.on.doc")
                                    }
                                    Spacer()
                                    Button {
                                        store.togglePin(clip)
                                    } label: {
                                        Image(systemName: clip.pinned ? "pin.fill" : "pin")
                                    }
                                    Button(role: .destructive) {
                                        store.delete(clip)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                                .font(.caption)
                            }
                            .listRowBackground(Color.white.opacity(darkMode ? 0.055 : 0.7))
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Enable your keyboard", systemImage: "keyboard")
                            .font(.headline)
                        Text("Open Settings → General → Keyboard → Keyboards → Add New Keyboard, then choose Misg Keyboard. Allow Full Access to share saved clips.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .preferredColorScheme(darkMode ? .dark : .light)
            .navigationTitle("Misg Keyboard")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        darkMode.toggle()
                    } label: {
                        Image(systemName: darkMode ? "sun.max" : "moon")
                    }
                }
            }
        }
    }
}
