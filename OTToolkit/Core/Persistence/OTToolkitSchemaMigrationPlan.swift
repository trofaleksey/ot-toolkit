import Foundation
import SwiftData

enum OTToolkitSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [OTToolkitSchemaV1.self, OTToolkitSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [
            .lightweight(
                fromVersion: OTToolkitSchemaV1.self,
                toVersion: OTToolkitSchemaV2.self
            )
        ]
    }
}

extension LocalModelContainerFactory {
    static var appSchema: Schema {
        Schema(versionedSchema: OTToolkitSchemaV2.self)
    }

    static func makeAppContainer(storeURL: URL) throws -> ModelContainer {
        try makeContainer(
            schema: appSchema,
            migrationPlan: OTToolkitSchemaMigrationPlan.self,
            storeURL: storeURL
        )
    }
}
