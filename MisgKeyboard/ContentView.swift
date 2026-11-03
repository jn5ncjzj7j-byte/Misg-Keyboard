import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var store = KeyboardStore.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var newClip = ""
    @State private var search = ""
    @State private var darkMode = true
    @State private var copiedID: UUID?

    private var filtered: [KeyboardClip] {
        store.clips.filter {
            search.isEmpty || $0.text.localizedCaseInsensitiveContains(search)
        }
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

                    ScrollView {
                        LazyVStack(spacing: 10) {
                            if filtered.isEmpty {
                                Text(search.isEmpty ? "No saved clips yet" : "No matching clips")
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 28)
                            }
                            ForEach(filtered) { clip in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(clip.text)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .textSelection(.enabled)
                                    HStack {
                                        Button {
                                            UIPasteboard.general.string = clip.text
                                            copiedID = clip.id
                                        } label: {
                                            Label(copiedID == clip.id ? "Copied" : "Copy",
                                                  systemImage: copiedID == clip.id ? "checkmark" : "doc.on.doc")
                                        }
                                        Spacer()
                                        Button {
                                            store.togglePin(clip)
                                            copiedID = nil
                                        } label: {
                                            Label(clip.pinned ? "Unpin" : "Pin",
                                                  systemImage: clip.pinned ? "pin.fill" : "pin")
                                        }
                                        Button(role: .destructive) {
                                            store.delete(clip)
                                            if copiedID == clip.id { copiedID = nil }
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                    }
                                    .font(.caption.weight(.medium))
                                    .buttonStyle(.borderless)
                                }
                                .padding(14)
                                .background(Color.white.opacity(darkMode ? 0.055 : 0.7),
                                            in: RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        .padding(.vertical, 2)
                    }

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
            .onChange(of: scenePhase) { phase in
                if phase == .active {
                    store.load()
                    copiedID = nil
                }
            }
        }
    }
}
