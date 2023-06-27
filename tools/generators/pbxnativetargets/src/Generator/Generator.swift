import Foundation
import PBXProj

/// A type that generates and writes to disk the
/// `PBXProject.attributes.TargetAttributes` `PBXProj` partial,
/// `PBXProject.targets` `PBXProj` partial, `PBXTargetDependency` `PBXProj`
/// partial, and target consolidation map files.
///
/// The `Generator` type is stateless. It can be used to generate multiple
/// partials. The `generate()` method is passed all the inputs needed to
/// generate a partial.
struct Generator {
    private let environment: Environment

    init(environment: Environment = .default) {
        self.environment = environment
    }

    /// Calculates the `PBXProject.attributes.TargetAttributes` `PBXProj`
    /// partial, `PBXProject.targets` `PBXProj` partial, `PBXTargetDependency`
    // `PBXProj` partial, and target consolidation map files. Then it writes
    /// them to disk.
    func generate(arguments: Arguments) throws {
//        let targetsPartial = environment.targetsPartial(
//        )
//
//        let targetAttributesPartial = environment.targetAttributesPartial(
//        )
//
//        let targetDependenciesPartial = environment.targetDependenciesPartial(
//        )
//
//        try environment.write(
//            targetsPartial,
//            /*to:*/ arguments.targetsOutputPath
//        )
//
//        try environment.write(
//            targetAttributesPartial,
//            /*to:*/ arguments.targetAttributesOutputPath
//        )
//
//        try environment.write(
//            targetDependenciesPartial,
//            /*to:*/ arguments.targetdependenciesOutputPath
//        )
    }
}
