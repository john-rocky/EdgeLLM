import PackagePlugin
import Foundation

@main
struct EdgeLLMSetupPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        // Run setup script if dependencies don't exist
        let depsPath = context.package.directory.appending(".dependencies")
        let setupScript = context.package.directory.appending("scripts", "setup.sh")
        
        if !FileManager.default.fileExists(atPath: depsPath.string) {
            return [
                .prebuildCommand(
                    displayName: "Setting up EdgeLLM dependencies",
                    executable: Path("/bin/bash"),
                    arguments: [setupScript.string],
                    outputFilesDirectory: depsPath
                )
            ]
        }
        
        return []
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension EdgeLLMSetupPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        // Similar implementation for Xcode
        let depsPath = context.xcodeProject.directory.appending(".dependencies")
        let setupScript = context.xcodeProject.directory.appending("scripts", "setup.sh")
        
        if !FileManager.default.fileExists(atPath: depsPath.string) {
            return [
                .prebuildCommand(
                    displayName: "Setting up EdgeLLM dependencies",
                    executable: Path("/bin/bash"),
                    arguments: [setupScript.string],
                    outputFilesDirectory: depsPath
                )
            ]
        }
        
        return []
    }
}
#endif