"""Actions for creating `PBXProj` partials."""

load("//xcodeproj/internal:collections.bzl", "flatten")
load("//xcodeproj/internal:memory_efficiency.bzl", "EMPTY_DEPSET", "EMPTY_STRING")
load(":platforms.bzl", "PLATFORM_NAME")

# Utility

def _apple_platform_to_platform_name(platform):
    return PLATFORM_NAME[platform]

def _depset_len(d):
    return str(len(d.to_list()))

def _depset_to_list(d):
    return d.to_list()

def _identity(seq):
    return seq

# Partials

# enum of flags, mainly to ensure the strings are frozen and reused
_flags = struct(
    archs = "--archs",
    c_params = "--c-params",
    colorize = "--colorize",
    consolidation_map_output_paths = "--consolidation-map-output-paths",
    cxx_params = "--cxx-params",
    default_xcode_configuration = "--default-xcode-configuration",
    dependencies = "--dependencies",
    dependency_counts = "--dependency-counts",
    dsym_paths = "--dsym-paths",
    files_paths = "--file-paths",
    folder_paths = "--folder-paths",
    folder_resources = "--folder-resources",
    folder_resources_counts = "--folder-resources-counts",
    hdrs = "--hdrs",
    hdrs_counts = "--hdrs-counts",
    hosted_targets = "--hosted-targets",
    labels = "--labels",
    label_counts = "--label-counts",
    non_arc_srcs = "--non-arc-srcs",
    non_arc_srcs_counts = "--non-arc-srcs-counts",
    organization_name = "--organization-name",
    os_versions = "--os-versions",
    output_product_filenames = "--output-product-filenames",
    platforms = "--platforms",
    post_build_script = "--post-build-script",
    pre_build_script = "--pre-build-script",
    product_paths = "--product-paths",
    product_types = "--product-types",
    resources = "--resources",
    resources_counts = "--resources-counts",
    srcs = "--srcs",
    srcs_counts = "--srcs-counts",
    swift_params = "--swift-params",
    targets = "--targets",
    target_counts = "--target-counts",
    use_base_internationalization = "--use-base-internationalization",
    xcode_configuration_counts = "--xcode-configuration-counts",
    xcode_configurations = "--xcode-configurations",
)

def _write_files_and_groups(
        *,
        actions,
        buildfile_maps,
        colorize,
        execution_root_file,
        generator_name,
        files,
        file_paths,
        folders,
        project_options,
        selected_model_versions_file,
        tool,
        workspace_directory):
    """
    Creates `File`s representing files and groups in a `.pbxproj`.

    Args:
        actions: `ctx.actions`.
        colorize: A `bool` indicating whether to colorize the output.
        execution_root_file: A `File` containing the absolute path to the Bazel
            execution root.
        files: A `depset` of `File`s  to include in the project.
        file_paths: A `depset` of file paths to files to include in the project.
            These are different from `files`, in order to handle normalized
            file paths.
        folders: A `depset` of paths to folders to include in the project.
        generator_name: The name of the `xcodeproj` generator target.
        project_options: A `dict` as returned by `project_options`.
        selected_model_versions_file: A `File` that contains a JSON
            representation of `[BazelPath: String]`, mapping `.xcdatamodeld`
            file paths to selected `.xcdatamodel` file names.
        tool: The executable that will generate the output files.
        workspace_directory: The absolute path to the Bazel workspace
            directory.

    Returns:
        A tuple with three elements:

        *   `pbxproject_known_regions`: The `File` for the
            `PBXProject.knownRegions` `PBXProj` partial.
        *   `files_and_groups`: The `File` for the files and groups `PBXProj`
            partial.
        *   `resolved_repositories`: A `File` containing a string for the
            `RESOLVED_REPOSITORIES` build setting.
    """
    pbxproject_known_regions = actions.declare_file(
        "{}_pbxproj_partials/pbxproject_known_regions".format(
            generator_name,
        ),
    )
    files_and_groups = actions.declare_file(
        "{}_pbxproj_partials/files_and_groups".format(
            generator_name,
        ),
    )
    resolved_repositories_file = actions.declare_file(
        "{}_pbxproj_partials/resolved_repositories_file".format(
            generator_name,
        ),
    )

    args = actions.args()
    args.use_param_file("@%s")
    args.set_param_file_format("multiline")

    # knownRegionsOutputPath
    args.add(pbxproject_known_regions)

    # filesAndGroupsOutputPath
    args.add(files_and_groups)

    # resolvedRepositoriesOutputPath
    args.add(resolved_repositories_file)

    # workspace
    args.add(workspace_directory)

    # executionRootFile
    args.add(execution_root_file)

    # selectedModelVersionsFile
    args.add(selected_model_versions_file)

    # developmentRegion
    args.add(project_options["development_region"])

    # useBaseInternationalization
    args.add(_flags.use_base_internationalization)

    # filePaths
    if files != EMPTY_DEPSET or file_paths != EMPTY_DEPSET:
        args.add(_flags.files_paths)
        args.add_all(files)
        # TODO: Consider moving normalization into `args.add_all.map_each`
        args.add_all(file_paths)

    # folderPaths
    args.add_all(_flags.folder_paths, folders)

    # colorize
    if colorize:
        args.add(_flags.colorize)

    actions.run(
        arguments = [args],
        executable = tool,
        inputs = [
            execution_root_file,
            selected_model_versions_file,
        ],
        outputs = [
            pbxproject_known_regions,
            files_and_groups,
            resolved_repositories_file,
        ],
        mnemonic = "WritePBXProjFileAndGroups",
    )

    return (
        pbxproject_known_regions,
        files_and_groups,
        resolved_repositories_file,
    )

