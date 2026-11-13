#!/usr/bin/env python3
"""Generates a valid Xcode 15/16 project.pbxproj for iCleanerPro and iCleanerProTests."""

from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
APP_DIR = ROOT / "iCleanerPro"
TEST_DIR = ROOT / "iCleanerProTests"

ID_PROJECT = "A00000010000000000000001"
ID_MAIN_GROUP = "A00000010000000000000002"
ID_PRODUCTS_GROUP = "A00000010000000000000003"
ID_APP_PRODUCT = "A00000010000000000000004"
ID_TEST_PRODUCT = "A00000010000000000000005"
ID_TARGET_APP = "A10000010000000000000001"
ID_TARGET_TEST = "A10000010000000000000002"

ID_APP_SOURCES_PHASE = "A20000010000000000000001"
ID_APP_FRAMEWORKS_PHASE = "A20000010000000000000002"
ID_APP_RESOURCES_PHASE = "A20000010000000000000003"
ID_TEST_SOURCES_PHASE = "A20000010000000000000004"
ID_TEST_FRAMEWORKS_PHASE = "A20000010000000000000005"
ID_TEST_RESOURCES_PHASE = "A20000010000000000000006"
ID_TARGET_DEP = "A20000010000000000000007"
ID_CONTAINER_PROXY = "A20000010000000000000008"

ID_PROJ_CFG_LIST = "A30000010000000000000001"
ID_PROJ_CFG_DEBUG = "A30000010000000000000002"
ID_PROJ_CFG_RELEASE = "A30000010000000000000003"
ID_APP_CFG_LIST = "A30000010000000000000004"
ID_APP_CFG_DEBUG = "A30000010000000000000005"
ID_APP_CFG_RELEASE = "A30000010000000000000006"
ID_TEST_CFG_LIST = "A30000010000000000000007"
ID_TEST_CFG_DEBUG = "A30000010000000000000008"
ID_TEST_CFG_RELEASE = "A30000010000000000000009"


