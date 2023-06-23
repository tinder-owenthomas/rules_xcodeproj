"""Module containing functions dealing with the `xcode_target` data \
structure."""

load(
    "//xcodeproj/internal:memory_efficiency.bzl",
    "EMPTY_DEPSET",
    "memory_efficient_depset",
)

# `xcode_target`

def _make_xcode_target(
        *,
        configuration,
        dependencies,
        id,
        inputs,
        label,
        outputs,
        params,
        platform,
        product,
        test_host,
        transitive_dependencies):
    """Creates the internal data structure of the `xcode_targets` module.

    Args:
        configuration: The configuration of the `Target`.
        dependencies: A `depset` of `id`s of targets that this target depends
            on.
        id: A unique identifier. No two Xcode targets will have the same `id`.
            This won't be user facing, the generator will use other fields to
            generate a unique name for a target.
        label: The `Label` of the `Target`.
        transitive_dependencies: A `depset` of `id`s of all transitive targets
            that this target depends on.
    """

    return struct(
        configuration = configuration,
        dependencies = dependencies,
        id = id,
        inputs = _to_xcode_target_inputs(inputs),
        label = label,
        outputs = _to_xcode_target_outputs(outputs),
        params = params,
        platform = platform,
        product = product,
        test_host = test_host,
        transitive_dependencies = transitive_dependencies,
    )

def _to_xcode_target_inputs(inputs):
    return struct(
        folder_resources = inputs.folder_resources,
        hdrs = tuple(inputs.hdrs),
        non_arc_srcs = tuple(inputs.non_arc_srcs),
        resources = inputs.resources,
        # TODO: Get these as non-flattened lists, to prevent processing/list creation?
        srcs = tuple(inputs.srcs),
    )

def _to_xcode_target_outputs(outputs):
    direct_outputs = outputs.direct_outputs

    swift_generated_header = None
    if direct_outputs:
        swift = direct_outputs.swift
        if swift:
            swiftmodule = swift.module.swiftmodule
            if swift.generated_header:
                swift_generated_header = swift.generated_header

    return struct(
        dsym_files = (
            (direct_outputs.dsym_files if direct_outputs else None) or EMPTY_DEPSET
        ),
        product_path = (
            direct_outputs.product_path if direct_outputs else None
        ),
        swift_generated_header = swift_generated_header,
    )

# Other

def _dicts_from_xcode_configurations(*, infos_per_xcode_configuration):
    """Creates `xcode_target`s `dicts` from multiple Xcode configurations.

    Args:
        infos_per_xcode_configuration: A `dict` mapping Xcode configuration
            names to a `list` of `XcodeProjInfo`s.

    Returns:
        A `tuple` with three elements:

        *   A `dict` mapping `xcode_target.id` to `xcode_target`s.
        *   A `dict` mapping `xcode_target.label` to a `dict` mapping
            `xcode_target.id` to `xcode_target`s.
        *   A `dict` mapping `xcode_target.id` to a `list` of Xcode
            configuration names that the target is present in.
    """
    xcode_targets = {}
    xcode_targets_by_label = {}
    xcode_target_configurations = {}
    for xcode_configuration, infos in infos_per_xcode_configuration.items():
        configuration_xcode_targets = {
            xcode_target.id: xcode_target
            for xcode_target in depset(
                transitive = [info.xcode_targets for info in infos],
            ).to_list()
        }
        xcode_targets.update(configuration_xcode_targets)
        for xcode_target in configuration_xcode_targets.values():
            id = xcode_target.id
            xcode_targets_by_label.setdefault(xcode_target.label, {})[id] = (
                xcode_target
            )
            xcode_target_configurations.setdefault(id, []).append(
                xcode_configuration,
            )

    return (xcode_targets, xcode_targets_by_label, xcode_target_configurations)

xcode_targets = struct(
    dicts_from_xcode_configurations = _dicts_from_xcode_configurations,
    make = _make_xcode_target,
)