def _write_pbxproject_targets(
        *,
        actions,
        colorize,
        generator_name,
        minimum_xcode_version,
        tool,
        xcode_target_configurations,
        xcode_targets_by_label):
    """
    Creates `File`s representing consolidated target in a `PBXProj`.

    Args:
        actions: `ctx.actions`.
        colorize: A `bool` indicating whether to colorize the output.
        generator_name: The name of the `xcodeproj` generator target.
        minimum_xcode_version: The minimum Xcode version that the generated
            project supports, as a `string`.
        tool: The executable that will generate the output files.
        xcode_target_configurations: A `dict` mapping `xcode_target.id` to a
            `list` of Xcode configuration names that the target is present in.
        xcode_targets_by_label:  A `dict` mapping `xcode_target.label` to a
            `dict` mapping `xcode_target.id` to `xcode_target`s.

    Returns:
        A tuple with four elements:

        *   `pbxproject_targets`: The `File` for the `PBXProject.targets`
            `PBXProj` partial.
        *   `pbxproject_target_attributes`: The `File` for the
            `PBXProject.attributes.TargetAttributes` `PBXProj` partial.
        *   `pbxtarget_dependencies`: The `File` for the
            `PBXTargetDependency` and `PBXContainerItemProxy` `PBXProj` partial.
        *   `consolidation_maps`: A `dict` mapping `File`s containing
            target consolidation maps to a `list` of `Label`s of the targets
            included in the map.
    """
    pbxproject_targets = actions.declare_file(
        "{}_pbxproj_partials/pbxproject_targets".format(
            generator_name,
        ),
    )
    pbxproject_target_attributes = actions.declare_file(
        "{}_pbxproj_partials/pbxproject_target_attributes".format(
            generator_name,
        ),
    )
    pbxtargetdependencies = actions.declare_file(
        "{}_pbxproj_partials/pbxtargetdependencies".format(
            generator_name,
        ),
    )

    bucketed_labels = {}
    for label in xcode_targets_by_label:
        # FIXME: Fine-tune this, and make it configurable
        bucketed_labels.setdefault(hash(label.name) % 8, []).append(label)

    consolidation_maps = {}

    args = actions.args()
    args.use_param_file("@%s")
    args.set_param_file_format("multiline")

    # targetsOutputPath
    args.add(pbxproject_targets)

    # targetAttributesOutputPath
    args.add(pbxproject_target_attributes)

    # targetDependenciesOutputPath
    args.add(pbxtargetdependencies)

    # minimumXcodeVersion
    args.add(minimum_xcode_version)

    archs = []
    dependencies = []
    dependency_counts = []
    label_counts = []
    labels = []
    os_versions = []
    platforms = []
    product_types = []
    product_paths = []
    target_counts = []
    target_ids = []
    xcode_configuration_counts = []
    xcode_configurations = []
    for idx, bucket_labels in enumerate(bucketed_labels.values()):
        consolidation_map = actions.declare_file(
            "{}_pbxproj_partials/consolidation_maps/{}".format(
                generator_name,
                idx,
            ),
        )
        consolidation_maps[consolidation_map] = bucket_labels

        label_counts.append(len(bucket_labels))
        for label in bucket_labels:
            labels.append(label)

            xcode_targets = xcode_targets_by_label[label].values()
            target_counts.append(len(xcode_targets))
            for xcode_target in xcode_targets:
                target_ids.append(xcode_target.id)
                product_types.append(xcode_target.product.type)
                product_paths.append(xcode_target.product.path)
                platforms.append(xcode_target.platform.platform)
                os_versions.append(xcode_target.platform.os_version)
                archs.append(xcode_target.platform.arch)
                dependency_counts.append(xcode_target.dependencies)
                dependencies.append(xcode_target.dependencies)

                configurations = xcode_target_configurations[xcode_target.id]
                xcode_configuration_counts.append(len(configurations))
                xcode_configurations.append(configurations)

    # consolidationMapOutputPaths
    args.add_all(
        _flags.consolidation_map_output_paths,
        consolidation_maps.keys(),
    )

    # labelCounts
    args.add_all(_flags.label_counts, label_counts)

    # labels
    args.add_all(_flags.labels, labels)

    # targetCounts
    args.add_all(_flags.target_counts, target_counts)

    # targets
    args.add_all(_flags.targets, target_ids)

    # xcodeConfigurationCounts
    args.add_all(
        _flags.xcode_configuration_counts,
        xcode_configuration_counts,
    )

    # xcodeConfigurations
    args.add_all(
        _flags.xcode_configurations,
        xcode_configurations,
        map_each = _identity,
    )

    # productTypes
    args.add_all(_flags.product_types, product_types)

    # productPaths
    args.add_all(_flags.product_paths, product_paths)

    # platforms
    args.add_all(
        _flags.platforms,
        platforms,
        map_each = _apple_platform_to_platform_name,
    )

    # osVersions
    args.add_all(_flags.os_versions, os_versions)

    # archs
    args.add_all(_flags.archs, archs)

    # dependencyCounts
    args.add_all(
        _flags.dependency_counts,
        dependency_counts,
        map_each = _depset_len,
    )

    # dependencies
    args.add_all(_flags.dependencies, dependencies, map_each = _depset_to_list)

    # colorize
    if colorize:
        args.add(_flags.colorize)

    actions.run(
        arguments = [args],
        executable = tool,
        outputs = [
            pbxproject_targets,
            pbxproject_target_attributes,
            pbxtargetdependencies,
        ] + consolidation_maps.keys(),
        mnemonic = "WritePBXProjPBXProjectTargets",
    )

    return (
        pbxproject_targets,
        pbxproject_target_attributes,
        pbxtargetdependencies,
        consolidation_maps,
    )

