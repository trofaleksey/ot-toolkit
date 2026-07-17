import AVFoundation
import Foundation
import UIKit

protocol VisualTimerIdleTimerControlling: AnyObject, Sendable {
    var isIdleTimerDisabled: Bool { get set }
}

@MainActor
protocol VisualTimerCompletionFeedbackDelivering: AnyObject {
    func deliverCompletion(soundEnabled: Bool, hapticEnabled: Bool)
}

final class SystemIdleTimerController: VisualTimerIdleTimerControlling, @unchecked Sendable {
    var isIdleTimerDisabled: Bool {
        get {
            MainActor.assumeIsolated {
                UIApplication.shared.isIdleTimerDisabled
            }
        }
        set {
            MainActor.assumeIsolated {
                UIApplication.shared.isIdleTimerDisabled = newValue
            }
        }
    }
}

@MainActor
final class SystemVisualTimerCompletionFeedback: VisualTimerCompletionFeedbackDelivering {
    private let tonePlayer = VisualTimerCompletionTonePlayer()

    func deliverCompletion(soundEnabled: Bool, hapticEnabled: Bool) {
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(
                notification: .announcement,
                argument: String(localized: "visualTimer.accessibility.completionAnnouncement")
            )
        }

        if soundEnabled {
            tonePlayer.play()
        }

        if hapticEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        }
    }
}

@MainActor
final class VisualTimerRuntimeCoordinator {
    private let idleTimer: any VisualTimerIdleTimerControlling
    private let completionFeedback: any VisualTimerCompletionFeedbackDelivering

    private var idleTimerValueBeforeOwnership: Bool?
    private var lastDeliveredCompletionSequence = 0

    init(
        idleTimer: any VisualTimerIdleTimerControlling = SystemIdleTimerController(),
        completionFeedback: any VisualTimerCompletionFeedbackDelivering =
            SystemVisualTimerCompletionFeedback()
    ) {
        self.idleTimer = idleTimer
        self.completionFeedback = completionFeedback
    }

    func synchronize(
        controller: VisualTimerController,
        isSceneActive: Bool,
        isTimerPresented: Bool
    ) {
        updateIdleTimerOwnership(
            shouldDisable: controller.isRunning && isSceneActive && isTimerPresented
        )

        guard
            isSceneActive,
            controller.completionSequence > lastDeliveredCompletionSequence
        else {
            return
        }

        lastDeliveredCompletionSequence = controller.completionSequence
        completionFeedback.deliverCompletion(
            soundEnabled: controller.isCompletionSoundEnabled,
            hapticEnabled: controller.isCompletionHapticEnabled
        )
    }

    func stop() {
        restoreIdleTimerIfNeeded()
    }

    deinit {
        if let idleTimerValueBeforeOwnership {
            idleTimer.isIdleTimerDisabled = idleTimerValueBeforeOwnership
        }
    }

    private func updateIdleTimerOwnership(shouldDisable: Bool) {
        if shouldDisable {
            guard idleTimerValueBeforeOwnership == nil else { return }
            idleTimerValueBeforeOwnership = idleTimer.isIdleTimerDisabled
            idleTimer.isIdleTimerDisabled = true
        } else {
            restoreIdleTimerIfNeeded()
        }
    }

    private func restoreIdleTimerIfNeeded() {
        guard let idleTimerValueBeforeOwnership else { return }
        idleTimer.isIdleTimerDisabled = idleTimerValueBeforeOwnership
        self.idleTimerValueBeforeOwnership = nil
    }
}

@MainActor
private final class VisualTimerCompletionTonePlayer {
    private var audioPlayer: AVAudioPlayer?

    func play() {
        do {
            let player = try AVAudioPlayer(data: Self.toneData)
            player.volume = 0.35
            player.prepareToPlay()
            player.play()
            audioPlayer = player
        } catch {
            audioPlayer = nil
        }
    }

    private static let toneData = makeToneData()

    private static func makeToneData() -> Data {
        let sampleRate = 44_100
        let duration = 0.22
        let sampleCount = Int(Double(sampleRate) * duration)
        var samples = Data(capacity: sampleCount * MemoryLayout<Int16>.size)

        for index in 0..<sampleCount {
            let time = Double(index) / Double(sampleRate)
            let release = max(0, (duration - time) / 0.05)
            let envelope = min(1, time / 0.02, release)
            let amplitude = sin(2 * Double.pi * 659.25 * time) * envelope * 0.18
            var sample = Int16(amplitude * Double(Int16.max)).littleEndian
            withUnsafeBytes(of: &sample) { bytes in
                samples.append(contentsOf: bytes)
            }
        }

        var wave = Data()
        wave.appendASCII("RIFF")
        wave.appendLittleEndian(UInt32(36 + samples.count))
        wave.appendASCII("WAVEfmt ")
        wave.appendLittleEndian(UInt32(16))
        wave.appendLittleEndian(UInt16(1))
        wave.appendLittleEndian(UInt16(1))
        wave.appendLittleEndian(UInt32(sampleRate))
        wave.appendLittleEndian(UInt32(sampleRate * MemoryLayout<Int16>.size))
        wave.appendLittleEndian(UInt16(MemoryLayout<Int16>.size))
        wave.appendLittleEndian(UInt16(16))
        wave.appendASCII("data")
        wave.appendLittleEndian(UInt32(samples.count))
        wave.append(samples)
        return wave
    }
}

private extension Data {
    mutating func appendASCII(_ value: String) {
        append(contentsOf: value.utf8)
    }

    mutating func appendLittleEndian<T: FixedWidthInteger>(_ value: T) {
        var littleEndianValue = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndianValue) { bytes in
            append(contentsOf: bytes)
        }
    }
}
