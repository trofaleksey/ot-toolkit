import Foundation

struct LocalStoreLayout: Equatable {
    static let directoryName = "OTToolkit"
    static let storeName = "OTToolkit.store"

    let contentDirectory: URL

    var storeURL: URL {
        contentDirectory.appendingPathComponent(Self.storeName, isDirectory: false)
    }

    var filesDirectory: URL {
        contentDirectory.appendingPathComponent("Files", isDirectory: true)
    }

    var cachesDirectory: URL {
        contentDirectory.appendingPathComponent("Caches", isDirectory: true)
    }

    var temporaryDirectory: URL {
        contentDirectory.appendingPathComponent("Temporary", isDirectory: true)
    }

    var resetBackupDirectory: URL {
        contentDirectory
            .deletingLastPathComponent()
            .appendingPathComponent(
                ".\(contentDirectory.lastPathComponent).reset-backup", isDirectory: true)
    }

    var managedDirectories: [URL] {
        [contentDirectory, filesDirectory, cachesDirectory, temporaryDirectory]
    }

    static func applicationSupport(fileManager: FileManager = .default) throws -> Self {
        let applicationSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        return Self(
            contentDirectory: applicationSupport.appendingPathComponent(
                directoryName,
                isDirectory: true
            )
        )
    }
}

struct LocalStoreResetStaging {
    let originalContentExisted: Bool
}

protocol LocalStoreFilePolicyApplying {
    func apply(to url: URL) throws
}

struct CompleteProtectionAndBackupExclusionPolicy: LocalStoreFilePolicyApplying {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func apply(to url: URL) throws {
        try fileManager.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: url.path
        )

        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var mutableURL = url
        try mutableURL.setResourceValues(resourceValues)
    }
}

struct LocalStoreFileSystem {
    private let fileManager: FileManager
    private let filePolicy: any LocalStoreFilePolicyApplying

    init(
        fileManager: FileManager = .default,
        filePolicy: (any LocalStoreFilePolicyApplying)? = nil
    ) {
        self.fileManager = fileManager
        self.filePolicy =
            filePolicy
            ?? CompleteProtectionAndBackupExclusionPolicy(fileManager: fileManager)
    }

    func prepareForLaunch(_ layout: LocalStoreLayout) throws {
        try recoverInterruptedResetIfNeeded(layout)
        try prepareFreshContent(layout)
    }

    func prepareFreshContent(_ layout: LocalStoreLayout) throws {
        for directory in layout.managedDirectories {
            try fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true,
                attributes: [.protectionKey: FileProtectionType.complete]
            )
        }

        try secureCurrentContent(layout)
    }

    func secureCurrentContent(_ layout: LocalStoreLayout) throws {
        guard fileManager.fileExists(atPath: layout.contentDirectory.path) else {
            return
        }

        try applyPolicyRecursively(to: layout.contentDirectory)
    }

    func stageCurrentContent(_ layout: LocalStoreLayout) throws -> LocalStoreResetStaging {
        guard !fileManager.fileExists(atPath: layout.resetBackupDirectory.path) else {
            throw CocoaError(.fileWriteFileExists)
        }

        let originalContentExisted = fileManager.fileExists(atPath: layout.contentDirectory.path)
        if originalContentExisted {
            try fileManager.moveItem(
                at: layout.contentDirectory,
                to: layout.resetBackupDirectory
            )
        }

        return LocalStoreResetStaging(originalContentExisted: originalContentExisted)
    }

    func commitReset(_ layout: LocalStoreLayout) throws {
        guard fileManager.fileExists(atPath: layout.resetBackupDirectory.path) else {
            return
        }

        try fileManager.removeItem(at: layout.resetBackupDirectory)
    }

    func rollBackReset(
        _ staging: LocalStoreResetStaging,
        layout: LocalStoreLayout
    ) throws {
        if fileManager.fileExists(atPath: layout.contentDirectory.path) {
            try fileManager.removeItem(at: layout.contentDirectory)
        }

        if staging.originalContentExisted {
            try fileManager.moveItem(
                at: layout.resetBackupDirectory,
                to: layout.contentDirectory
            )
            try secureCurrentContent(layout)
        }
    }

    func originalContentIsPreserved(
        after staging: LocalStoreResetStaging?,
        layout: LocalStoreLayout
    ) -> Bool {
        guard let staging, staging.originalContentExisted else {
            return true
        }

        return fileManager.fileExists(atPath: layout.contentDirectory.path)
            || fileManager.fileExists(atPath: layout.resetBackupDirectory.path)
    }

    private func recoverInterruptedResetIfNeeded(_ layout: LocalStoreLayout) throws {
        guard fileManager.fileExists(atPath: layout.resetBackupDirectory.path) else {
            return
        }

        if fileManager.fileExists(atPath: layout.contentDirectory.path) {
            try fileManager.removeItem(at: layout.contentDirectory)
        }

        try fileManager.moveItem(
            at: layout.resetBackupDirectory,
            to: layout.contentDirectory
        )
    }

    private func applyPolicyRecursively(to url: URL) throws {
        try filePolicy.apply(to: url)

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
            isDirectory.boolValue
        else {
            return
        }

        let children = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil
        )
        for child in children {
            try applyPolicyRecursively(to: child)
        }
    }
}