def _write_targets(
        *,
        actions,
        consolidation_maps,
        generator_name,
        hosted_targets,
        xcode_targets_by_label,
        temp_templates):
    """
    Creates `File`s representing targets in a `PBXProj` element.

    Args:
        actions: `ctx.actions`.
        consolidation_maps: A `dict` mapping `File`s containing target
            consolidation maps to a `list` of `Label`s of the targets included
            in the map.
        generator_name: The name of the `xcodeproj` generator target.
        hosted_targets: A `depset` of `struct`s with `host` and `hosted` fields.
            The `host` field is the target ID of the hosting target. The
            `hosted` field is the target ID of the hosted target.
        xcode_targets_by_label: A `dict` mapping `xcode_target.label` to a
            `dict` mapping `xcode_target.id` to `xcode_target`s.

    Returns:
        A tuple with three elements:

        *   `pbxnativetargets`: A `list` of `File`s for the `PBNativeTarget`
            `PBXProj` partials.
        *   `buildfile_maps`: A `list` of `File`s that map `PBXBuildFile`
            identifiers to file paths.
        *   `automatic_xcschemes`: A `list` of `File`s for automatically
            generated `.xcscheme`s.
    """
    pbxnativetargets = []
    buildfile_maps = []
    automatic_xcschemes = []
    for consolidation_map, labels in consolidation_maps.items():
        (
            label_pbxnativetargets,
            label_buildfile_map,
            label_automatic_xcschemes,
        ) = _write_consolidation_map_targets(
            actions = actions,
            consolidation_map = consolidation_map,
            generator_name = generator_name,
            hosted_targets = hosted_targets,
            idx = consolidation_map.basename,
            labels = labels,
            xcode_targets_by_label = xcode_targets_by_label,
            temp_templates = temp_templates,
        )

        pbxnativetargets.append(label_pbxnativetargets)
        buildfile_maps.append(label_buildfile_map)
        automatic_xcschemes.append(label_automatic_xcschemes)

    return (
        pbxnativetargets,
        buildfile_maps,
        automatic_xcschemes,
    )

