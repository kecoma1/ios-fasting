#!/usr/bin/env python3
"""Rebuild the checked-in Xcode project with Python's standard library only."""
from pathlib import Path
import hashlib
import json
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
PROJECT = "iOSFasting.xcodeproj"
objects = {}


def ident(name):
    return hashlib.sha256(name.encode()).hexdigest()[:24].upper()


def add(name, value):
    key = ident(name)
    objects[key] = value
    return key


def quote(value):
    return json.dumps(str(value))


def settings(values):
    return "{ " + " ".join(f"{k} = {quote(v)};" for k, v in values.items()) + " }"


def array(values):
    return "(" + ", ".join(values) + ",)" if values else "()"


def file(path, kind):
    return add("file:" + path, f"{{ isa = PBXFileReference; lastKnownFileType = {kind}; path = {quote(path)}; sourceTree = \"<group>\"; }}")


app_sources = sorted(str(p.relative_to(ROOT)) for p in (ROOT / "Fasting").rglob("*.swift"))
unit_sources = ["Tests/FastingStoreTests.swift"] + [p for p in app_sources if "/Models/" in p or p.endswith("FastingStore.swift")]
ui_sources = sorted(str(p.relative_to(ROOT)) for p in (ROOT / "UITests").rglob("*.swift"))
all_sources = sorted(set(app_sources + unit_sources + ui_sources))
refs = {p: file(p, "sourcecode.swift") for p in all_sources}
resources = {
    "Fasting/Resources/Assets.xcassets": "folder.assetcatalog",
    "Fasting/Resources/Localizable.xcstrings": "text.json.xcstrings",
    "Fasting/Resources/PrivacyInfo.xcprivacy": "text.xml",
}
refs.update({p: file(p, kind) for p, kind in resources.items()})
extra = [file("Fasting/Info.plist", "text.plist.xml"), file("Fasting/Fasting.entitlements", "text.plist.entitlements")]
products = []
targets = []

common = {"IPHONEOS_DEPLOYMENT_TARGET": "17.0", "SDKROOT": "iphoneos", "SWIFT_VERSION": "5.0", "TARGETED_DEVICE_FAMILY": "1,2", "CLANG_ENABLE_MODULES": "YES", "CODE_SIGN_STYLE": "Automatic", "SWIFT_STRICT_CONCURRENCY": "complete"}

for name, sources, product_type in [
    ("Fasting", app_sources, "com.apple.product-type.application"),
    ("FastingStoreTests", unit_sources, "com.apple.product-type.bundle.unit-test"),
    ("FastingUITests", ui_sources, "com.apple.product-type.bundle.ui-testing"),
]:
    app = name == "Fasting"
    suffix = ".app" if app else ".xctest"
    product = add(name + ":product", f"{{ isa = PBXFileReference; explicitFileType = {'wrapper.application' if app else 'wrapper.cfbundle'}; includeInIndex = 0; path = {name}{suffix}; sourceTree = BUILT_PRODUCTS_DIR; }}")
    products.append(product)
    build_sources = [add(name + ":build:" + p, f"{{ isa = PBXBuildFile; fileRef = {refs[p]}; }}") for p in sources]
    source_phase = add(name + ":sources", f"{{ isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = {array(build_sources)}; runOnlyForDeploymentPostprocessing = 0; }}")
    resource_files = [add(name + ":resource:" + p, f"{{ isa = PBXBuildFile; fileRef = {refs[p]}; }}") for p in resources] if app else []
    resource_phase = add(name + ":resources", f"{{ isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = {array(resource_files)}; runOnlyForDeploymentPostprocessing = 0; }}")
    framework_phase = add(name + ":frameworks", "{ isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; }")
    configs = []
    for configuration in ["Debug", "Release"]:
        values = dict(common, PRODUCT_NAME=name, PRODUCT_BUNDLE_IDENTIFIER="com.kecoma.fasting" + ("" if app else "." + name), SWIFT_OPTIMIZATION_LEVEL="-Onone" if configuration == "Debug" else "-O", SWIFT_ACTIVE_COMPILATION_CONDITIONS="DEBUG" if configuration == "Debug" else "", DEBUG_INFORMATION_FORMAT="dwarf" if configuration == "Debug" else "dwarf-with-dsym", ENABLE_TESTABILITY="YES" if configuration == "Debug" else "NO", GENERATE_INFOPLIST_FILE="NO" if app else "YES", ONLY_ACTIVE_ARCH="YES" if configuration == "Debug" else "NO")
        if app:
            values.update(INFOPLIST_FILE="Fasting/Info.plist", CODE_SIGN_ENTITLEMENTS="Fasting/Fasting.entitlements", DEVELOPMENT_TEAM="6GDZU4K9BF", ASSETCATALOG_COMPILER_APPICON_NAME="AppIcon", ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME="AccentColor", ICLOUD_ENVIRONMENT="Development" if configuration == "Debug" else "Production", APS_ENVIRONMENT="development" if configuration == "Debug" else "production", SWIFT_EMIT_LOC_STRINGS="YES")
        else:
            values.update(CODE_SIGN_IDENTITY="-", SKIP_INSTALL="YES")
        if name == "FastingUITests":
            values["TEST_TARGET_NAME"] = "Fasting"
        configs.append(add(name + ":" + configuration, f"{{ isa = XCBuildConfiguration; buildSettings = {settings(values)}; name = {configuration}; }}"))
    config_list = add(name + ":configs", f"{{ isa = XCConfigurationList; buildConfigurations = {array(configs)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }}")
    dependencies = []
    if name == "FastingUITests":
        proxy = add("ui:proxy", f"{{ isa = PBXContainerItemProxy; containerPortal = {ident('project')}; proxyType = 1; remoteGlobalIDString = {ident('Fasting:target')}; remoteInfo = Fasting; }}")
        dependencies.append(add("ui:dependency", f"{{ isa = PBXTargetDependency; target = {ident('Fasting:target')}; targetProxy = {proxy}; }}"))
    targets.append(add(name + ":target", f"{{ isa = PBXNativeTarget; buildConfigurationList = {config_list}; buildPhases = {array([source_phase, framework_phase, resource_phase])}; buildRules = (); dependencies = {array(dependencies)}; name = {name}; productName = {name}; productReference = {product}; productType = {quote(product_type)}; }}"))

