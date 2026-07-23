import Foundation

/// Every preference the app owns. `OTAppStorageKeys.all` is derived from this
/// list, so a new preference cannot be added without reset also clearing it.
enum OTPreference: String, CaseIterable, Sendable {
    case visualTimerCompletionSound = "preference.visualTimer.completionSound"
    case visualTimerCompletionHaptic = "preference.visualTimer.completionHaptic"
    case tokenBoardCompletionHaptic = "preference.tokenBoard.completionHaptic"

    /// Sensory feedback stays off until a therapist opts in.
    var defaultValue: Bool {
        false
    }
}

/// Reads and writes the app-owned preferences. Injectable so tests can use an
/// isolated `UserDefaults` suite instead of the shared domain.
@MainActor
final class OTPreferences {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func isEnabled(_ preference: OTPreference) -> Bool {
        guard defaults.object(forKey: preference.rawValue) != nil else {
            return preference.defaultValue
        }
        return defaults.bool(forKey: preference.rawValue)
    }

    func setEnabled(_ isEnabled: Bool, for preference: OTPreference) {
        defaults.set(isEnabled, forKey: preference.rawValue)
    }
}
