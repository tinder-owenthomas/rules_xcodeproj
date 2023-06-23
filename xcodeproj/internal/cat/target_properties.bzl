"""Functions for processing target properties."""

load(":collections.bzl", "uniq")
load("//xcodeproj/internal:memory_efficiency.bzl", "memory_efficient_depset")

def process_dependencies(*, transitive_infos):
    """Logic for processing target dependencies.

    Args:
        transitive_infos: A `list` of `XcodeProjInfo`s for the transitive
            dependencies of `target`.

    Returns:
        A `tuple` containing two elements:

        *   A `depset` of direct dependencies.
        *   A `depset` of direct and transitive dependencies.
    """
    direct_dependencies = []
    direct_transitive_dependencies = []
    all_transitive_dependencies = []
    for info in transitive_infos:
        all_transitive_dependencies.append(info.transitive_dependencies)
        if info.xcode_target:
            direct_dependencies.append(info.xcode_target.id)
        else:
            # We pass on the next level of dependencies if the previous target
            # didn't create an Xcode target.
            direct_transitive_dependencies.append(info.dependencies)

    direct = memory_efficient_depset(
        direct_dependencies,
        transitive = direct_transitive_dependencies,
    )
    transitive = memory_efficient_depset(
        direct_dependencies,
        transitive = all_transitive_dependencies,
    )
    return (direct, transitive)

def process_modulemaps(*, swift_info):
    """Logic for working with modulemaps and their paths.

    Args:
        swift_info: A `SwiftInfo` provider.

    Returns:
        A `tuple` of files of the modules maps of the passed `SwiftInfo`.
    """
    if not swift_info:
        return ()

    modulemap_files = []
    for module in swift_info.direct_modules:
        compilation_context = module.compilation_context
        if not compilation_context:
            continue

        for module_map in compilation_context.module_maps:
            if type(module_map) == "File":
                modulemap_files.append(module_map)

    # Different modules might be defined in the same modulemap file, so we need
    # to deduplicate them.
    return tuple(uniq(modulemap_files))
