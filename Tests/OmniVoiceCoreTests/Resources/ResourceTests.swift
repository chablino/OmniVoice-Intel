import Foundation
import ApplicationServices
import Testing
@testable import OmniVoiceCore

@Suite("Resources")
struct ResourceTests {
    @Test
    func appIconResourceExists() {
        let path = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Resources/AppIcon.icns")
        #expect(FileManager.default.fileExists(atPath: path.path))
    }

    @Test
    func nativeGlassEffectViewIsOnlyLookedUpDynamically() throws {
        let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        let hudDirectory = repositoryRoot.appendingPathComponent("Sources/OmniVoiceCore/UI/HUD")
        let hudSourceURLs = try FileManager.default.contentsOfDirectory(
            at: hudDirectory,
            includingPropertiesForKeys: nil
        )
            .filter { $0.pathExtension == "swift" }

        for url in hudSourceURLs {
            let source = url.path.replacingOccurrences(of: repositoryRoot.path + "/", with: "")
            let contents = try String(contentsOf: url, encoding: .utf8)
            let withoutDynamicLookupString = contents.replacingOccurrences(of: "\"NSGlassEffectView\"", with: "")
            #expect(
                !withoutDynamicLookupString.contains("NSGlassEffectView"),
                "\(source) must not statically reference NSGlassEffectView so older SDKs can compile"
            )
        }
    }
}
