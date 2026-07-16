import SwiftUI

enum OTColorRole: String, CaseIterable, Sendable {
    case background = "OTBackground"
    case surface = "OTSurface"
    case elevatedSurface = "OTElevatedSurface"
    case primaryText = "OTPrimaryText"
    case secondaryText = "OTSecondaryText"
    case accent = "OTAccent"
    case selection = "OTSelection"
    case success = "OTSuccess"
    case warning = "OTWarning"
    case destructive = "OTDestructive"
    case separator = "OTSeparator"
    case focus = "OTFocus"

    var color: Color {
        Color(rawValue)
    }
}

enum OTColor {
    static var background: Color { OTColorRole.background.color }
    static var surface: Color { OTColorRole.surface.color }
    static var elevatedSurface: Color { OTColorRole.elevatedSurface.color }
    static var primaryText: Color { OTColorRole.primaryText.color }
    static var secondaryText: Color { OTColorRole.secondaryText.color }
    static var accent: Color { OTColorRole.accent.color }
    static var selection: Color { OTColorRole.selection.color }
    static var success: Color { OTColorRole.success.color }
    static var warning: Color { OTColorRole.warning.color }
    static var destructive: Color { OTColorRole.destructive.color }
    static var separator: Color { OTColorRole.separator.color }
    static var focus: Color { OTColorRole.focus.color }
}
