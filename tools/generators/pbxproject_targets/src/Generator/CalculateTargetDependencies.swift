import PBXProj

extension Generator {
    struct CalculateTargetDependencies {
        private let calculateContainerItemProxy: CalculateContainerItemProxy
        private let calculateTargetDependency: CalculateTargetDependency

        private let callable: Callable

        /// - Parameters:
        ///   - callable: The function that will be called in
        ///     `callAsFunction()`.
        init(
            calculateContainerItemProxy: CalculateContainerItemProxy,
            calculateTargetDependency: CalculateTargetDependency,
            callable: @escaping Callable = Self.defaultCallable
        ) {
            self.calculateContainerItemProxy = calculateContainerItemProxy
            self.calculateTargetDependency = calculateTargetDependency

            self.callable = callable
        }

        /// Calculates all the `PBXTargetDependency` and `PBXContainerItemProxy`
        /// elements.
        func callAsFunction(
            identifiedTargets: [IdentifiedTarget],
            identifiers: [TargetID: Identifiers.Targets.Identifier]
        ) throws -> [Element] {
            return try callable(
                /*identifiedTargets:*/ identifiedTargets,
                /*identifiers:*/ identifiers,
                /*calculateContainerItemProxy:*/ calculateContainerItemProxy,
                /*calculateTargetDependency:*/ calculateTargetDependency
            )
        }
    }
}

// MARK: - CalculateTargetDependencies.Callable

extension Generator.CalculateTargetDependencies {
    typealias Callable = (
        _ identifiedTargets: [IdentifiedTarget],
        _ identifiers: [TargetID: Identifiers.Targets.Identifier],
        _ calculateContainerItemProxy: Generator.CalculateContainerItemProxy,
        _ calculateTargetDependency: Generator.CalculateTargetDependency
    ) throws -> [Element]

    // FIXME: Add test
    static func defaultCallable(
        identifiedTargets: [IdentifiedTarget],
        identifiers: [TargetID: Identifiers.Targets.Identifier],
        calculateContainerItemProxy: Generator.CalculateContainerItemProxy,
        calculateTargetDependency: Generator.CalculateTargetDependency
    ) throws -> [Element] {
        var targetDependencies: [Element] = []
        for target in identifiedTargets {
            let identifier = target.identifier

            for dependency in target.dependencies {
                let dependencyIdentifier = try identifiers.value(
                    for: dependency,
                    context: "Dependency"
                )

                let containerItemProxy = Element(
                    identifier: Identifiers.Targets.containerItemProxy(
                        from: identifier.subIdentifier,
                        to: dependencyIdentifier.subIdentifier
                    ),
                    content: calculateContainerItemProxy(
                        identifier: dependencyIdentifier
                    )
                )
                targetDependencies.append(containerItemProxy)

                let targetDependency = Element(
                    identifier: Identifiers.Targets.dependency(
                        from: identifier.subIdentifier,
                        to: dependencyIdentifier.subIdentifier
                    ),
                    content: calculateTargetDependency(
                        identifier: dependencyIdentifier,
                        containerItemProxyIdentifier:
                            containerItemProxy.identifier
                    )
                )
                targetDependencies.append(targetDependency)
            }
        }

        return targetDependencies
    }
}
