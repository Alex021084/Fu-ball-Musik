import SwiftUI

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()

    private let buttons: [SoundButton] = [
        .init(title: "TOR", icon: "soccerball", fileName: "tor", prominent: true),
        .init(title: "TORHYMNE", icon: "trophy.fill", fileName: "torhymne"),
        .init(title: "FANGESANG", icon: "megaphone.fill", fileName: "fangesang"),
        .init(title: "HYPE", icon: "flame.fill", fileName: "hype"),
        .init(title: "SIEG", icon: "flag.fill", fileName: "sieg")
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FUßBALL MUSIK")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text(audioManager.isPlaying ? "Wiedergabe läuft" : "Bereit für das nächste Tor")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.65))
                    }

                    Spacer()

                    Button {
                        audioManager.stop()
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 24, weight: .bold))
                            .frame(width: 64, height: 64)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                }

                GeometryReader { proxy in
                    let columns = proxy.size.width > 900 ? 3 : 2

                    LazyVGrid(
                        columns: Array(
                            repeating: GridItem(.flexible(), spacing: 16),
                            count: columns
                        ),
                        spacing: 16
                    ) {
                        ForEach(buttons) { button in
                            Button {
                                audioManager.play(fileName: button.fileName)
                            } label: {
                                VStack(spacing: 12) {
                                    Image(systemName: button.icon)
                                        .font(.system(
                                            size: button.prominent ? 54 : 38,
                                            weight: .bold
                                        ))

                                    Text(button.title)
                                        .font(.system(
                                            size: button.prominent ? 30 : 22,
                                            weight: .black,
                                            design: .rounded
                                        ))
                                }
                                .frame(
                                    maxWidth: .infinity,
                                    minHeight: button.prominent ? 210 : 160
                                )
                                .foregroundStyle(.white)
                                .background(
                                    RoundedRectangle(cornerRadius: 28)
                                        .fill(
                                            button.prominent
                                            ? Color.green
                                            : Color.white.opacity(0.12)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(24)
        }
        .preferredColorScheme(.dark)
    }
}

private struct SoundButton: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let fileName: String
    let prominent: Bool

    init(
        title: String,
        icon: String,
        fileName: String,
        prominent: Bool = false
    ) {
        self.title = title
        self.icon = icon
        self.fileName = fileName
        self.prominent = prominent
    }
}

#Preview {
    ContentView()
}
