# `PBXNativeTarget`s `PBXProj` partials generator

The `pbxnativetargets` generator creates two or more files:

- A `PBXProj` partial containing all of the `PBXNativeTarget` related elements:
  - `PBXNativeTarget`
  - `XCBuildConfiguration`
  - `XCBuildConfigurationList`
  - and various build phases
- A file that maps `PBXBuildFile` identifiers to file paths
- A directory containing zero or more automatic `.xcsheme`s

Each `pbxnativetargets` invocation might process a subset of all targets. All
targets that share the same name will be processed by the same invocation. This
is to enable target disambiguation (using the full label as the Xcode target
name when multiple targets share the same target name).

## Inputs

The generator accepts the following command-line arguments (see
[`Arguments.swift`](src/Generator/Arguments.swift) and
[`PBXNativeTargets.swift`](src/PBXNativeTargets.swift) for more details):

- Positional `targets-output-path`
- Positional `buildfile-map-output-path`
- Positional `xcshemes-output-directory`
- Positional `consolidation-map`
- Optional option `--hosted-targets <host-target> <hosted-target> ...`
- Option `--targets <target> ...`
- Option `--product-types <product-types> ...`
- Option `--product-paths <product-path> ...`
- Option `--platforms <platform> ...`
- Option `--os-versions <os-version> ...`
- Option `--archs <arch> ...`
- Optional option `--srcs-counts <srcs-count> ...`
- Optional option `--srcs <srcs> ...`
- Optional option `--non-arc-srcs-counts <non-arc-srcs-count> ...`
- Optional option `--non-arc-srcs <non-arc-srcs> ...`
- Optional option `--hdrs-counts <hdrs-count> ...`
- Optional option `--hdrs <hdrs> ...`
- Optional option `--resources-counts <resources-count> ...`
- Optional option `--resources <resources> ...`
- Optional option `--folder-resources-counts <folder-resources-count> ...`
- Optional option `--folder-resources <folder-resources> ...`
- Option `--output-product-filenames <output-product-filename> ...`
- Option `--dysm-paths <dysm-path> ...`
- Flag `--colorize`

Here is an example invocation:

```shell
$ pbxnativetargets \
    /tmp/pbxproj_partials/pbxnativetargets/0 \
    /tmp/pbxproj_partials/buildfile_maps/0 \
    /tmp/pbxproj_partials/automatic_xcschemes/0 \
    /tmp/pbxproj_partials/consolidation_maps/0 \
    --targets \
    //tools/generators/legacy:generator applebin_macos-darwin_x86_64-dbg-STABLE-3 \
    //tools/generators/legacy/test:tests.__internal__.__test_bundle applebin_macos-darwin_x86_64-dbg-STABLE-3 \
    //tools/generators/legacy:generator.library macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1 \
    --product-types \
    com.apple.product-type.tool \
    com.apple.product-type.bundle.unit-test \
    com.apple.product-type.library.static \
    --product-paths \
    bazel-out/applebin_macos-darwin_x86_64-dbg-STABLE-3/bin/tools/generators/legacy/generator \
    bazel-out/applebin_macos-darwin_x86_64-dbg-STABLE-3/bin/tools/generators/legacy/test/tests.__internal__.__test_bundle_archive-root/tests.xctest \
    bazel-out/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-STABLE-1/bin/tools/generators/legacy/libgenerator.library.a \
    --platforms \
    macosx \
    macosx \
    macosx \
    --os-versions \
    12.0 \
    12.0 \
    12.0 \
    --archs \
    x86_64 \
    x86_64 \
    x86_64 \
    --srcs-counts \
    0 \
    2 \
    3 \
    --srcs \
    tools/generators/legacy/test/AddTargetsTests.swift \
    tools/generators/legacy/test/Array+ExtensionsTests.swift \
    tools/generators/legacy/src/BuildSettingConditional.swift \
    tools/generators/legacy/src/DTO/BazelLabel.swift \
    tools/generators/legacy/src/DTO/BuildSetting.swift \
    --output-product-filenames \
    generator_codesigned \
    tests.xctest \
    "" \
    --dsym-paths \
    "" \
    "" \
    ""
```

## Output

Here is an example output:

### `pbxnativetargets`

```

```

### `consolidation_maps/1`

```

```