# TODO: Verify we want to do this, versus popping the depset and creating the
# list at analysis. This retains the created `target_ids` in memory, which might
# not be the tradeoff we want to do.
def _create_map_hosted_targets(labels, xcode_targets_by_label):
    target_ids = {
        id: None
        for label in labels
        for id in xcode_targets_by_label[label]
    }

    def _map_hosted_targets(hosted_target):
        if hosted_target.hosted in target_ids:
            return [hosted_target.host, hosted_target.hosted]
        return None

    return _map_hosted_targets

def _dsym_files_to_string(dsym_files):
    dsym_paths = []
    for file in dsym_files.to_list():
        file_path = file.path

        # dSYM files contain plist and DWARF.
        if not file_path.endswith("Info.plist"):
            # ../Product.dSYM/Contents/Resources/DWARF/Product
            dsym_path = "/".join(file_path.split("/")[:-4])
            dsym_paths.append("\"{}\"".format(dsym_path))
    return " ".join(dsym_paths)

def _paths(files):
    return [file.path for file in files]

def _depset_paths(files):
    return [file.path for file in files.to_list()]

def _write_consolidation_map_targets(
        *,
        actions,
        consolidation_map,
        generator_name,
        hosted_targets,
        idx,
        labels,
        xcode_targets_by_label,
        temp_templates):
    """
    Creates `File`s representing targets in a `PBXProj` element, for a given \
    consolidation map

    Args:
        actions: `ctx.actions`.
        consolidation_map: A `File` containing a target consolidation maps.
        generator_name: The name of the `xcodeproj` generator target.
        hosted_targets: A `depset` of `struct`s with `host` and `hosted` fields.
            The `host` field is the target ID of the hosting target. The
            `hosted` field is the target ID of the hosted target.
        idx: The index of the consolidation map.
        labels: A `list` of `Label`s of the targets included in
            `consolidation_map`.
        xcode_targets_by_label: A `dict` mapping `xcode_target.label` to a
            `dict` mapping `xcode_target.id` to `xcode_target`s.

    Returns:
        A tuple with three elements:

        *   `pbxnativetargets`: A `File` for the `PBNativeTarget` `PBXProj`
            partial.
        *   `buildfile_map`: A `File` that map `PBXBuildFile` identifiers to
            file paths.
        *   `automatic_xcschemes`: A `File` for the directory containing
            automatically generated `.xcscheme`s.
    """
    pbxnativetargets = actions.declare_file(
        "{}_pbxproj_partials/pbxnativetargets/{}".format(
            generator_name,
            idx,
        ),
    )

    buildfile_map = actions.declare_file(
        "{}_pbxproj_partials/buildfile_maps/{}".format(
            generator_name,
            idx,
        ),
    )

    automatic_xcschemes = actions.declare_directory(
        "{}_pbxproj_partials/automatic_xcschemes/{}".format(
            generator_name,
            idx,
        ),
    )

    inputs = [consolidation_map] + temp_templates

    args = actions.args()
    args.use_param_file("%s")
    args.set_param_file_format("multiline")

    # targetsOutputPath
    args.add(pbxnativetargets)

    # buildfileMapOutputPath
    args.add(buildfile_map)

    # xcshemesOutputDirectory
    args.add(automatic_xcschemes.path)

    # consolidationMap
    args.add(consolidation_map)

    # hostedTargets
    args.add_all(
        _flags.hosted_targets,
        hosted_targets,
        allow_closure = True,
        map_each = _create_map_hosted_targets(
            labels = labels,
            xcode_targets_by_label = xcode_targets_by_label,
        ),
    )

    archs = []
    dsym_files = []
    folder_resources = []
    folder_resources_counts = []
    hdrs = []
    hdrs_counts = []
    non_arc_srcs = []
    non_arc_srcs_counts = []
    output_product_filenames = []
    os_versions = []
    platforms = []
    product_paths = []
    product_types = []
    resources = []
    resources_counts = []
    srcs = []
    srcs_counts = []
    target_ids = []
    for label in labels:
        for xcode_target in xcode_targets_by_label[label].values():
            target_ids.append(xcode_target.id)
            product_types.append(xcode_target.product.type)
            product_paths.append(xcode_target.product.path)
            platforms.append(xcode_target.platform.platform)
            os_versions.append(xcode_target.platform.os_version)
            archs.append(xcode_target.platform.arch)
            srcs_counts.append(len(xcode_target.inputs.srcs))
            srcs.append(xcode_target.inputs.srcs)
            non_arc_srcs_counts.append(len(xcode_target.inputs.non_arc_srcs))
            non_arc_srcs.append(xcode_target.inputs.non_arc_srcs)
            hdrs_counts.append(len(xcode_target.inputs.hdrs))
            hdrs.append(xcode_target.inputs.hdrs)
            resources_counts.append(xcode_target.inputs.resources)
            resources.append(xcode_target.inputs.resources)
            folder_resources_counts.append(xcode_target.inputs.folder_resources)
            folder_resources.append(xcode_target.inputs.folder_resources)
            output_product_filenames.append(
                # FIXME: Make it work with `None` values? Would be nice to remove the check
                xcode_target.outputs.product_path or EMPTY_STRING,
            )
            dsym_files.append(xcode_target.outputs.dsym_files)

            # args.add_all(
            #     _flags.swift_params,
            #     xcode_target.params.swift_raw_params,
            # )
            # inputs.extend(xcode_target.params.swift_raw_params)

            # args.add_all(_flags.c_params, xcode_target.params.c_raw_params)
            # inputs.extend(xcode_target.params.c_raw_params)

            # args.add_all(_flags.cxx_params, xcode_target.params.cxx_raw_params)
            # inputs.extend(xcode_target.params.cxx_raw_params)

    # targets
    args.add_all(_flags.targets, target_ids)

    # productTypes
    args.add_all(_flags.product_types, product_types)

    # productPaths
    args.add_all(_flags.product_paths, product_paths)

    # platforms
    args.add_all(
        _flags.platforms,
        platforms,
        map_each = _apple_platform_to_platform_name,
    )

    # osVersions
    args.add_all(_flags.os_versions, os_versions)

    # archs
    args.add_all(_flags.archs, archs)

    has_srcs = False
    for srcs_count in srcs_counts:
        if srcs_count > 0:
            has_srcs = True
            break
    if has_srcs:
        # srcsCounts
        args.add_all(_flags.srcs_counts, srcs_counts)

        # srcs
        args.add_all(_flags.srcs, srcs, map_each = _paths)

    has_non_arc_srcs = False
    for non_arc_srcs_count in non_arc_srcs_counts:
        if non_arc_srcs_count > 0:
            has_non_arc_srcs = True
            break
    if has_non_arc_srcs:
        # nonArcSrcsCounts
        args.add_all(_flags.non_arc_srcs_counts, non_arc_srcs_counts)

        # nonArcSrcs
        args.add_all(_flags.non_arc_srcs, non_arc_srcs, map_each = _paths)

    has_hdrs = False
    for hdrs_count in hdrs_counts:
        if hdrs_count > 0:
            has_hdrs = True
            break
    if has_hdrs:
        # hdrsCounts
        args.add_all(_flags.hdrs_counts, hdrs_counts)

        # hdrs
        args.add_all(_flags.hdrs, hdrs, map_each = _paths)

    # resourcesCounts
    args.add_all(
        _flags.resources_counts,
        resources_counts,
        map_each = _depset_len,
    )

    # resources
    args.add_all(_flags.resources, resources)

    # folderResourcesCounts
    args.add_all(
        _flags.folder_resources_counts,
        folder_resources_counts,
        map_each = _depset_len,
    )

    # folderResources
    args.add_all(_flags.folder_resources, folder_resources)

    # outputProductFilenames
    args.add_all(_flags.output_product_filenames, output_product_filenames)

    # dsymPaths
    args.add_all(
        _flags.dsym_paths,
        dsym_files,
        map_each = _dsym_files_to_string,
    )

    actions.run_shell(
        arguments = [args],
        inputs = inputs,
        outputs = [
            pbxnativetargets,
            buildfile_map,
            automatic_xcschemes,
        ],
        command = """\
cp -c {pbxnativetargets_template} {pbxnativetargets}

echo "TODO" > {buildfile_map}

mkdir -p {automatic_xcschemes}
echo "TODO" > "{automatic_xcschemes}/random1.xcscheme"
echo "TODO" > "{automatic_xcschemes}/random2.xcscheme"
""".format(
            pbxnativetargets = pbxnativetargets.path,
            pbxnativetargets_template = temp_templates[0].path,
            buildfile_map = buildfile_map.path,
            automatic_xcschemes = automatic_xcschemes.path,
        ),
        mnemonic = "WritePBXNativeTargets",
        execution_requirements = {
            # Reading lots of files, let's have some speed
            "no-sandbox": "1",
        },
    )

    return (
        pbxnativetargets,
        buildfile_map,
        automatic_xcschemes,
    )

