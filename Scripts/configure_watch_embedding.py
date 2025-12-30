#!/usr/bin/env python3
import re
import uuid
import sys

def main():
    pbxproj_path = 'RootsApp.xcodeproj/project.pbxproj'
    
    with open(pbxproj_path, 'r') as f:
        content = f.read()
    
    # Known UUIDs
    IOS_TARGET_UUID = "1AD7D4332EDD328800D403F3"
    WATCH_TARGET_UUID = "A3D4E93275A547E499CA3B3E"
    WATCH_PRODUCT_UUID = "9BBB386A3C3046FCA7A3D6DB"
    PROJECT_UUID = "1AD7D42C2EDD328800D403F3"
    
    # Generate new UUIDs
    COPY_FILES_UUID = uuid.uuid4().hex[:24].upper()
    TARGET_DEP_UUID = uuid.uuid4().hex[:24].upper()
    CONTAINER_PROXY_UUID = uuid.uuid4().hex[:24].upper()
    BUILD_FILE_UUID = uuid.uuid4().hex[:24].upper()
    
    # Fix 1: Deployment targets
    content = content.replace('IPHONEOS_DEPLOYMENT_TARGET = 26.1;', 'IPHONEOS_DEPLOYMENT_TARGET = 17.0;')
    content = content.replace('WATCHOS_DEPLOYMENT_TARGET = 26.0;', 'WATCHOS_DEPLOYMENT_TARGET = 10.0;')
    
    # Fix 2: Add PBXBuildFile
    build_file = f"\t\t{BUILD_FILE_UUID} /* RootsWatch.app in Embed Watch Content */ = {{isa = PBXBuildFile; fileRef = {WATCH_PRODUCT_UUID} /* RootsWatch.app */; settings = {{ATTRIBUTES = (RemoveHeadersOnCopy, ); }}; }};\n"
    content = content.replace(
        '/* Begin PBXBuildFile section */\n',
        f'/* Begin PBXBuildFile section */\n{build_file}'
    )
    
    # Fix 3: Add PBXContainerItemProxy
    container_proxy = f"\t\t{CONTAINER_PROXY_UUID} /* PBXContainerItemProxy */ = {{\n\t\t\tisa = PBXContainerItemProxy;\n\t\t\tcontainerPortal = {PROJECT_UUID} /* Project object */;\n\t\t\tproxyType = 1;\n\t\t\tremoteGlobalIDString = {WATCH_TARGET_UUID};\n\t\t\tremoteInfo = RootsWatch;\n\t\t}};\n"
    
    if '/* Begin PBXContainerItemProxy section */' in content:
        content = content.replace(
            '/* Begin PBXContainerItemProxy section */\n',
            f'/* Begin PBXContainerItemProxy section */\n{container_proxy}'
        )
    else:
        content = content.replace(
            '/* Begin PBXCopyFilesBuildPhase section */',
            f'/* Begin PBXContainerItemProxy section */\n{container_proxy}/* End PBXContainerItemProxy section */\n\n/* Begin PBXCopyFilesBuildPhase section */'
        )
    
    # Fix 4: Add PBXCopyFilesBuildPhase
    copy_files_phase = f"\t\t{COPY_FILES_UUID} /* Embed Watch Content */ = {{\n\t\t\tisa = PBXCopyFilesBuildPhase;\n\t\t\tbuildActionMask = 2147483647;\n\t\t\tdstPath = \"$(CONTENTS_FOLDER_PATH)/Watch\";\n\t\t\tdstSubfolderSpec = 16;\n\t\t\tfiles = (\n\t\t\t\t{BUILD_FILE_UUID} /* RootsWatch.app in Embed Watch Content */,\n\t\t\t);\n\t\t\tname = \"Embed Watch Content\";\n\t\t\trunOnlyForDeploymentPostprocessing = 0;\n\t\t}};\n"
    
    if '/* Begin PBXCopyFilesBuildPhase section */' in content:
        content = content.replace(
            '/* Begin PBXCopyFilesBuildPhase section */\n',
            f'/* Begin PBXCopyFilesBuildPhase section */\n{copy_files_phase}'
        )
    else:
        content = content.replace(
            '/* Begin PBXFileReference section */',
            f'/* Begin PBXCopyFilesBuildPhase section */\n{copy_files_phase}/* End PBXCopyFilesBuildPhase section */\n\n/* Begin PBXFileReference section */'
        )
    
    # Fix 5: Add PBXTargetDependency
    target_dependency = f"\t\t{TARGET_DEP_UUID} /* PBXTargetDependency */ = {{\n\t\t\tisa = PBXTargetDependency;\n\t\t\ttarget = {WATCH_TARGET_UUID} /* RootsWatch */;\n\t\t\ttargetProxy = {CONTAINER_PROXY_UUID} /* PBXContainerItemProxy */;\n\t\t}};\n"
    
    if '/* Begin PBXTargetDependency section */' in content:
        content = content.replace(
            '/* Begin PBXTargetDependency section */\n',
            f'/* Begin PBXTargetDependency section */\n{target_dependency}'
        )
    else:
        content = content.replace(
            '/* Begin PBXVariantGroup section */',
            f'/* Begin PBXTargetDependency section */\n{target_dependency}/* End PBXTargetDependency section */\n\n/* Begin PBXVariantGroup section */'
        )
    
    # Fix 6: Add copy files phase to iOS target buildPhases
    ios_pattern = rf'({IOS_TARGET_UUID} /\* Roots \*/ = {{.*?buildPhases = \(.*?1AD7D4322EDD328800D403F3 /\* Resources \*/,)'
    replacement = rf'\1\n\t\t\t\t{COPY_FILES_UUID} /* Embed Watch Content */,'
    content = re.sub(ios_pattern, replacement, content, flags=re.DOTALL)
    
    # Fix 7: Add target dependency to iOS target
    ios_dep_pattern = rf'({IOS_TARGET_UUID} /\* Roots \*/ = {{.*?dependencies = \(\s+)\);'
    replacement = rf'\1\t\t\t\t{TARGET_DEP_UUID} /* PBXTargetDependency */,\n\t\t\t);'
    content = re.sub(ios_dep_pattern, replacement, content, flags=re.DOTALL)
    
    # Write back
    with open(pbxproj_path, 'w') as f:
        f.write(content)
    
    print("✅ watchOS companion app configuration complete")
    print(f"  • Fixed iOS deployment target: 26.1 → 17.0")
    print(f"  • Fixed watchOS deployment target: 26.0 → 10.0")
    print(f"  • Added embedding infrastructure")
    print(f"  • Watch app will now be included in iOS .ipa")

if __name__ == '__main__':
    main()