def main() -> None:
    app_swift = sorted(APP_DIR.rglob("*.swift"))
    test_swift = sorted(TEST_DIR.rglob("*.swift"))

    seq = 1

    def next_id(prefix: str = "B") -> str:
        nonlocal seq
        val = f"{prefix}{seq:023X}"
        seq += 1
        return val

    file_refs = []
    build_files = []
    app_sources_ids = []
    app_resources_ids = []
    test_sources_ids = []

    groups: dict[str, dict] = {}

    def ensure_group(rel_path: Path) -> str:
        key = rel_path.as_posix()
        if key in groups:
            return groups[key]["id"]
        gid = next_id("C")
        groups[key] = {"id": gid, "name": rel_path.name, "path": rel_path.name, "children": []}
        if rel_path.parent != Path("."):
            ensure_group(rel_path.parent)
            groups[rel_path.parent.as_posix()]["children"].append((gid, rel_path.name))
        return gid

    ensure_group(Path("iCleanerPro"))
    ensure_group(Path("iCleanerProTests"))

    for sf in app_swift:
        rel = sf.relative_to(ROOT)
        ensure_group(rel.parent)
        fid = next_id("F")
        bid = next_id("D")
        file_refs.append((fid, sf.name, sf.name, "sourcecode.swift"))
        build_files.append((bid, fid, sf.name, "Sources"))
        app_sources_ids.append((bid, sf.name))
        groups[rel.parent.as_posix()]["children"].append((fid, sf.name))

    for sf in test_swift:
        rel = sf.relative_to(ROOT)
        ensure_group(rel.parent)
        fid = next_id("F")
        bid = next_id("D")
        file_refs.append((fid, sf.name, sf.name, "sourcecode.swift"))
        build_files.append((bid, fid, sf.name, "Sources"))
        test_sources_ids.append((bid, sf.name))
        groups[rel.parent.as_posix()]["children"].append((fid, sf.name))

    res_specs = [
        (Path("iCleanerPro/Assets.xcassets"), "folder.assetcatalog", True),
        (Path("iCleanerPro/Resources/Localizable.strings"), "text.plist.strings", True),
        (Path("iCleanerPro/Info.plist"), "text.plist.xml", False),
        (Path("iCleanerPro/iCleanerPro.entitlements"), "text.plist.entitlements", False),
    ]
    for rel, ftype, in_resources in res_specs:
        ensure_group(rel.parent)
        fid = next_id("F")
        file_refs.append((fid, rel.name, rel.name, ftype))
        groups[rel.parent.as_posix()]["children"].append((fid, rel.name))
        if in_resources:
            bid = next_id("D")
            build_files.append((bid, fid, rel.name, "Resources"))
            app_resources_ids.append((bid, rel.name))

    lines = [
        "// !$*UTF8*$!",
        "{",
        "\tarchiveVersion = 1;",
        "\tclasses = {",
        "\t};",
        "\tobjectVersion = 56;",
        "\tobjects = {",
        "/* Begin PBXBuildFile section */",
    ]
    for bid, fid, name, phase in build_files:
        lines.append(
            f"\t\t{bid} /* {name} in {phase} */ = {{isa = PBXBuildFile; fileRef = {fid} /* {name} */; }};"
        )
    lines.extend([
        "/* End PBXBuildFile section */",
        "",
        "/* Begin PBXContainerItemProxy section */",
        f"\t\t{ID_CONTAINER_PROXY} /* PBXContainerItemProxy */ = {{",
        "\t\t\tisa = PBXContainerItemProxy;",
        f"\t\t\tcontainerPortal = {ID_PROJECT} /* Project object */;",
        "\t\t\tproxyType = 1;",
        f"\t\t\tremoteGlobalIDString = {ID_TARGET_APP};",
        "\t\t\tremoteInfo = iCleanerPro;",
        "\t\t};",
        "/* End PBXContainerItemProxy section */",
        "",
        "/* Begin PBXFileReference section */",
        f"\t\t{ID_APP_PRODUCT} /* iCleanerPro.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = iCleanerPro.app; sourceTree = BUILT_PRODUCTS_DIR; }};",
        f"\t\t{ID_TEST_PRODUCT} /* iCleanerProTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = iCleanerProTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};",
    ])
    for fid, name, path, ftype in file_refs:
        lines.append(
            f'\t\t{fid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; path = {path}; sourceTree = "<group>"; }};'
        )
    lines.extend([
        "/* End PBXFileReference section */",
        "",
        "/* Begin PBXFrameworksBuildPhase section */",
        f"\t\t{ID_APP_FRAMEWORKS_PHASE} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};",
        f"\t\t{ID_TEST_FRAMEWORKS_PHASE} /* Frameworks */ = {{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};",
        "/* End PBXFrameworksBuildPhase section */",
        "",
        "/* Begin PBXGroup section */",
        f"\t\t{ID_MAIN_GROUP} = {{",
        "\t\t\tisa = PBXGroup;",
        "\t\t\tchildren = (",
        f'\t\t\t\t{groups["iCleanerPro"]["id"]} /* iCleanerPro */,',
        f'\t\t\t\t{groups["iCleanerProTests"]["id"]} /* iCleanerProTests */,',
        f"\t\t\t\t{ID_PRODUCTS_GROUP} /* Products */,",
        "\t\t\t);",
        '\t\t\tsourceTree = "<group>";',
        "\t\t};",
        f"\t\t{ID_PRODUCTS_GROUP} /* Products */ = {{",
        "\t\t\tisa = PBXGroup;",
        "\t\t\tchildren = (",
        f"\t\t\t\t{ID_APP_PRODUCT} /* iCleanerPro.app */,",
        f"\t\t\t\t{ID_TEST_PRODUCT} /* iCleanerProTests.xctest */,",
        "\t\t\t);",
        "\t\t\tname = Products;",
        '\t\t\tsourceTree = "<group>";',
        "\t\t};",
    ])
    for key in sorted(groups.keys()):
        g = groups[key]
        lines.append(f'\t\t{g["id"]} /* {g["name"]} */ = {{')
        lines.append("\t\t\tisa = PBXGroup;")
        lines.append("\t\t\tchildren = (")
        for cid, cname in g["children"]:
            lines.append(f"\t\t\t\t{cid} /* {cname} */,")
        lines.append("\t\t\t);")
        lines.append(f'\t\t\tpath = {g["path"]};')
        lines.append('\t\t\tsourceTree = "<group>";')
        lines.append("\t\t};")
    lines.extend([
        "/* End PBXGroup section */",
        "",
        "/* Begin PBXNativeTarget section */",
        f"\t\t{ID_TARGET_APP} /* iCleanerPro */ = {{",
        "\t\t\tisa = PBXNativeTarget;",
        f'\t\t\tbuildConfigurationList = {ID_APP_CFG_LIST} /* Build configuration list for PBXNativeTarget "iCleanerPro" */;',
        "\t\t\tbuildPhases = (",
        f"\t\t\t\t{ID_APP_SOURCES_PHASE} /* Sources */,",
        f"\t\t\t\t{ID_APP_FRAMEWORKS_PHASE} /* Frameworks */,",
        f"\t\t\t\t{ID_APP_RESOURCES_PHASE} /* Resources */,",
        "\t\t\t);",
        "\t\t\tbuildRules = ();",
        "\t\t\tdependencies = ();",
        "\t\t\tname = iCleanerPro;",
        "\t\t\tproductName = iCleanerPro;",
        f"\t\t\tproductReference = {ID_APP_PRODUCT} /* iCleanerPro.app */;",
        '\t\t\tproductType = "com.apple.product-type.application";',
        "\t\t};",
        f"\t\t{ID_TARGET_TEST} /* iCleanerProTests */ = {{",
        "\t\t\tisa = PBXNativeTarget;",
        f'\t\t\tbuildConfigurationList = {ID_TEST_CFG_LIST} /* Build configuration list for PBXNativeTarget "iCleanerProTests" */;',
        "\t\t\tbuildPhases = (",
        f"\t\t\t\t{ID_TEST_SOURCES_PHASE} /* Sources */,",
        f"\t\t\t\t{ID_TEST_FRAMEWORKS_PHASE} /* Frameworks */,",
        f"\t\t\t\t{ID_TEST_RESOURCES_PHASE} /* Resources */,",
        "\t\t\t);",
        "\t\t\tbuildRules = ();",
        f"\t\t\tdependencies = ({ID_TARGET_DEP} /* PBXTargetDependency */,);",
        "\t\t\tname = iCleanerProTests;",
        "\t\t\tproductName = iCleanerProTests;",
        f"\t\t\tproductReference = {ID_TEST_PRODUCT} /* iCleanerProTests.xctest */;",
        '\t\t\tproductType = "com.apple.product-type.bundle.unit-test";',
        "\t\t};",
        "/* End PBXNativeTarget section */",
        "",
        "/* Begin PBXProject section */",
        f"\t\t{ID_PROJECT} /* Project object */ = {{",
        "\t\t\tisa = PBXProject;",
        "\t\t\tattributes = {",
        "\t\t\t\tBuildIndependentTargetsInParallel = 1;",
        "\t\t\t\tLastSwiftUpdateCheck = 1540;",
        "\t\t\t\tLastUpgradeCheck = 1540;",
        "\t\t\t\tTargetAttributes = {",
        f"\t\t\t\t\t{ID_TARGET_APP} = {{CreatedOnToolsVersion = 15.4; }};",
        f"\t\t\t\t\t{ID_TARGET_TEST} = {{CreatedOnToolsVersion = 15.4; TestTargetID = {ID_TARGET_APP}; }};",
        "\t\t\t\t};",
        "\t\t\t};",
        f'\t\t\tbuildConfigurationList = {ID_PROJ_CFG_LIST} /* Build configuration list for PBXProject "iCleanerPro" */;',
        '\t\t\tcompatibilityVersion = "Xcode 14.0";',
        "\t\t\tdevelopmentRegion = vi;",
        "\t\t\thasScannedForEncodings = 0;",
        "\t\t\tknownRegions = (vi, en, Base);",
        f"\t\t\tmainGroup = {ID_MAIN_GROUP};",
        f"\t\t\tproductRefGroup = {ID_PRODUCTS_GROUP} /* Products */;",
        '\t\t\tprojectDirPath = "";',
        '\t\t\tprojectRoot = "";',
        f"\t\t\ttargets = ({ID_TARGET_APP} /* iCleanerPro */, {ID_TARGET_TEST} /* iCleanerProTests */,);",
        "\t\t};",
        "/* End PBXProject section */",
        "",
        "/* Begin PBXResourcesBuildPhase section */",
        f"\t\t{ID_APP_RESOURCES_PHASE} /* Resources */ = {{",
        "\t\t\tisa = PBXResourcesBuildPhase;",
        "\t\t\tbuildActionMask = 2147483647;",
        "\t\t\tfiles = (",
    ])
    for bid, name in app_resources_ids:
        lines.append(f"\t\t\t\t{bid} /* {name} in Resources */,")
    lines.extend([
        "\t\t\t);",
        "\t\t\trunOnlyForDeploymentPostprocessing = 0;",
        "\t\t};",
        f"\t\t{ID_TEST_RESOURCES_PHASE} /* Resources */ = {{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }};",
        "/* End PBXResourcesBuildPhase section */",
        "",
        "/* Begin PBXSourcesBuildPhase section */",
        f"\t\t{ID_APP_SOURCES_PHASE} /* Sources */ = {{",
        "\t\t\tisa = PBXSourcesBuildPhase;",
        "\t\t\tbuildActionMask = 2147483647;",
        "\t\t\tfiles = (",
    ])
    for bid, name in app_sources_ids:
        lines.append(f"\t\t\t\t{bid} /* {name} in Sources */,")
    lines.extend([
        "\t\t\t);",
        "\t\t\trunOnlyForDeploymentPostprocessing = 0;",
        "\t\t};",
        f"\t\t{ID_TEST_SOURCES_PHASE} /* Sources */ = {{",
        "\t\t\tisa = PBXSourcesBuildPhase;",
        "\t\t\tbuildActionMask = 2147483647;",
        "\t\t\tfiles = (",
    ])
    for bid, name in test_sources_ids:
        lines.append(f"\t\t\t\t{bid} /* {name} in Sources */,")
    lines.extend([
        "\t\t\t);",
        "\t\t\trunOnlyForDeploymentPostprocessing = 0;",
        "\t\t};",
        "/* End PBXSourcesBuildPhase section */",
        "",
        "/* Begin PBXTargetDependency section */",
        f"\t\t{ID_TARGET_DEP} /* PBXTargetDependency */ = {{",
        "\t\t\tisa = PBXTargetDependency;",
        f"\t\t\ttarget = {ID_TARGET_APP} /* iCleanerPro */;",
        f"\t\t\ttargetProxy = {ID_CONTAINER_PROXY} /* PBXContainerItemProxy */;",
        "\t\t};",
        "/* End PBXTargetDependency section */",
        "",
        "/* Begin XCBuildConfiguration section */",
    ])

    proj_debug = """\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCODE_SIGN_STYLE = Manual;
\t\t\t\tCODE_SIGNING_ALLOWED = NO;
\t\t\t\tCODE_SIGNING_REQUIRED = NO;
\t\t\t\tCODE_SIGN_IDENTITY = "";
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";"""

    proj_release = """\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCODE_SIGN_STYLE = Manual;
\t\t\t\tCODE_SIGNING_ALLOWED = NO;
\t\t\t\tCODE_SIGNING_REQUIRED = NO;
\t\t\t\tCODE_SIGN_IDENTITY = "";
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tVALIDATE_PRODUCT = YES;"""

    app_common = """\t\t\t\tAD_HOC_CODE_SIGNING_ALLOWED = YES;
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCODE_SIGN_IDENTITY = "";
\t\t\t\tCODE_SIGN_STYLE = Manual;
\t\t\t\tCODE_SIGNING_ALLOWED = NO;
\t\t\t\tCODE_SIGNING_REQUIRED = NO;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = iCleanerPro/Info.plist;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks");
\t\t\t\tMARKETING_VERSION = 1.0.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.icleanerpro.app;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
\t\t\t\tSUPPORTS_MACCATALYST = NO;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";"""

    test_common = """\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCODE_SIGN_IDENTITY = "";
\t\t\t\tCODE_SIGN_STYLE = Manual;
\t\t\t\tCODE_SIGNING_ALLOWED = NO;
\t\t\t\tCODE_SIGNING_REQUIRED = NO;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tMARKETING_VERSION = 1.0.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.icleanerpro.app.tests;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/iCleanerPro.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/iCleanerPro";"""

    configs = [
        (ID_PROJ_CFG_DEBUG, "Debug", proj_debug),
        (ID_PROJ_CFG_RELEASE, "Release", proj_release),
        (ID_APP_CFG_DEBUG, "Debug", app_common),
        (ID_APP_CFG_RELEASE, "Release", app_common),
        (ID_TEST_CFG_DEBUG, "Debug", test_common),
        (ID_TEST_CFG_RELEASE, "Release", test_common),
    ]
    for cid, cname, settings in configs:
        lines.append(f"\t\t{cid} /* {cname} */ = {{")
        lines.append("\t\t\tisa = XCBuildConfiguration;")
        lines.append("\t\t\tbuildSettings = {")
        lines.append(settings)
        lines.append("\t\t\t};")
        lines.append(f"\t\t\tname = {cname};")
        lines.append("\t\t};")

    lines.extend([
        "/* End XCBuildConfiguration section */",
        "",
        "/* Begin XCConfigurationList section */",
        f"\t\t{ID_PROJ_CFG_LIST} = {{isa = XCConfigurationList; buildConfigurations = ({ID_PROJ_CFG_DEBUG} /* Debug */, {ID_PROJ_CFG_RELEASE} /* Release */); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};",
        f"\t\t{ID_APP_CFG_LIST} = {{isa = XCConfigurationList; buildConfigurations = ({ID_APP_CFG_DEBUG} /* Debug */, {ID_APP_CFG_RELEASE} /* Release */); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};",
        f"\t\t{ID_TEST_CFG_LIST} = {{isa = XCConfigurationList; buildConfigurations = ({ID_TEST_CFG_DEBUG} /* Debug */, {ID_TEST_CFG_RELEASE} /* Release */); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};",
        "/* End XCConfigurationList section */",
        "\t};",
        f"\trootObject = {ID_PROJECT} /* Project object */;",
        "}",
    ])

    out_pbx = ROOT / "iCleanerPro.xcodeproj" / "project.pbxproj"
    out_pbx.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Generated {out_pbx} with {len(app_swift)} app files and {len(test_swift)} test files.")


if __name__ == "__main__":
    main()