def _write_pbxproj_prefix(
        *,
        actions,
        build_mode,
        colorize,
        default_xcode_configuration,
        execution_root_file,
        generator_name,
        index_import,
        minimum_xcode_version,
        platforms,
        post_build_script,
        pre_build_script,
        project_options,
        resolved_repositories_file,
        target_ids_list,
        tool,
        workspace_directory,
        xcode_configurations):
    """
    Creates a `File` containing a `PBXProject` prefix `PBXProj` partial.

    Args:
        actions: `ctx.actions`.
        build_mode: `xcodeproj.build_mode`.
        colorize: A `bool` indicating whether to colorize the output.
        default_xcode_configuration: Optional. The name of the the Xcode
            configuration to use when building, if not overridden by custom
            schemes. If not set, the first Xcode configuration alphabetically
            will be used.
        execution_root_file: A `File` containing the absolute path to the Bazel
            execution root.
        generator_name: The name of the `xcodeproj` generator target.
        index_import: The executable `File` for the `index_import` tool.
        minimum_xcode_version: The minimum Xcode version that the generated
            project supports, as a `string`.
        platforms: A `depset` of `apple_platform`s.
        post_build_script: A `string` representing a post build script.
        pre_build_script: A `string` representing a pre build script.
        project_options: A `dict` as returned by `project_options`.
        resolved_repositories_file: A `File` containing containing a string for
            the `RESOLVED_REPOSITORIES` build setting.
        target_ids_list: A `File` containing a list of target IDs.
        tool: The executable that will generate the `PBXProj` partial.
        workspace_directory: The absolute path to the Bazel workspace
            directory.
        xcode_configurations: A sequence of Xcode configuration names.

    Returns:
        The `File` for the `PBXProject` prefix `PBXProj` partial.
    """
    inputs = [execution_root_file, resolved_repositories_file]
    output = actions.declare_file(
        "{}_pbxproj_partials/pbxproj_prefix".format(
            generator_name,
        ),
    )

    args = actions.args()
    args.use_param_file("@%s")
    args.set_param_file_format("multiline")

    # outputPath
    args.add(output)

    # workspace
    args.add(workspace_directory)

    # executionRootFile
    args.add(execution_root_file)

    # targetIdsFile
    args.add(target_ids_list)

    # indexImport
    args.add(index_import)

    # resolvedRepositoriesFile
    args.add(resolved_repositories_file)

    # buildMode
    args.add(build_mode)

    # minimumXcodeVersion
    args.add(minimum_xcode_version)

    # developmentRegion
    args.add(project_options["development_region"])

    # organizationName
    organization_name = project_options.get("organization_name")
    if organization_name:
        args.add(_flags.organization_name, organization_name)

    # platforms
    args.add_all(
        _flags.platforms,
        platforms,
        map_each = _apple_platform_to_platform_name,
    )

    # xcodeConfigurations
    args.add_all(_flags.xcode_configurations, xcode_configurations)

    # defaultXcodeConfiguration
    if default_xcode_configuration:
        args.add(
            _flags.default_xcode_configuration,
            default_xcode_configuration,
        )

    # preBuildScript
    if pre_build_script:
        pre_build_script_output = actions.declare_file(
            "{}_pbxproj_partials/pre_build_script".format(
                generator_name,
            ),
        )
        actions.write(
            pre_build_script_output,
            pre_build_script,
        )
        inputs.append(pre_build_script_output)
        args.add(_flags.pre_build_script, pre_build_script_output)

    # postBuildScript
    if post_build_script:
        post_build_script_output = actions.declare_file(
            "{}_pbxproj_partials/post_build_script".format(
                generator_name,
            ),
        )
        actions.write(
            post_build_script_output,
            post_build_script,
        )
        inputs.append(post_build_script_output)
        args.add(_flags.post_build_script, post_build_script_output)

    # colorize
    if colorize:
        args.add(_flags.colorize)

    actions.run(
        arguments = [args],
        executable = tool,
        inputs = inputs,
        outputs = [output],
        mnemonic = "WritePBXProjPrefix",
    )

    return output

