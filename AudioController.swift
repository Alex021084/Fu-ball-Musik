import Foundation
import AVFoundation

@MainActor
final class AudioController: NSObject, ObservableObject, AVAudioPlayerDelegate {
    private var players: [UUID: AVAudioPlayer] = [:]

    func play(id: UUID, url: URL, start: TimeInterval, end: TimeInterval) {
        stopAll()
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.currentTime = max(0, start)
            player.delegate = self
            player.play()
            players[id] = player

            if end > start {
                let duration = end - start
                Task { [weak self] in
                    try? await Task.sleep(for: .seconds(duration))
                    self?.stop(id: id)
                }
            }
        } catch {
            print("Lokale Audio-Datei konnte nicht abgespielt werden: \(error)")
        }
    }

    func stop(id: UUID) {
        players[id]?.stop()
        players.removeValue(forKey: id)
    }

    func stopAll() {
        players.values.forEach { $0.stop() }
        players.removeAll()
    }
}
