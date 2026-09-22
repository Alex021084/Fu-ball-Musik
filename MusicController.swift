import Foundation
import MusicKit

@MainActor
final class MusicController: ObservableObject {
    @Published var authorization: MusicAuthorization.Status = .notDetermined
    @Published var message = "Bereit"

    let player = ApplicationMusicPlayer.shared

    func requestAccess() async {
        authorization = await MusicAuthorization.request()
        switch authorization {
        case .authorized:
            message = "Apple Music ist freigegeben"
        case .denied:
            message = "Apple Music-Zugriff wurde abgelehnt"
        case .restricted:
            message = "Apple Music ist auf diesem Gerät eingeschränkt"
        case .notDetermined:
            message = "Apple Music-Zugriff noch nicht erteilt"
        @unknown default:
            message = "Unbekannter Berechtigungsstatus"
        }
    }

    func play(songID: String, start: TimeInterval, end: TimeInterval) async {
        guard authorization == .authorized else {
            await requestAccess()
            guard authorization == .authorized else { return }
        }

        do {
            let id = MusicItemID(rawValue: songID)
            var request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: id)
            request.limit = 1
            let response = try await request.response()
            guard let song = response.items.first else {
                message = "Song wurde nicht gefunden"
                return
            }

            player.queue = [song]
            try await player.prepareToPlay()
            player.playbackTime = max(0, start)
            try await player.play()
            message = "▶ \(song.title)"

            if end > start {
                let duration = end - start
                Task { [weak self] in
                    try? await Task.sleep(for: .seconds(duration))
                    guard let self else { return }
                    self.player.stop()
                    self.message = "Clip beendet"
                }
            }
        } catch {
            message = "Apple Music Fehler: \(error.localizedDescription)"
        }
    }

    func stop() {
        player.stop()
        message = "⏹ Stopp"
    }
}
