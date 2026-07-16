# Design system

## Purpose

OT Toolkit should feel calm, professional, predictable, and age-respectful for children approximately 4–13 while remaining fast for therapists to configure. Accessibility settings are treated as inputs to the system, not exceptions.

## Spacing

Use a four-point grid:

    enum OTSpacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

- xs: icon/label gaps and badge padding.
- sm: compact control padding and small internal gaps.
- md: standard control and card padding.
- lg: space between sections.
- xl: screen margins and child-facing presentation margins.

One-off values are acceptable only for platform metrics or a documented component need. Repeated layout constants become tokens.

## Shape

    enum OTRadius {
        static let control: CGFloat = 12
        static let card: CGFloat = 16
    }

Inner containers use a visually compatible radius relative to parent padding. Shadows are subtle, are not required to understand hierarchy, and are removed when Increase Contrast makes borders clearer.

## Typography

Typography tokens map to semantic SwiftUI Font.TextStyle values rather than fixed point sizes:

- Metadata: caption.
- Control label: callout or body.
- Body: body.
- Section heading: headline or title3.
- Screen title: title2 or title.
- Child-facing timer/value: an appropriate semantic large-title style with layout-specific scaling.

Text supports Dynamic Type through the largest accessibility categories. Required controls and meaning may reflow, wrap, or scroll; they may not clip or disappear. ScaledMetric is used only for non-text geometry that must track text size.

An optional alternate typeface must not imply a clinical or dyslexia-treatment benefit.

## Semantic color roles

Asset-catalog colors provide light, dark, and increased-contrast variants for:

- background
- surface
- elevatedSurface
- primaryText
- secondaryText
- accent
- selection
- success
- warning
- destructive
- separator
- focus

Text and meaningful graphics meet WCAG AA contrast: 4.5:1 for normal text and 3:1 for large text or essential non-text controls. Contrast is verified with tooling and on device. System Increase Contrast and Differentiate Without Color are honored; the custom Calm theme does not override accessibility settings.

No state is conveyed by color alone. Selected, completed, paused, disabled, warning, and error states also use text, icons, shape, or layout.

## Containers and controls

Card containers use surface, OTRadius.card, OTSpacing.md, and a border or subtle elevation. Child-facing presentation uses generous margins and removes nonessential chrome.

Primary and secondary actions:

- Have clear text or an unambiguous accessible label.
- Maintain at least a 44 by 44 point activation area.
- Preserve spacing at large text sizes.
- Expose disabled reasons when the reason is not otherwise evident.

Standard SwiftUI controls are preferred. Dragging is never the only way to reorder or act; provide Move Up/Down actions and accessible alternatives.

## Child-facing mode and adult controls

- Child-facing mode minimizes distraction without trapping the user.
- A visible, labeled adult-exit control is available.
- Accidental exit can be reduced with a hold or confirmation, but VoiceOver, Switch Control, and keyboard users receive an equivalent action.
- Instructions may recommend Guided Access, but app behavior does not depend on it.
- Therapist configuration controls remain visually distinct from child interaction targets.

## Motion and feedback

- Reduce Motion disables or replaces nonessential movement.
- Transitions are short, predictable fades or simple moves.
- No flashing, strobing, rapid color cycling, or repeated bouncing.
- Completion feedback combines at least two available forms among text/shape, optional sound, and optional haptics.
- Sound and haptics are optional.
- When VoiceOver is active, the timer exposes an on-demand remaining-time value and announces completion once; it never announces every display tick.

Visual Timer progress is smooth and linear, but elapsed time comes from domain state rather than animation frames. With Reduce Motion, continuous depletion may be replaced by a static progress shape plus the updating numerical value.

Token celebration is calm, brief, off by default, and still communicates completion when Reduce Motion is on.

## Images and assets

These budgets are the single source of truth for built-in and future imported images:

- Large board or card illustration: maximum 1200 px on the longest displayed dimension.
- Board item image: maximum 800 px on the longest displayed dimension.
- Thumbnail or token image: maximum 300 px on the longest displayed dimension.
- Built-in compressed assets should normally remain below 150 KB.

Decoded memory, not only compressed file size, is considered. Images are downsampled to their display need, decoded away from the main thread where practical, cached with a bounded policy, and tested in grids on the lowest supported device class.

Future imported media follows PRIVACY.md and ADR-0003: re-encoding, metadata removal, protected app-owned storage, cleanup, and backup policy are release requirements.

All custom illustrations, icons, sounds, and fonts require documented source and license provenance. OT Toolkit uses an original timer visual language and does not reproduce another product's distinctive assets or trade dress.

Informative illustrations and symbols have localized accessibility labels derived from their meaning, never from asset filenames. Decorative images and redundant symbols are hidden from assistive technologies. Board image/label combinations are tested so VoiceOver neither omits meaning nor repeats the same label.

## Accessibility release matrix

Each critical flow is manually checked for:

| Setting or context | Required result |
| --- | --- |
| VoiceOver | Logical focus order, useful labels/values/actions, no per-second announcement spam |
| Largest accessibility text | Required meaning/actions remain visible through reflow, wrap, or scroll |
| Reduce Motion | No essential information is lost |
| Increase Contrast | Text, focus, boundaries, and state remain distinguishable |
| Differentiate Without Color | State has a non-color indicator |
| Reduce Transparency | Surfaces remain legible |
| Switch Control and keyboard | Primary actions and adult exit remain operable |
| Small iPhone | No blocked primary flow |
| Full and compact iPad | Navigation adapts without losing active state |

Automated accessibility audits are added where supported, but manual assistive-technology checks remain part of the release gate.

## Empty, error, and destructive states

- Empty states briefly explain what belongs in the view and provide a primary next action.
- Errors name the failed action and a safe recovery path.
- Destructive actions state what will be removed.
- Reset app data requires confirmation and reports completion or failure.
- Persistence recovery never silently destroys user content.

## Review rule

New components reference these tokens and patterns in their ticket. A new token or pattern is added here only when it has a clear semantic purpose or more than one proven consumer.
