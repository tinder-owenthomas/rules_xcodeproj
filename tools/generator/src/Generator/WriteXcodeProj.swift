import PathKit
import XcodeProj

extension Generator {
    /// Writes the ".xcodeproj" file to disk.
    static func writeXcodeProj(
        _ xcodeProj: XcodeProj,
        directories: Directories,
        files: [FilePath: File],
        to outputPath: Path
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            let internalOutputPath = outputPath + directories.internalDirectoryName

            for (filePath, file) in files.filter(\.key.isInternal) {
                guard case let .reference(_, maybeContent) = file else {
                    continue
                }
                guard let content = maybeContent else {
                    continue
                }

                group.addTask {
                    let path = internalOutputPath + filePath.path
                    try path.parent().mkpath()
                    try path.write(content)
                }

                try await group.waitForAll()
            }
            
            group.addTask {
                try xcodeProj.write(path: outputPath)
            }
        }
    }
}

private extension FilePath {
    var isInternal: Bool { type == .internal }
}
