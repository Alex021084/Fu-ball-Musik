import Foundation
import AVFoundation

final class AudioManager: ObservableObject {
    @Published private(set) var isPlaying = false

    private var player: AVAudioPlayer?

    init() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try session.setActive(true)
        } catch {
            print("Audio session error: \(error.localizedDescription)")
        }
    }

    func play(fileName: String, fileExtension: String = "mp3") {
        stop()

        guard let url = Bundle.main.url(
            forResource: fileName,
            withExtension: fileExtension
        ) else {
            print("Audio file not found: \(fileName).\(fileExtension)")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
            isPlaying = true
        } catch {
            print("Could not play audio: \(error.localizedDescription)")
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
    }
}
