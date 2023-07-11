import CustomDump
import XCTest

@testable import pbxproject_targets
@testable import PBXProj

final class CalculateConsolidationMapsTests: XCTestCase {
    func test_success() throws {
        // Arrange

        let identifiedTargets: [IdentifiedTarget] = [
            .mock(
                consolidationMapOutputPath: URL(fileURLWithPath: "/tmp/1"),
                key: ["B"],
                identifier: .init(
                    name: "b",
                    subIdentifier: .init(shard: "42", hash: "12345678"),
                    full: "B_ID /* b */",
                    withoutComment: "B_ID"
                ),
                dependencies: []
            ),
            .mock(
                consolidationMapOutputPath: URL(fileURLWithPath: "/tmp/0"),
                key: ["A"],
                identifier: .init(
                    name: "AA",
                    subIdentifier: .init(shard: "07", hash: "11111111"),
                    full: "A_ID /* AA */",
                    withoutComment: "A_ID"
                ),
                dependencies: ["C"]
            ),
            .mock(
                consolidationMapOutputPath: URL(fileURLWithPath: "/tmp/1"),
                key: ["C"],
                identifier: .init(
                    name: "C",
                    subIdentifier: .init(shard: "10", hash: "FFFFFFFF"),
                    full: "C_ID /* C */",
                    withoutComment: "C_ID"
                ),
                dependencies: []
            ),
        ]
        let identifiers: [TargetID: Identifiers.Targets.Identifier] = [
            "A": identifiedTargets[1].identifier,
            "B": identifiedTargets[0].identifier,
            "C": identifiedTargets[2].identifier,
        ]

        let expectedConsolidationMaps: [URL: [ConsolidationMapEntry]] = [
            URL(fileURLWithPath: "/tmp/1"): [
                .init(
                    key: ["B"],
                    name: "b",
                    subIdentifier: .init(shard: "42", hash: "12345678"),
                    dependencySubIdentifiers: []
                ),
                .init(
                    key: ["C"],
                    name: "C",
                    subIdentifier: .init(shard: "10", hash: "FFFFFFFF"),
                    dependencySubIdentifiers: []
                ),
            ],
            URL(fileURLWithPath: "/tmp/0"): [
                .init(
                    key: ["A"],
                    name: "AA",
                    subIdentifier: .init(shard: "07", hash: "11111111"),
                    dependencySubIdentifiers: [
                        .init(shard: "10", hash: "FFFFFFFF"),
                    ]
                ),
            ],
        ]

        // Act

        let consolidationMaps = try Generator.CalculateConsolidationMaps
            .defaultCallable(
                identifiedTargets: identifiedTargets,
                identifiers: identifiers
            )

        // Assert

        XCTAssertNoDifference(consolidationMaps, expectedConsolidationMaps)
    }

    func test_missingDependency_throws() {
        // Arrange

        let identifiedTargets: [IdentifiedTarget] = [
            .mock(key: ["A"], dependencies: ["B"]),
        ]
        let identifiers: [TargetID: Identifiers.Targets.Identifier] = [
            "A": identifiedTargets[0].identifier,
        ]

        // Act/Assert

        XCTAssertThrowsError(
            try Generator.CalculateConsolidationMaps.defaultCallable(
                identifiedTargets: identifiedTargets,
                identifiers: identifiers
            )
        )
    }
}
