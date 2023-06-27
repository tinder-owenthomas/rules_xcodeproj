import CustomDump
import XCTest

@testable import pbxnativetargets

final class TargetsArgumentsTests: XCTestCase {
    func test_toTargetArguments_emptyFileArrays() throws {
        // Arrange
        let arguments = try TargetsArguments.parse([
            "--targets",
            "//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3",
            "//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3",
            "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",

            "--product-types",
            "com.apple.product-type.tool",
            "com.apple.product-type.bundle.unit-test",
            "com.apple.product-type.library.static",

            "--product-paths",
            "bazel-out/applebin_macos-darwin_x86_64-dbg-STABLE-3/bin/tools/generators/legacy/generator",
            "bazel-out/applebin_macos-darwin_x86_64-dbg-STABLE-3/bin/tools/generators/legacy/test/tests.__internal__.__test_bundle_archive-root/tests.xctest",
            "bazel-out/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1/bin/tools/generators/legacy/libgenerator.library.a",

            "--platforms",
            "macosx",
            "iphoneos",
            "appletvsimulator",

            "--os-versions",
            "12.0",
            "16.0",
            "9.1",

            "--archs",
            "x86_64",
            "arm64",
            "i386",

            "--srcs-counts",
            "0",
            "2",
            "3",

            "--srcs",
            "tools/generators/legacy/test/AddTargetsTests.swift",
            "tools/generators/legacy/test/Array+ExtensionsTests.swift",
            "tools/generators/legacy/src/BuildSettingConditional.swift",
            "tools/generators/legacy/src/DTO/BazelLabel.swift",
            "tools/generators/legacy/src/DTO/BuildSetting.swift",

            "--output-product-filenames",
            "generator_codesigned",
            "tests.xctest",
            "",

            "--dsym-paths",
            "",
            "",
            "",
        ])

        let expectedTargetArguments: [TargetArguments] = [
            .init(
                id: "//tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3",
                productType: .commandLineTool,
                productPath: "bazel-out/applebin_macos-darwin_x86_64-dbg-STABLE-3/bin/tools/generators/legacy/generator",
                platform: .macOS,
                osVersion: "12.0",
                arch: "x86_64",
                srcs: [],
                nonArcSrcs: [],
                hdrs: [],
                resources: [],
                folderResources: [],
                outputProductFilename: "generator_codesigned",
                dsymPathsBuildSetting: ""
            ),
            .init(
                id: "//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3",
                productType: .unitTestBundle,
                productPath: "bazel-out/applebin_macos-darwin_x86_64-dbg-STABLE-3/bin/tools/generators/legacy/test/tests.__internal__.__test_bundle_archive-root/tests.xctest",
                platform: .iOSDevice,
                osVersion: "16.0",
                arch: "arm64",
                srcs: [
                    "tools/generators/legacy/test/AddTargetsTests.swift",
                    "tools/generators/legacy/test/Array+ExtensionsTests.swift",
                ],
                nonArcSrcs: [],
                hdrs: [],
                resources: [],
                folderResources: [],
                outputProductFilename: "tests.xctest",
                dsymPathsBuildSetting: ""
            ),
            .init(
                id: "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
                productType: .staticLibrary,
                productPath: "bazel-out/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1/bin/tools/generators/legacy/libgenerator.library.a",
                platform: .tvOSSimulator,
                osVersion: "9.1",
                arch: "i386",
                srcs: [
                    "tools/generators/legacy/src/BuildSettingConditional.swift",
                    "tools/generators/legacy/src/DTO/BazelLabel.swift",
                    "tools/generators/legacy/src/DTO/BuildSetting.swift",
                ],
                nonArcSrcs: [],
                hdrs: [],
                resources: [],
                folderResources: [],
                outputProductFilename: "",
                dsymPathsBuildSetting: ""
            ),
        ]

        // Act

        let targetArguments = arguments.toTargetArguments()

        // Assert

        XCTAssertNoDifference(
            targetArguments,
            expectedTargetArguments
        )
    }

