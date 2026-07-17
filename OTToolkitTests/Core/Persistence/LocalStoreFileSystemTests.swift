import Foundation
import XCTest
@testable import OTToolkit

final class LocalStoreFileSystemTests: XCTestCase {
    private final class RecordingFilePolicy: LocalStoreFilePolicyApplying {
        private let wrapped: any LocalStoreFilePolicyApplying
        private(set) var appliedURLs: [URL] = []

        init(wrapped: any LocalStoreFilePolicyApplying) {
            self.wrapped = wrapped
        }

        func apply(to url: URL) throws {
            appliedURLs.append(url)
            try wrapped.apply(to: url)
        }
    }

    private let fileManager = FileManager.default
    private var testRoot: URL!
    private var layout: LocalStoreLayout!

    override func setUpWithError() throws {
        try super.setUpWithError()
        testRoot = fileManager.temporaryDirectory.appendingPathComponent(
            "LocalStoreFileSystemTests-\(UUID().uuidString)",
            isDirectory: true
        )
        layout = LocalStoreLayout(contentDirectory: testRoot.appendingPathComponent("Content"))
    }

    override func tearDownWithError() throws {
        if fileManager.fileExists(atPath: testRoot.path) {
            try fileManager.removeItem(at: testRoot)
        }
        try super.tearDownWithError()
    }

    func testPreparationProtectsAndExcludesDirectoriesAndSidecarsFromBackup() throws {
        let policy = RecordingFilePolicy(
            wrapped: CompleteProtectionAndBackupExclusionPolicy(fileManager: fileManager)
        )
        let subject = LocalStoreFileSystem(
            fileManager: fileManager,
            filePolicy: policy
        )
        try subject.prepareForLaunch(layout)

        let sidecars = [
            layout.storeURL,
            URL(fileURLWithPath: layout.storeURL.path + "-wal"),
            URL(fileURLWithPath: layout.storeURL.path + "-shm"),
        ]
        for sidecar in sidecars {
            XCTAssertTrue(
                fileManager.createFile(atPath: sidecar.path, contents: Data("fixture".utf8)))
        }

        try subject.secureCurrentContent(layout)

        for url in layout.managedDirectories + sidecars {
            XCTAssertTrue(
                policy.appliedURLs.contains(url),
                "Expected the protection policy to cover \(url.lastPathComponent)"
            )

            let values = try url.resourceValues(forKeys: [.isExcludedFromBackupKey])
            XCTAssertEqual(
                values.isExcludedFromBackup,
                true,
                "Expected backup exclusion for \(url.lastPathComponent)"
            )
        }
    }

    func testInterruptedResetRestoresStagedOriginalContentOnNextLaunch() throws {
        let subject = LocalStoreFileSystem(fileManager: fileManager)
        try subject.prepareForLaunch(layout)
        let marker = layout.filesDirectory.appendingPathComponent("original.fixture")
        XCTAssertTrue(fileManager.createFile(atPath: marker.path, contents: Data("original".utf8)))

        _ = try subject.stageCurrentContent(layout)
        try subject.prepareFreshContent(layout)
        let replacement = layout.filesDirectory.appendingPathComponent("replacement.fixture")
        XCTAssertTrue(fileManager.createFile(atPath: replacement.path, contents: Data()))

        try subject.prepareForLaunch(layout)

        XCTAssertTrue(fileManager.fileExists(atPath: marker.path))
        XCTAssertFalse(fileManager.fileExists(atPath: replacement.path))
        XCTAssertFalse(fileManager.fileExists(atPath: layout.resetBackupDirectory.path))
    }
}
