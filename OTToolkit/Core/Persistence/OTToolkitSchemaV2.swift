@preconcurrency import SwiftData

/// Second versioned schema. It keeps the immutable First–Then V1 models and adds
/// the Token Board template introduced by OTK-031. First–Then models are
/// unchanged, so the V1→V2 migration is lightweight.
enum OTToolkitSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [FirstThenBoard.self, FirstThenItem.self, TokenBoardTemplate.self]
    }
}
