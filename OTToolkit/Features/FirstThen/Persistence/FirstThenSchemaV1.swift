import Foundation
import SwiftData

enum FirstThenItemRole: String, CaseIterable, Sendable {
    case first
    case then

    var sortIndex: Int {
        switch self {
        case .first:
            0
        case .then:
            1
        }
    }
}

enum OTToolkitSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [FirstThenBoard.self, FirstThenItem.self]
    }

    @Model
    final class FirstThenBoard {
        @Attribute(.unique) var id: UUID
        var name: String
        var sortIndex: Int
        var createdAt: Date
        var updatedAt: Date

        @Relationship(deleteRule: .cascade, inverse: \FirstThenItem.board)
        var items: [FirstThenItem] = []

        init(
            id: UUID,
            name: String,
            sortIndex: Int,
            createdAt: Date,
            updatedAt: Date,
            items: [FirstThenItem] = []
        ) {
            self.id = id
            self.name = name
            self.sortIndex = sortIndex
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.items = items

            for item in items {
                item.board = self
            }
        }
    }

    @Model
    final class FirstThenItem {
        @Attribute(.unique) var id: UUID
        var roleRawValue: String
        var label: String
        var systemSymbolName: String
        var sortIndex: Int
        var createdAt: Date
        var updatedAt: Date
        var board: FirstThenBoard?

        var role: FirstThenItemRole? {
            FirstThenItemRole(rawValue: roleRawValue)
        }

        init(
            id: UUID,
            role: FirstThenItemRole,
            label: String,
            systemSymbolName: String,
            sortIndex: Int,
            createdAt: Date,
            updatedAt: Date,
            board: FirstThenBoard? = nil
        ) {
            self.id = id
            roleRawValue = role.rawValue
            self.label = label
            self.systemSymbolName = systemSymbolName
            self.sortIndex = sortIndex
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.board = board
        }
    }
}

typealias FirstThenBoard = OTToolkitSchemaV1.FirstThenBoard
typealias FirstThenItem = OTToolkitSchemaV1.FirstThenItem
