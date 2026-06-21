#!/usr/bin/env python3
"""
Generates the SpaceSaver.xcodeproj project file.
Run from the project root: python3 generate_project.py
"""

import os
import uuid

SRC_DIR = "SpaceSaver"
PRODUCT_NAME = "SpaceSaver"
BUNDLE_ID = "com.spacesaver.app"
MIN_MACOS = "13.0"

SOURCE_GROUPS = {
    "SpaceSaver": [
        "SpaceSaverApp.swift",
        "ContentView.swift",
    ],
    "Models": [
        "DiskInfo.swift",
        "ScanResult.swift",
        "CacheCategory.swift",
    ],
    "ViewModels": [
        "DashboardViewModel.swift",
        "LargeFilesViewModel.swift",
        "DuplicateViewModel.swift",
        "CacheCleanerViewModel.swift",
        "TrashViewModel.swift",
        "DownloadsViewModel.swift",
        "AppUninstallerViewModel.swift",
        "LoginItemsViewModel.swift",
    ],
    "Views": [
        "DashboardView.swift",
        "LargeFilesView.swift",
        "DuplicateFinderView.swift",
        "CacheCleanerView.swift",
        "CacheCategoryDetailView.swift",
        "TrashManagerView.swift",
        "DownloadsCleanerView.swift",
        "AppUninstallerView.swift",
        "LoginItemsView.swift",
    ],
    "Views/Components": [
        "FileSizeFormatter.swift",
        "ConfirmDeleteView.swift",
        "ProgressView+.swift",
    ],
    "Utilities": [
        "DiskUsage.swift",
        "FileScanner.swift",
        "CacheLocator.swift",
    ],
}

class ID:
    _used = set()
    @staticmethod
    def new():
        while True:
            uid = uuid.uuid4().hex[:24].upper()
            if uid not in ID._used:
                ID._used.add(uid)
                return uid