    func test_toTargetArguments_full() throws {
        // Arrange
        let arguments = try TargetsArguments.parse([
            "--targets",
            "//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3",
            "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",

            "--product-types",
            "com.apple.product-type.bundle.unit-test",
            "com.apple.product-type.library.static",

            "--product-paths",
            "bazel-out/applebin_macos-darwin_x86_64-dbg-STABLE-3/bin/tools/generators/legacy/test/tests.__internal__.__test_bundle_archive-root/tests.xctest",
            "bazel-out/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1/bin/tools/generators/legacy/libgenerator.library.a",

            "--platforms",
            "iphoneos",
            "appletvsimulator",

            "--os-versions",
            "15.0",
            "10.2.1",

            "--archs",
            "arm64",
            "x86_64",

            "--srcs-counts",
            "2",
            "3",

            "--srcs",
            "tools/generators/legacy/test/AddTargetsTests.swift",
            "tools/generators/legacy/test/Array+ExtensionsTests.swift",
            "tools/generators/legacy/src/BuildSettingConditional.swift",
            "tools/generators/legacy/src/DTO/BazelLabel.swift",
            "tools/generators/legacy/src/DTO/BuildSetting.swift",

            "--non-arc-srcs-counts",
            "0",
            "2",

            "--non-arc-srcs",
            "tools/generators/legacy/src/DTO/BazelLabel.m",
            "tools/generators/legacy/src/DTO/BuildSetting.m",

            "--hdrs-counts",
            "2",
            "0",

            "--hdrs",
            "tools/generators/legacy/test/AddTargetsTests.h",
            "tools/generators/legacy/test/Array+ExtensionsTests.h",

            "--resources-counts",
            "1",
            "1",

            "--resources",
            "tools/generators/legacy/test/something.json",
            "tools/generators/legacy/src/something.json",

            "--folder-resources-counts",
            "2",
            "1",

            "--folder-resources",
            "tools/generators/legacy/test/something.bundle",
            "tools/generators/legacy/test/something.framework",
            "tools/generators/legacy/src/something.bundle",

            "--output-product-filenames",
            "tests.xctest",
            "",

            "--dsym-paths",
            #""bazel-out/applebin_macos-darwin_x86_64-opt-STABLE-4/bin/tools/generator/test/tests.xctest.dSYM" "bazel-out/applebin_macos-darwin_x86_64-opt-STABLE-5/bin/tools/generator/test/tests.xctest.dSYM""#,
            "",
        ])

        let expectedTargetArguments: [TargetArguments] = [
            .init(
                id: "//tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3",
                productType: .unitTestBundle,
                productPath: "bazel-out/applebin_macos-darwin_x86_64-dbg-STABLE-3/bin/tools/generators/legacy/test/tests.__internal__.__test_bundle_archive-root/tests.xctest",
                platform: .iOSDevice,
                osVersion: "15.0",
                arch: "arm64",
                srcs: [
                    "tools/generators/legacy/test/AddTargetsTests.swift",
                    "tools/generators/legacy/test/Array+ExtensionsTests.swift",
                ],
                nonArcSrcs: [],
                hdrs: [
                    "tools/generators/legacy/test/AddTargetsTests.h",
                    "tools/generators/legacy/test/Array+ExtensionsTests.h"
                ],
                resources: [
                    "tools/generators/legacy/test/something.json",
                ],
                folderResources: [
                    "tools/generators/legacy/test/something.bundle",
                    "tools/generators/legacy/test/something.framework",
                ],
                outputProductFilename: "tests.xctest",
                dsymPathsBuildSetting: "\"bazel-out/applebin_macos-darwin_x86_64-opt-STABLE-4/bin/tools/generator/test/tests.xctest.dSYM\" \"bazel-out/applebin_macos-darwin_x86_64-opt-STABLE-5/bin/tools/generator/test/tests.xctest.dSYM\""
            ),
            .init(
                id: "//tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1",
                productType: .staticLibrary,
                productPath: "bazel-out/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1/bin/tools/generators/legacy/libgenerator.library.a",
                platform: .tvOSSimulator,
                osVersion: "10.2.1",
                arch: "x86_64",
                srcs: [
                    "tools/generators/legacy/src/BuildSettingConditional.swift",
                    "tools/generators/legacy/src/DTO/BazelLabel.swift",
                    "tools/generators/legacy/src/DTO/BuildSetting.swift",
                ],
                nonArcSrcs: [
                    "tools/generators/legacy/src/DTO/BazelLabel.m",
                    "tools/generators/legacy/src/DTO/BuildSetting.m",
                ],
                hdrs: [],
                resources: [
                    "tools/generators/legacy/src/something.json",
                ],
                folderResources: [
                    "tools/generators/legacy/src/something.bundle",
                ],
                outputProductFilename: "",
                dsymPathsBuildSetting: ""
            ),
        ]

        // Act

        let targetArguments = arguments.toTargetArguments()

        // Assert

        XCTAssertNoDifference(
            targetArguments,
            expectedTargetArguments
        )
    }
}