# `project.pbxproj`

def _write_project_pbxproj(
        *,
        actions,
        files_and_groups,
        generator_name,
        pbxproj_prefix,
        pbxproject_targets,
        pbxproject_known_regions,
        pbxproject_target_attributes,
        pbxtargetdependencies,
        targets):
    """
    Creates a `project.pbxproj` `File`.

    Args:
        actions: `ctx.actions`.
        files_and_groups: The `files_and_groups` `File` returned from
            `pbxproj_partials.write_files_and_groups`.
        generator_name: The name of the `xcodeproj` generator target.
        pbxproj_prefix: The `File` returned from
            `pbxproj_partials.write_pbxproj_prefix`.
        pbxproject_known_regions: The `known_regions` `File` returned from
            `pbxproj_partials.write_known_regions`.
        pbxproject_target_attributes: The `pbxproject_target_attributes` `File` returned from
            `pbxproj_partials.write_pbxproject_targets`.
        pbxproject_targets: The `pbxproject_targets` `File` returned from
            `pbxproj_partials.write_pbxproject_targets`.
        pbxtargetdependencies: The `pbxtargetdependencies` `Files` returned from
            `pbxproj_partials.write_pbxproject_targets`.
        targets: The `targets` `list` of `Files` returned from
            `pbxproj_partials.write_targets`.

    Returns:
        A `project.pbxproj` `File`.
    """
    output = actions.declare_file("{}.project.pbxproj".format(generator_name))

    inputs = [
        pbxproj_prefix,
        pbxproject_target_attributes,
        pbxproject_known_regions,
        pbxproject_targets,
    ] + targets + [
        pbxtargetdependencies,
        # TODO: Use all targets after stubs are replaced
        files_and_groups,
    ]

    args = actions.args()
    args.use_param_file("%s")
    args.set_param_file_format("multiline")
    args.add_all(inputs)

    actions.run_shell(
        arguments = [args],
        inputs = inputs,
        outputs = [output],
        command = """\
if [ $# -eq 1 ]; then
    xargs cat < "$1" > {output}
else
    cat "$@" > {output}
fi
""".format(output = output.path),
        mnemonic = "WriteXcodeProjPBXProj",
        execution_requirements = {
            # Absolute paths
            "no-remote": "1",
            # Each file is directly referenced, so lets have some speed
            "no-sandbox": "1",
        },
    )

    return output

pbxproj_partials = struct(
    write_files_and_groups = _write_files_and_groups,
    write_project_pbxproj = _write_project_pbxproj,
    write_pbxproj_prefix = _write_pbxproj_prefix,
    write_pbxproject_targets = _write_pbxproject_targets,
    write_targets = _write_targets,
)
