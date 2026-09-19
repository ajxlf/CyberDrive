import AVFoundation
import CarPlay
import MapKit
import UIKit

@MainActor
final class NavigationGuidance {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {
        guard !text.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        synthesizer.speak(utterance)
    }

    func maneuvers(for route: MKRoute) -> [CPManeuver] {
        route.steps
            .filter { !$0.instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { step in
                let maneuver = CPManeuver()
                let instruction = step.instructions
                maneuver.instructionVariants = [instruction, instruction]
                maneuver.dashboardInstructionVariants = [instruction]
                maneuver.notificationInstructionVariants = [instruction]
                maneuver.maneuverType = Self.maneuverType(for: instruction)
                if !step.distance.isZero {
                    maneuver.initialTravelEstimates = CPTravelEstimates(
                        distanceRemaining: Measurement(value: step.distance, unit: .meters),
                        timeRemaining: step.distance / 13.4
                    )
                }
                return maneuver
            }
    }

    private static func maneuverType(for instruction: String) -> CPManeuverType {
        let lower = instruction.lowercased()
        if lower.contains("arrive") || lower.contains("destination") { return .arriveAtDestination }
        if lower.contains("u-turn") || lower.contains("uturn") { return .uTurn }
        if lower.contains("roundabout") { return .enterRoundabout }
        if lower.contains("keep left") { return .keepLeft }
        if lower.contains("keep right") { return .keepRight }
        if lower.contains("left") { return .leftTurn }
        if lower.contains("right") { return .rightTurn }
        if lower.contains("merge") { return .changeHighway }
        if lower.contains("straight") || lower.contains("continue") { return .straightAhead }
        return .followRoad
    }
}
