import SwiftUI
import MusicKit
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var music: MusicController
    @StateObject private var store = SoundStore()
    @StateObject private var localAudio = AudioController()
    @State private var showFileImporter = false
    @State private var fileTarget: UUID?
    @State private var selectedSongBySlot: [UUID: Song] = [:]
    @State private var showPickerFor: UUID?

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, Color(red: 0.03, green: 0.14, blue: 0.07), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                header
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                        ForEach(store.slots) { slot in
                            SoundCard(
                                slot: binding(for: slot),
                                onAppleMusic: { showPickerFor = slot.id },
                                onLocalFile: {
                                    fileTarget = slot.id
                                    showFileImporter = true
                                },
                                onPlay: { play(slot) }
                            )
                            .musicPicker(
                                isPresented: Binding(
                                    get: { showPickerFor == slot.id },
                                    set: { if !$0 { showPickerFor = nil } }
                                ),
                                selection: Binding(
                                    get: { selectedSongBySlot[slot.id] },
                                    set: { song in
                                        selectedSongBySlot[slot.id] = song
                                        if let song {
                                            var copy = slot
                                            copy.songTitle = song.title
                                            copy.artist = song.artistName ?? ""
                                            copy.source = .appleMusic
                                            copy.appleMusicSongID = song.id.rawValue
                                            copy.localFileName = nil
                                            store.update(copy)
                                        }
                                    }
                                )
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }

                HStack(spacing: 12) {
                    Text(music.message)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                    Spacer()
                    Button("Apple Music freigeben") {
                        Task { await music.requestAccess() }
                    }
                    .buttonStyle(.borderedProminent)
                    Button("STOP") {
                        music.stop()
                        localAudio.stopAll()
                    }
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.red, in: Capsule())
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 8)
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            handleFile(result)
        }
        .task {
            await music.requestAccess()
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image("crest")
                .resizable()
                .scaledToFit()
                .frame(height: 78)
            VStack(alignment: .leading, spacing: 2) {
                Text("FC OSTEREISTEDT-RHADE")
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text("FUSSBALL • MUSIK • STADION")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.green)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
    }

    private func binding(for slot: SoundSlot) -> Binding<SoundSlot> {
        Binding(
            get: { store.slots.first(where: { $0.id == slot.id }) ?? slot },
            set: { store.update($0) }
        )
    }

    private func play(_ slot: SoundSlot) {
        music.stop()
        localAudio.stopAll()
        switch slot.source {
        case .appleMusic:
            if let id = slot.appleMusicSongID {
                Task { await music.play(songID: id, start: slot.start, end: slot.end) }
            }
        case .localFile:
            if let name = slot.localFileName {
                let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(name)
                localAudio.play(id: slot.id, url: url, start: slot.start, end: slot.end)
            }
        case .none:
            break
        }
    }

    private func handleFile(_ result: Result<[URL], Error>) {
        guard let target = fileTarget, let sourceURL = try? result.get().first else { return }
        let access = sourceURL.startAccessingSecurityScopedResource()
        defer { if access { sourceURL.stopAccessingSecurityScopedResource() } }

        do {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let safeName = "sound_\(target.uuidString)_\(sourceURL.lastPathComponent)"
            let destination = documents.appendingPathComponent(safeName)
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destination)

            if let slot = store.slots.first(where: { $0.id == target }) {
                var copy = slot
                copy.songTitle = sourceURL.deletingPathExtension().lastPathComponent
                copy.artist = "Eigene Audiodatei"
                copy.source = .localFile
                copy.localFileName = safeName
                copy.appleMusicSongID = nil
                store.update(copy)
            }
        } catch {
            print("Import fehlgeschlagen: \(error)")
        }
    }
}

struct SoundCard: View {
    @Binding var slot: SoundSlot
    let onAppleMusic: () -> Void
    let onLocalFile: () -> Void
    let onPlay: () -> Void

    private var buttonColor: Color {
        let colors: [Color] = [.green, .red, .orange, .blue, .purple, .pink]
        let index = abs(slot.category.hashValue) % colors.count
        return colors[index]
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onPlay) {
                VStack(spacing: 4) {
                    Text(slot.category)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.65)
                        .lineLimit(2)
                    Text(slot.songTitle)
                        .font(.caption.weight(.bold))
                        .lineLimit(1)
                        .opacity(slot.source == .none ? 0.6 : 1)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 72)
                .background(
                    LinearGradient(colors: [buttonColor.opacity(0.95), buttonColor.opacity(0.65)], startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.35), lineWidth: 1))
                .shadow(color: .black.opacity(0.35), radius: 5, y: 3)
            }
            .buttonStyle(.plain)

            VStack(spacing: 5) {
                HStack(spacing: 5) {
                    Button("Apple Music", action: onAppleMusic)
                    Button("Datei", action: onLocalFile)
                }
                .font(.caption2.weight(.bold))
                .buttonStyle(.bordered)
                .tint(.white)

                HStack(spacing: 6) {
                    Text("Start")
                    TextField("0", value: $slot.start, format: .number.precision(.fractionLength(0)))
                    Text("Ende")
                    TextField("15", value: $slot.end, format: .number.precision(.fractionLength(0)))
                }
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.9))
                .textFieldStyle(.roundedBorder)
            }
            .padding(7)
            .background(.black.opacity(0.7), in: RoundedRectangle(cornerRadius: 0))
        }
        .background(.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 16))
    }
}
