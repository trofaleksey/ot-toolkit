import Foundation
@preconcurrency import SwiftData

/// Third versioned schema. It keeps the immutable First–Then V1 and Token V2
/// models and adds the Choice Board introduced by OTK-050. Existing models are
/// unchanged, so V2→V3 is a lightweight migration.
///
/// Only the board and its options are persisted. Temporary hiding and the
/// current selection are session state and deliberately have no stored
/// counterpart: a therapist hiding an unavailable choice for one session must
/// not edit the saved board.
enum OTToolkitSchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            FirstThenBoard.self,
            FirstThenItem.self,
            TokenBoardTemplate.self,
            ChoiceBoard.self,
            ChoiceOption.self,
        ]
    }

    @Model
    final class ChoiceBoard {
        @Attribute(.unique) var id: UUID
        var name: String
        var sortIndex: Int
        var createdAt: Date
        var updatedAt: Date

        @Relationship(deleteRule: .cascade, inverse: \ChoiceOption.board)
        var options: [ChoiceOption] = []

        init(
            id: UUID,
            name: String,
            sortIndex: Int,
            createdAt: Date,
            updatedAt: Date,
            options: [ChoiceOption] = []
        ) {
            self.id = id
            self.name = name
            self.sortIndex = sortIndex
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.options = options

            for option in options {
                option.board = self
            }
        }
    }

    @Model
    final class ChoiceOption {
        @Attribute(.unique) var id: UUID
        var label: String
        var systemSymbolName: String
        var sortIndex: Int
        var createdAt: Date
        var updatedAt: Date
        var board: ChoiceBoard?

        init(
            id: UUID,
            label: String,
            systemSymbolName: String,
            sortIndex: Int,
            createdAt: Date,
            updatedAt: Date,
            board: ChoiceBoard? = nil
        ) {
            self.id = id
            self.label = label
            self.systemSymbolName = systemSymbolName
            self.sortIndex = sortIndex
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.board = board
        }
    }
}

typealias ChoiceBoard = OTToolkitSchemaV3.ChoiceBoard
typealias ChoiceOption = OTToolkitSchemaV3.ChoiceOption
