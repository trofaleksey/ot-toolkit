import Foundation
import UIKit
import XCTest
@testable import OTToolkit

final class SemanticColorTests: XCTestCase {
    private struct Appearance {
        let name: String
        let interfaceStyle: UIUserInterfaceStyle
        let contrast: UIAccessibilityContrast

        @MainActor
        var traits: UITraitCollection {
            UITraitCollection { traits in
                traits.userInterfaceStyle = interfaceStyle
                traits.accessibilityContrast = contrast
            }
        }
    }

    private let appearances = [
        Appearance(name: "light", interfaceStyle: .light, contrast: .normal),
        Appearance(name: "dark", interfaceStyle: .dark, contrast: .normal),
        Appearance(name: "light increased", interfaceStyle: .light, contrast: .high),
        Appearance(name: "dark increased", interfaceStyle: .dark, contrast: .high),
    ]

    func testEveryRoleDeclaresAllRequiredAssetAppearances() throws {
        let expectedSignatures: Set<String> = [
            "any",
            "luminosity=dark",
            "contrast=high",
            "contrast=high+luminosity=dark",
        ]
        let catalogURL = assetCatalogURL()

        for role in OTColorRole.allCases {
            let contentsURL =
                catalogURL
                .appendingPathComponent("\(role.rawValue).colorset")
                .appendingPathComponent("Contents.json")
            let data = try Data(contentsOf: contentsURL)
            let object = try JSONSerialization.jsonObject(with: data)
            let dictionary = try XCTUnwrap(object as? [String: Any])
            let colors = try XCTUnwrap(dictionary["colors"] as? [[String: Any]])
            let signatures = Set(colors.compactMap(appearanceSignature))

            XCTAssertEqual(colors.count, 4, role.rawValue)
            XCTAssertEqual(signatures, expectedSignatures, role.rawValue)
        }
    }

    @MainActor
    func testTextAndForegroundRolesMeetNormalTextContrastOnEverySurface() throws {
        let foregroundRoles: [OTColorRole] = [
            .primaryText,
            .secondaryText,
            .accent,
            .success,
            .warning,
            .destructive,
            .focus,
        ]
        let surfaceRoles: [OTColorRole] = [.background, .surface, .elevatedSurface]

        try assertContrast(
            foregroundRoles: foregroundRoles,
            backgroundRoles: surfaceRoles,
            minimumRatio: 4.5
        )
    }

    @MainActor
    func testSeparatorMeetsEssentialGraphicContrastOnEverySurface() throws {
        try assertContrast(
            foregroundRoles: [.separator],
            backgroundRoles: [.background, .surface, .elevatedSurface],
            minimumRatio: 3
        )
    }

    @MainActor
    func testSelectionSurfaceSupportsPrimaryTextInEveryAppearance() throws {
        try assertContrast(
            foregroundRoles: [.primaryText],
            backgroundRoles: [.selection],
            minimumRatio: 4.5
        )
    }

    private func assetCatalogURL() -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("OTToolkit/Resources/Assets.xcassets")
    }

    private func appearanceSignature(from color: [String: Any]) -> String? {
        guard let appearances = color["appearances"] else {
            return "any"
        }
        guard let entries = appearances as? [[String: Any]] else {
            return nil
        }

        let values = entries.compactMap { entry -> String? in
            guard
                let appearance = entry["appearance"] as? String,
                let value = entry["value"] as? String
            else {
                return nil
            }
            return "\(appearance)=\(value)"
        }
        guard values.count == entries.count else {
            return nil
        }
        return values.sorted().joined(separator: "+")
    }

    @MainActor
    private func assertContrast(
        foregroundRoles: [OTColorRole],
        backgroundRoles: [OTColorRole],
        minimumRatio: Double
    ) throws {
        for appearance in appearances {
            for foregroundRole in foregroundRoles {
                for backgroundRole in backgroundRoles {
                    let foreground = try resolvedColor(for: foregroundRole, appearance: appearance)
                    let background = try resolvedColor(for: backgroundRole, appearance: appearance)
                    let ratio = try contrastRatio(foreground: foreground, background: background)

                    XCTAssertGreaterThanOrEqual(
                        ratio,
                        minimumRatio,
                        "\(foregroundRole.rawValue) on \(backgroundRole.rawValue) in "
                            + "\(appearance.name) resolved to \(ratio):1"
                    )
                }
            }
        }
    }

    @MainActor
    private func resolvedColor(
        for role: OTColorRole,
        appearance: Appearance
    ) throws -> UIColor {
        let color = try XCTUnwrap(
            UIColor(named: role.rawValue, in: Bundle.main, compatibleWith: appearance.traits),
            "Missing color asset \(role.rawValue)"
        )
        return color.resolvedColor(with: appearance.traits)
    }

    @MainActor
    private func contrastRatio(foreground: UIColor, background: UIColor) throws -> Double {
        let foregroundLuminance = try relativeLuminance(of: foreground)
        let backgroundLuminance = try relativeLuminance(of: background)
        let lighter = max(foregroundLuminance, backgroundLuminance)
        let darker = min(foregroundLuminance, backgroundLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    @MainActor
    private func relativeLuminance(of color: UIColor) throws -> Double {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            throw ColorTestError.couldNotResolveSRGB
        }
        guard abs(alpha - 1) < 0.001 else {
            throw ColorTestError.semanticColorMustBeOpaque
        }

        return 0.2126 * linearized(Double(red))
            + 0.7152 * linearized(Double(green))
            + 0.0722 * linearized(Double(blue))
    }

    private func linearized(_ component: Double) -> Double {
        if component <= 0.04045 {
            return component / 12.92
        }
        return pow((component + 0.055) / 1.055, 2.4)
    }
}

private enum ColorTestError: Error {
    case couldNotResolveSRGB
    case semanticColorMustBeOpaque
}
