import AVFoundation
import AudioToolbox
import UIKit

enum RiftboundFeedbackKind: String {
    case tap
    case ward
    case attack
    case skill
    case enemy
    case heal
    case reward
    case victory
    case defeat
}

@MainActor
final class RiftboundFeedback {
    static let shared = RiftboundFeedback()

    private var players: [String: AVAudioPlayer] = [:]
    private var audioConfigured = false

    private init() {}

    func play(_ kind: RiftboundFeedbackKind, soundEnabled: Bool, vibrationEnabled: Bool) {
        if soundEnabled {
            playCustom(kind)
        }
        guard vibrationEnabled else { return }
        switch kind {
        case .victory:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .defeat:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .skill, .reward, .ward:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .enemy:
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        default:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func playCustom(_ kind: RiftboundFeedbackKind) {
        guard let name = resourceName(for: kind), let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            AudioServicesPlaySystemSound(soundID(for: kind))
            return
        }
        if !audioConfigured {
            try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try? AVAudioSession.sharedInstance().setActive(true)
            audioConfigured = true
        }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0.9
            player.prepareToPlay()
            players[kind.rawValue] = player
            player.play()
        } catch {
            AudioServicesPlaySystemSound(soundID(for: kind))
        }
    }

    private func resourceName(for kind: RiftboundFeedbackKind) -> String? {
        switch kind {
        case .tap: return "rift-click"
        case .ward: return "rift-guard"
        case .attack: return "rift-attack"
        case .skill: return "rift-skill"
        case .enemy: return "rift-enemy"
        case .heal: return "rift-heal"
        case .reward: return "rift-reward"
        case .victory: return "rift-victory"
        case .defeat: return "rift-defeat"
        }
    }

    private func soundID(for kind: RiftboundFeedbackKind) -> SystemSoundID {
        switch kind {
        case .tap: return 1104
        case .ward: return 1104
        case .attack: return 1103
        case .skill: return 1057
        case .enemy: return 1055
        case .heal: return 1025
        case .reward: return 1026
        case .victory: return 1027
        case .defeat: return 1006
        }
    }
}
