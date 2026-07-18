import Foundation
import SwiftData

enum OTToolkitSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [OTToolkitSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}

extension LocalModelContainerFactory {
    static var appSchema: Schema {
        Schema(versionedSchema: OTToolkitSchemaV1.self)
    }

    static func makeAppContainer(storeURL: URL) throws -> ModelContainer {
        try makeContainer(
            schema: appSchema,
            migrationPlan: OTToolkitSchemaMigrationPlan.self,
            storeURL: storeURL
        )
    }
}
