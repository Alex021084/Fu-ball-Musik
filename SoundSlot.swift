import Foundation

struct SoundSlot: Identifiable, Codable, Equatable {
    enum Source: String, Codable {
        case none
        case appleMusic
        case localFile
    }

    let id: UUID
    var category: String
    var songTitle: String = "Noch kein Lied"
    var artist: String = ""
    var source: Source = .none
    var appleMusicSongID: String?
    var localFileName: String?
    var start: Double = 0
    var end: Double = 15

    init(id: UUID = UUID(), category: String) {
        self.id = id
        self.category = category
    }
}

@MainActor
final class SoundStore: ObservableObject {
    @Published var slots: [SoundSlot] = [] {
        didSet { save() }
    }

    private let key = "fc_sound_slots_v2"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([SoundSlot].self, from: data),
           decoded.count == 12 {
            slots = decoded
        } else {
            let names = [
                "TOR", "TORHYMNE", "FANGESANG", "HYPE",
                "SIEG", "AUF GEHT'S", "NUR DER VEREIN", "WIR SIND EIN TEAM",
                "GEMEINSAM STARK", "KÄMPFEN UND SIEGEN", "FUSSBALL LEIDENSCHAFT", "IMMER WEITER"
            ]
            slots = names.map { SoundSlot(category: $0) }
        }
    }

    func update(_ slot: SoundSlot) {
        guard let index = slots.firstIndex(where: { $0.id == slot.id }) else { return }
        slots[index] = slot
    }

    private func save() {
        if let data = try? JSONEncoder().encode(slots) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
