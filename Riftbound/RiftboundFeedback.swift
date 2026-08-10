import AudioToolbox
import UIKit

enum RiftboundFeedbackKind {
    case tap
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

    private init() {}

    func play(_ kind: RiftboundFeedbackKind, soundEnabled: Bool, vibrationEnabled: Bool) {
        if soundEnabled {
            AudioServicesPlaySystemSound(soundID(for: kind))
        }
        guard vibrationEnabled else { return }
        switch kind {
        case .victory:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .defeat:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .skill, .reward:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .enemy:
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        default:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func soundID(for kind: RiftboundFeedbackKind) -> SystemSoundID {
        switch kind {
        case .tap: return 1104
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