def main():
    ids = {}
    # Generate all needed IDs
    ids['PROJECT'] = ID.new()
    ids['MAIN_GROUP'] = ID.new()
    ids['PRODUCTS_GROUP'] = ID.new()
    ids['TARGET'] = ID.new()
    ids['CONFIG_LIST_PROJECT'] = ID.new()
    ids['CONFIG_LIST_TARGET'] = ID.new()
    ids['DEBUG_CONFIG_PROJECT'] = ID.new()
    ids['RELEASE_CONFIG_PROJECT'] = ID.new()
    ids['DEBUG_CONFIG_TARGET'] = ID.new()
    ids['RELEASE_CONFIG_TARGET'] = ID.new()
    ids['PRODUCT_REF'] = ID.new()
    ids['BUILD_PHASE_SOURCES'] = ID.new()
    ids['BUILD_PHASE_FRAMEWORKS'] = ID.new()
    ids['BUILD_PHASE_RESOURCES'] = ID.new()
    ids['ASSET_CATALOG_FILE_REF'] = ID.new()
    ids['ASSET_CATALOG_BUILD_FILE'] = ID.new()
    ids['INFOPLIST_FILE_REF'] = ID.new()
    ids['ENTITLEMENTS_FILE_REF'] = ID.new()

    for group_name, files in SOURCE_GROUPS.items():
        ids[f'group_{group_name}'] = ID.new()
        for f in files:
            ids[f'fileref_{f}'] = ID.new()
            ids[f'buildfile_{f}'] = ID.new()

    # Build the pbxproj content
    L = []  # lines

    def w(s=""):
        L.append(s)

    w("// !$*UTF8*$!")
    w("{")
    w("\tarchiveVersion = 1;")
    w("\tclasses = {")
    w("\t};")
    w("\tobjectVersion = 56;")
    w("\tobjects = {")
    w()

    # PBXBuildFile
    w("/* Begin PBXBuildFile section */")
    for group_name, files in SOURCE_GROUPS.items():
        for f in files:
            w(f"\t\t{ids[f'buildfile_{f}']} /* {f} in Sources */ = {{isa = PBXBuildFile; fileRef = {ids[f'fileref_{f}']} /* {f} */; }};")
    w(f"\t\t{ids['ASSET_CATALOG_BUILD_FILE']} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {ids['ASSET_CATALOG_FILE_REF']} /* Assets.xcassets */; }};")
    w("/* End PBXBuildFile section */")
    w()

    # PBXFileReference
    w("/* Begin PBXFileReference section */")
    w(f"\t\t{ids['PRODUCT_REF']} /* {PRODUCT_NAME}.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = {PRODUCT_NAME}.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
    for group_name, files in SOURCE_GROUPS.items():
        for f in files:
            # Quote path if it contains characters illegal in unquoted NeXTSTEP strings (e.g. "+")
            path_val = f'"{f}"' if not all(c.isalnum() or c in "._-" for c in f) else f
            w(f"\t\t{ids[f'fileref_{f}']} /* {f} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {path_val}; sourceTree = \"<group>\"; }};")
    w(f"\t\t{ids['INFOPLIST_FILE_REF']} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; }};")
    w(f"\t\t{ids['ENTITLEMENTS_FILE_REF']} /* Entitlements.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Entitlements.plist; sourceTree = \"<group>\"; }};")
    w(f"\t\t{ids['ASSET_CATALOG_FILE_REF']} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = \"<group>\"; }};")
    w("/* End PBXFileReference section */")
    w()

    # PBXGroup
    w("/* Begin PBXGroup section */")

    # Main group
    w(f"\t\t{ids['MAIN_GROUP']} /* Main */ = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    w(f"\t\t\t\t{ids['group_SpaceSaver']},")
    w(f"\t\t\t\t{ids['PRODUCTS_GROUP']},")
    w("\t\t\t);")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")

    # Products group
    w(f"\t\t{ids['PRODUCTS_GROUP']} /* Products */ = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")
    w(f"\t\t\t\t{ids['PRODUCT_REF']} /* {PRODUCT_NAME}.app */,")
    w("\t\t\t);")
    w("\t\t\tname = Products;")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")

    # Source groups
    # We need the SpaceSaver group to include both source files and sub-groups
    # First, determine the structure:
    # SpaceSaver/ contains: SpaceSaverApp.swift, ContentView.swift, Info.plist, Entitlements.plist, Assets.xcassets
    # and sub-groups: Models, ViewModels, Views, Utilities

    # Actually, let's simplify: make one big flat group under SpaceSaver
    # Xcode will show the folder structure from the filesystem

    w(f"\t\t{ids['group_SpaceSaver']} /* {SRC_DIR} */ = {{")
    w("\t\t\tisa = PBXGroup;")
    w("\t\t\tchildren = (")

    # Add only the files that belong directly to the SpaceSaver root group
    for f in SOURCE_GROUPS["SpaceSaver"]:
        w(f"\t\t\t\t{ids[f'fileref_{f}']} /* {f} */,")

    # Add sub-group refs (each sub-group contains its own files)
    for group_name in SOURCE_GROUPS:
        if group_name != "SpaceSaver":
            group_display = f'"{group_name}"' if "/" in group_name else group_name
            w(f"\t\t\t\t{ids[f'group_{group_name}']} /* {group_display} */,")

    # Add Info.plist, Entitlements, Assets
    w(f"\t\t\t\t{ids['INFOPLIST_FILE_REF']} /* Info.plist */,")
    w(f"\t\t\t\t{ids['ENTITLEMENTS_FILE_REF']} /* Entitlements.plist */,")
    w(f"\t\t\t\t{ids['ASSET_CATALOG_FILE_REF']} /* Assets.xcassets */,")
    w("\t\t\t);")
    w(f"\t\t\tpath = {SRC_DIR};")
    w("\t\t\tsourceTree = \"<group>\";")
    w("\t\t};")

    # Sub-groups
    for group_name, files in SOURCE_GROUPS.items():
        if group_name == "SpaceSaver":
            continue
        w(f"\t\t{ids[f'group_{group_name}']} /* {group_name} */ = {{")
        w("\t\t\tisa = PBXGroup;")
        w("\t\t\tchildren = (")
        for f in files:
            w(f"\t\t\t\t{ids[f'fileref_{f}']} /* {f} */,")
        w("\t\t\t);")
        # Quote the name if it contains special characters (e.g., "/" in "Views/Components")
        group_display = f'"{group_name}"' if "/" in group_name else group_name
        w(f"\t\t\tname = {group_display};")
        # Path is relative to the parent "SpaceSaver" group, so just the folder name
        w(f"\t\t\tpath = \"{group_name}\";")
        w("\t\t\tsourceTree = \"<group>\";")
        w("\t\t};")

    w("/* End PBXGroup section */")
    w()

    # PBXNativeTarget
    w("/* Begin PBXNativeTarget section */")
    w(f"\t\t{ids['TARGET']} /* {PRODUCT_NAME} */ = {{")
    w("\t\t\tisa = PBXNativeTarget;")
    w(f"\t\t\tbuildConfigurationList = {ids['CONFIG_LIST_TARGET']};")
    w("\t\t\tbuildPhases = (")
    w(f"\t\t\t\t{ids['BUILD_PHASE_SOURCES']} /* Sources */,")
    w(f"\t\t\t\t{ids['BUILD_PHASE_FRAMEWORKS']} /* Frameworks */,")
    w(f"\t\t\t\t{ids['BUILD_PHASE_RESOURCES']} /* Resources */,")
    w("\t\t\t);")
    w("\t\t\tbuildRules = (")
    w("\t\t\t);")
    w("\t\t\tdependencies = (")
    w("\t\t\t);")
    w(f"\t\t\tname = {PRODUCT_NAME};")
    w(f"\t\t\tproductName = {PRODUCT_NAME};")
    w(f"\t\t\tproductReference = {ids['PRODUCT_REF']} /* {PRODUCT_NAME}.app */;")
    w("\t\t\tproductType = \"com.apple.product-type.application\";")
    w("\t\t};")
    w("/* End PBXNativeTarget section */")
    w()

    # PBXProject
    w("/* Begin PBXProject section */")
    w(f"\t\t{ids['PROJECT']} /* Project object */ = {{")
    w("\t\t\tisa = PBXProject;")
    w("\t\t\tattributes = {")
    w("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    w("\t\t\t\tLastSwiftUpdateCheck = 1500;")
    w("\t\t\t\tLastUpgradeCheck = 1500;")
    w("\t\t\t\tTargetAttributes = {")
    w(f"\t\t\t\t\t{ids['TARGET']} = {{")
    w("\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;")
    w("\t\t\t\t\t};")
    w("\t\t\t\t};")
    w("\t\t\t};")
    w(f"\t\t\tbuildConfigurationList = {ids['CONFIG_LIST_PROJECT']};")
    w("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
    w("\t\t\tdevelopmentRegion = en;")
    w("\t\t\thasScannedForEncodings = 0;")
    w("\t\t\tknownRegions = (")
    w("\t\t\t\ten,")
    w("\t\t\t\tBase,")
    w("\t\t\t);")
    w(f"\t\t\tmainGroup = {ids['MAIN_GROUP']};")
    w(f"\t\t\tproductRefGroup = {ids['PRODUCTS_GROUP']} /* Products */;")
    w("\t\t\tprojectDirPath = \"\";")
    w("\t\t\tprojectRoot = \"\";")
    w("\t\t\ttargets = (")
    w(f"\t\t\t\t{ids['TARGET']} /* {PRODUCT_NAME} */,")
    w("\t\t\t);")
    w("\t\t};")
    w("/* End PBXProject section */")
    w()

    # PBXResourcesBuildPhase
    w("/* Begin PBXResourcesBuildPhase section */")
    w(f"\t\t{ids['BUILD_PHASE_RESOURCES']} /* Resources */ = {{")
    w("\t\t\tisa = PBXResourcesBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (")
    w(f"\t\t\t\t{ids['ASSET_CATALOG_BUILD_FILE']} /* Assets.xcassets in Resources */,")
    w("\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")
    w("/* End PBXResourcesBuildPhase section */")
    w()

    # PBXSourcesBuildPhase
    w("/* Begin PBXSourcesBuildPhase section */")
    w(f"\t\t{ids['BUILD_PHASE_SOURCES']} /* Sources */ = {{")
    w("\t\t\tisa = PBXSourcesBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (")
    for group_name, files in SOURCE_GROUPS.items():
        for f in files:
            w(f"\t\t\t\t{ids[f'buildfile_{f}']} /* {f} in Sources */,")
    w("\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")
    w("/* End PBXSourcesBuildPhase section */")
    w()

    # PBXFrameworksBuildPhase
    w("/* Begin PBXFrameworksBuildPhase section */")
    w(f"\t\t{ids['BUILD_PHASE_FRAMEWORKS']} /* Frameworks */ = {{")
    w("\t\t\tisa = PBXFrameworksBuildPhase;")
    w("\t\t\tbuildActionMask = 2147483647;")
    w("\t\t\tfiles = (")
    w("\t\t\t);")
    w("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    w("\t\t};")
    w("/* End PBXFrameworksBuildPhase section */")
    w()

    # XCBuildConfiguration - common project-level settings
    project_debug_settings = {
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "CLANG_ANALYZER_NONNULL": "YES",
        "CLANG_CXX_LANGUAGE_STANDARD": "\"gnu++20\"",
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "CLANG_ENABLE_OBJC_WEAK": "YES",
        "CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING": "YES",
        "CLANG_WARN_BOOL_CONVERSION": "YES",
        "CLANG_WARN_COMMA": "YES",
        "CLANG_WARN_CONSTANT_CONVERSION": "YES",
        "CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS": "YES",
        "CLANG_WARN_DIRECT_OBJC_ISA_USAGE": "YES_ERROR",
        "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
        "CLANG_WARN_EMPTY_BODY": "YES",
        "CLANG_WARN_ENUM_CONVERSION": "YES",
        "CLANG_WARN_INFINITE_RECURSION": "YES",
        "CLANG_WARN_INT_CONVERSION": "YES",
        "CLANG_WARN_NON_LITERAL_NULL_CONVERSION": "YES",
        "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF": "YES",
        "CLANG_WARN_OBJC_LITERAL_CONVERSION": "YES",
        "CLANG_WARN_OBJC_ROOT_CLASS": "YES_ERROR",
        "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER": "YES",
        "CLANG_WARN_RANGE_LOOP_ANALYSIS": "YES",
        "CLANG_WARN_STRICT_PROTOTYPES": "YES",
        "CLANG_WARN_SUSPICIOUS_MOVE": "YES",
        "CLANG_WARN_UNGUARDED_AVAILABILITY": "YES",
        "CLANG_WARN_UNREACHABLE_CODE": "YES",
        "CLANG_WARN__DUPLICATE_METHOD_MATCH": "YES",
        "COPY_PHASE_STRIP": "NO",
        "DEBUG_INFORMATION_FORMAT": "dwarf",
        "ENABLE_STRICT_OBJC_MSGSEND": "YES",
        "ENABLE_TESTABILITY": "YES",
        "GCC_DYNAMIC_NO_PIC": "NO",
        "GCC_NO_COMMON_BLOCKS": "YES",
        "GCC_OPTIMIZATION_LEVEL": "0",
        "GCC_PREPROCESSOR_DEFINITIONS": ["DEBUG=1", "$(inherited)"],
        "GCC_WARN_64_TO_32_BIT_CONVERSION": "YES",
        "GCC_WARN_ABOUT_RETURN_TYPE": "YES_ERROR",
        "GCC_WARN_UNDECLARED_SELECTOR": "YES",
        "GCC_WARN_UNINITIALIZED_AUTOS": "YES_AGGRESSIVE",
        "GCC_WARN_UNUSED_FUNCTION": "YES",
        "GCC_WARN_UNUSED_VARIABLE": "YES",
        "MACOSX_DEPLOYMENT_TARGET": MIN_MACOS,
        "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
        "MTL_FAST_MATH": "YES",
        "ONLY_ACTIVE_ARCH": "YES",
        "SDKROOT": "macosx",
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": ["$(inherited)", "DEBUG"],
        "SWIFT_OPTIMIZATION_LEVEL": "\"-Onone\"",
        "SWIFT_VERSION": "5.0",
    }

    project_release_settings = {
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "CLANG_ANALYZER_NONNULL": "YES",
        "CLANG_CXX_LANGUAGE_STANDARD": "\"gnu++20\"",
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "CLANG_ENABLE_OBJC_WEAK": "YES",
        "CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING": "YES",
        "CLANG_WARN_BOOL_CONVERSION": "YES",
        "CLANG_WARN_COMMA": "YES",
        "CLANG_WARN_CONSTANT_CONVERSION": "YES",
        "CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS": "YES",
        "CLANG_WARN_DIRECT_OBJC_ISA_USAGE": "YES_ERROR",
        "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
        "CLANG_WARN_EMPTY_BODY": "YES",
        "CLANG_WARN_ENUM_CONVERSION": "YES",
        "CLANG_WARN_INFINITE_RECURSION": "YES",
        "CLANG_WARN_INT_CONVERSION": "YES",
        "CLANG_WARN_NON_LITERAL_NULL_CONVERSION": "YES",
        "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF": "YES",
        "CLANG_WARN_OBJC_LITERAL_CONVERSION": "YES",
        "CLANG_WARN_OBJC_ROOT_CLASS": "YES_ERROR",
        "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER": "YES",
        "CLANG_WARN_RANGE_LOOP_ANALYSIS": "YES",
        "CLANG_WARN_STRICT_PROTOTYPES": "YES",
        "CLANG_WARN_SUSPICIOUS_MOVE": "YES",
        "CLANG_WARN_UNGUARDED_AVAILABILITY": "YES",
        "CLANG_WARN_UNREACHABLE_CODE": "YES",
        "CLANG_WARN__DUPLICATE_METHOD_MATCH": "YES",
        "COPY_PHASE_STRIP": "NO",
        "DEBUG_INFORMATION_FORMAT": "\"dwarf-with-dsym\"",
        "ENABLE_NS_ASSERTIONS": "YES",
        "ENABLE_STRICT_OBJC_MSGSEND": "YES",
        "GCC_NO_COMMON_BLOCKS": "YES",
        "GCC_WARN_64_TO_32_BIT_CONVERSION": "YES",
        "GCC_WARN_ABOUT_RETURN_TYPE": "YES_ERROR",
        "GCC_WARN_UNDECLARED_SELECTOR": "YES",
        "GCC_WARN_UNINITIALIZED_AUTOS": "YES_AGGRESSIVE",
        "GCC_WARN_UNUSED_FUNCTION": "YES",
        "GCC_WARN_UNUSED_VARIABLE": "YES",
        "MACOSX_DEPLOYMENT_TARGET": MIN_MACOS,
        "MTL_FAST_MATH": "YES",
        "SDKROOT": "macosx",
        "SWIFT_COMPILATION_MODE": "wholemodule",
        "SWIFT_VERSION": "5.0",
    }

    target_debug_settings = {
        "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
        "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
        "CODE_SIGN_ENTITLEMENTS": f"{SRC_DIR}/Entitlements.plist",
        "CODE_SIGN_STYLE": "Automatic",
        "COMBINE_HIDPI_IMAGES": "YES",
        "CURRENT_PROJECT_VERSION": "1",
        "DEVELOPMENT_TEAM": "",
        "ENABLE_HARDENED_RUNTIME": "YES",
        "GENERATE_INFOPLIST_FILE": "YES",
        "INFOPLIST_FILE": f"{SRC_DIR}/Info.plist",
        "INFOPLIST_KEY_NSHumanReadableCopyright": "",
        "INFOPLIST_KEY_NSMainStoryboardFile": "",
        "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/../Frameworks"],
        "MARKETING_VERSION": "1.0",
        "PRODUCT_BUNDLE_IDENTIFIER": BUNDLE_ID,
        "PRODUCT_NAME": "\"$(TARGET_NAME)\"",
        "SWIFT_EMIT_LOC_STRINGS": "YES",
        "SWIFT_VERSION": "5.0",
    }

    target_release_settings = dict(target_debug_settings)  # Same settings for both configs

    def fmt_value(value):
        """Format a setting value for the pbxproj file."""
        if isinstance(value, (list, tuple)):
            # Array value: wrap in parens, quote each element
            inner = ", ".join('"%s"' % v for v in value)
            return "(%s)" % inner
        if isinstance(value, str):
            # Plain identifiers (YES/NO/numbers/known tokens) stay unquoted
            plain_tokens = ("YES", "NO", "YES_ERROR", "YES_AGGRESSIVE", "wholemodule",
                            "macosx", "dwarf", "Automatic", "AppIcon", "AccentColor",
                            "INCLUDE_SOURCE", "0", "1")
            if value in plain_tokens or value.replace(".", "").replace("-", "").isdigit():
                return value
            if value.startswith("$") or "/" in value or "." in value or " " in value or "+" in value or value == "":
                # Already-quoted strings (start with ") pass through; empty -> ""
                if value.startswith('"'):
                    return value
                return '"%s"' % value
            # Default: quote it
            if value.startswith('"'):
                return value
            return '"%s"' % value
        return str(value)

    def write_config(config_id, name, settings, is_project=True):
        w(f"\t\t{config_id} /* {name} */ = {{")
        w("\t\t\tisa = XCBuildConfiguration;")
        w("\t\t\tbuildSettings = {")
        for key, value in settings.items():
            w(f"\t\t\t\t{key} = {fmt_value(value)};")
        w("\t\t\t};")
        w(f"\t\t\tname = {name};")
        w("\t\t};")

    w("/* Begin XCBuildConfiguration section */")
    write_config(ids['DEBUG_CONFIG_PROJECT'], "Debug", project_debug_settings)
    write_config(ids['RELEASE_CONFIG_PROJECT'], "Release", project_release_settings)
    write_config(ids['DEBUG_CONFIG_TARGET'], "Debug", target_debug_settings, is_project=False)
    write_config(ids['RELEASE_CONFIG_TARGET'], "Release", target_release_settings, is_project=False)
    w("/* End XCBuildConfiguration section */")
    w()

    # XCConfigurationList
    w("/* Begin XCConfigurationList section */")
    w(f"\t\t{ids['CONFIG_LIST_PROJECT']} /* Build configuration list for PBXProject \"{PRODUCT_NAME}\" */ = {{")
    w("\t\t\tisa = XCConfigurationList;")
    w("\t\t\tbuildConfigurations = (")
    w(f"\t\t\t\t{ids['DEBUG_CONFIG_PROJECT']} /* Debug */,")
    w(f"\t\t\t\t{ids['RELEASE_CONFIG_PROJECT']} /* Release */,")
    w("\t\t\t);")
    w("\t\t\tdefaultConfigurationIsVisible = 0;")
    w("\t\t\tdefaultConfigurationName = Release;")
    w("\t\t};")

    w(f"\t\t{ids['CONFIG_LIST_TARGET']} /* Build configuration list for PBXNativeTarget \"{PRODUCT_NAME}\" */ = {{")
    w("\t\t\tisa = XCConfigurationList;")
    w("\t\t\tbuildConfigurations = (")
    w(f"\t\t\t\t{ids['DEBUG_CONFIG_TARGET']} /* Debug */,")
    w(f"\t\t\t\t{ids['RELEASE_CONFIG_TARGET']} /* Release */,")
    w("\t\t\t);")
    w("\t\t\tdefaultConfigurationIsVisible = 0;")
    w("\t\t\tdefaultConfigurationName = Release;")
    w("\t\t};")
    w("/* End XCConfigurationList section */")
    w()

    w("\t};")
    w(f"\trootObject = {ids['PROJECT']} /* Project object */;")
    w("}")

    # Write project.pbxproj
    base_dir = os.path.dirname(os.path.abspath(__file__))
    xcodeproj_dir = os.path.join(base_dir, "SpaceSaver.xcodeproj")
    os.makedirs(xcodeproj_dir, exist_ok=True)

    pbxproj_path = os.path.join(xcodeproj_dir, "project.pbxproj")
    with open(pbxproj_path, "w") as f:
        f.write("\n".join(L))
    print(f"Created {pbxproj_path}")

    # Create xcworkspace
    xcworkspace_dir = os.path.join(base_dir, "SpaceSaver.xcworkspace")
    os.makedirs(xcworkspace_dir, exist_ok=True)
    workspace_data = """<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>"""
    with open(os.path.join(xcworkspace_dir, "contents.xcworkspacedata"), "w") as f:
        f.write(workspace_data)
    print(f"Created {xcworkspace_dir}/contents.xcworkspacedata")

    # Create Assets.xcassets
    assets_dir = os.path.join(base_dir, SRC_DIR, "Assets.xcassets")
    os.makedirs(assets_dir, exist_ok=True)
    with open(os.path.join(assets_dir, "Contents.json"), "w") as f:
        f.write('{\n  "info" : {\n    "author" : "xcode",\n    "version" : 1\n  }\n}')
    print(f"Created {assets_dir}/Contents.json")

    # AccentColor.colorset
    accent_dir = os.path.join(assets_dir, "AccentColor.colorset")
    os.makedirs(accent_dir, exist_ok=True)
    with open(os.path.join(accent_dir, "Contents.json"), "w") as f:
        f.write('{\n  "colors" : [\n    {\n      "idiom" : "universal"\n    }\n  ],\n  "info" : {\n    "author" : "xcode",\n    "version" : 1\n  }\n}')

    # AppIcon.appiconset
    appicon_dir = os.path.join(assets_dir, "AppIcon.appiconset")
    os.makedirs(appicon_dir, exist_ok=True)
    with open(os.path.join(appicon_dir, "Contents.json"), "w") as f:
        f.write('{\n  "images" : [\n    {\n      "idiom" : "mac",\n      "scale" : "1x",\n      "size" : "16x16"\n    },\n    {\n      "idiom" : "mac",\n      "scale" : "2x",\n      "size" : "16x16"\n    },\n    {\n      "idiom" : "mac",\n      "scale" : "1x",\n      "size" : "32x32"\n    },\n    {\n      "idiom" : "mac",\n      "scale" : "2x",\n      "size" : "32x32"\n    },\n    {\n      "idiom" : "mac",\n      "scale" : "1x",\n      "size" : "128x128"\n    },\n    {\n      "idiom" : "mac",\n      "scale" : "2x",\n      "size" : "128x128"\n    },\n    {\n      "idiom" : "mac",\n      "scale" : "1x",\n      "size" : "256x256"\n    },\n    {\n      "idiom" : "mac",\n      "scale" : "2x",\n      "size" : "256x256"\n    },\n    {\n      "idiom" : "mac",\n      "scale" : "1x",\n      "size" : "512x512"\n    },\n    {\n      "idiom" : "mac",\n      "scale" : "2x",\n      "size" : "512x512"\n    }\n  ],\n  "info" : {\n    "author" : "xcode",\n    "version" : 1\n  }\n}')

    # Xcode scheme
    schemes_dir = os.path.join(xcodeproj_dir, "xcshareddata", "xcschemes")
    os.makedirs(schemes_dir, exist_ok=True)
    scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{ids['TARGET']}"
               BuildableName = "{PRODUCT_NAME}.app"
               BlueprintName = "{PRODUCT_NAME}"
               ReferencedContainer = "container:{PRODUCT_NAME}.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{ids['TARGET']}"
            BuildableName = "{PRODUCT_NAME}.app"
            BlueprintName = "{PRODUCT_NAME}"
            ReferencedContainer = "container:{PRODUCT_NAME}.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>"""
    with open(os.path.join(schemes_dir, "SpaceSaver.xcscheme"), "w") as f:
        f.write(scheme)
    print(f"Created {schemes_dir}/SpaceSaver.xcscheme")

    print("\n✅ Xcode project created successfully!")
    print(f"   Open {os.path.join(base_dir, 'SpaceSaver.xcodeproj')} in Xcode to build and run.")


if __name__ == "__main__":
    main()