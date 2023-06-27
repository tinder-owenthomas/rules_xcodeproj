import PBXProj

extension Generator {
    /// Provides the callable dependencies for `Generator`.
    ///
    /// The main purpose of `Environment` is to enable dependency injection,
    /// allowing for different implementations to be used in tests.
    struct Environment {
        let write: Write
    }
}

extension Generator.Environment {
    static let `default` = Self(
        write: Write()
    )
}