product_group = add("products", f"{{ isa = PBXGroup; children = {array(products)}; name = Products; sourceTree = \"<group>\"; }}")
root_group = add("root", f"{{ isa = PBXGroup; children = {array(list(refs.values()) + extra + [product_group])}; sourceTree = \"<group>\"; }}")
project_configs = [add("project:" + c, f"{{ isa = XCBuildConfiguration; buildSettings = {{ ALWAYS_SEARCH_USER_PATHS = NO; CLANG_ENABLE_OBJC_ARC = YES; GCC_C_LANGUAGE_STANDARD = gnu17; }}; name = {c}; }}") for c in ["Debug", "Release"]]
project_config_list = add("project:configs", f"{{ isa = XCConfigurationList; buildConfigurations = {array(project_configs)}; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }}")
project_id = add("project", f"{{ isa = PBXProject; attributes = {{ LastUpgradeCheck = 2630; TargetAttributes = {{ {ident('Fasting:target')} = {{ CreatedOnToolsVersion = 26.3; SystemCapabilities = {{ com.apple.iCloud = {{ enabled = 1; }}; com.apple.Push = {{ enabled = 1; }}; com.apple.BackgroundModes = {{ enabled = 1; }}; }}; }}; }}; }}; buildConfigurationList = {project_config_list}; compatibilityVersion = \"Xcode 14.0\"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, es, Base); mainGroup = {root_group}; productRefGroup = {product_group}; projectDirPath = \"\"; projectRoot = \"\"; targets = {array(targets)}; }}")
project_path = ROOT / PROJECT
project_path.mkdir(exist_ok=True)
(project_path / "project.pbxproj").write_text("// !$*UTF8*$!\n{\narchiveVersion = 1;\nclasses = {};\nobjectVersion = 56;\nobjects = {\n" + "\n".join(f"{k} = {v};" for k, v in objects.items()) + f"\n}};\nrootObject = {project_id};\n}}\n")


def reference(name):
    return f'<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{ident(name + ":target")}" BuildableName="{name}{".app" if name == "Fasting" else ".xctest"}" BlueprintName="{name}" ReferencedContainer="container:{PROJECT}" />'


app_reference = reference("Fasting")
scheme = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2630" version="1.3">
 <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries>
  <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{app_reference}</BuildActionEntry>
 </BuildActionEntries></BuildAction>
 <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables>
  <TestableReference skipped="NO">{reference("FastingStoreTests")}</TestableReference>
  <TestableReference skipped="NO">{reference("FastingUITests")}</TestableReference>
 </Testables></TestAction>
 <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{app_reference}</BuildableProductRunnable><CommandLineArguments><CommandLineArgument argument="-InitializeCloudKitSchema" isEnabled="NO" /></CommandLineArguments></LaunchAction>
 <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" useCustomWorkingDirectory="NO"><BuildableProductRunnable runnableDebuggingMode="0">{app_reference}</BuildableProductRunnable></ProfileAction>
 <AnalyzeAction buildConfiguration="Debug" />
 <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES" />
</Scheme>
'''
scheme_path = project_path / "xcshareddata/xcschemes/Fasting.xcscheme"
scheme_path.parent.mkdir(parents=True, exist_ok=True)
scheme_path.write_text(scheme)
demo = ET.fromstring(scheme)
test_action = demo.find("TestAction")
test_action.set("shouldUseLaunchSchemeArgsEnv", "NO")
variables = ET.SubElement(test_action, "EnvironmentVariables")
ET.SubElement(variables, "EnvironmentVariable", key="FASTING_RECORD_DEMO", value="1", isEnabled="YES")
ET.ElementTree(demo).write(scheme_path.with_name("FastingDemo.xcscheme"), encoding="UTF-8", xml_declaration=True)
print(f"Generated {PROJECT} with app, storage tests, and UI tests.")
