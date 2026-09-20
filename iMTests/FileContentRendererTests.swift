import XCTest

final class FileContentRendererTests: XCTestCase {

    // MARK: - Fenced wrapping

    func testCodeExtensionWrapsInFencedBlock() {
        XCTAssertEqual(FileContentRenderer.markdownBody(text: "let x = 1",
                                                        pathExtension: "swift"),
                       "```swift\nlet x = 1\n```")
    }

    func testAliasExtensionsMapToSameLanguage() {
        XCTAssertEqual(FileContentRenderer.markdownBody(text: "k: v", pathExtension: "yml"),
                       "```yaml\nk: v\n```")
        XCTAssertEqual(FileContentRenderer.markdownBody(text: "echo hi", pathExtension: "zsh"),
                       "```bash\necho hi\n```")
        XCTAssertEqual(FileContentRenderer.markdownBody(text: "SELECT 1", pathExtension: "patch"),
                       "```diff\nSELECT 1\n```")
    }

    func testMarkdownVariantsPassThroughUnchanged() {
        let text = "# Title\n\nbody"
        for ext in ["md", "markdown", "mdown", "mkd", "mkdn", "mdwn", "mdtxt", "mdtext"] {
            XCTAssertEqual(FileContentRenderer.markdownBody(text: text, pathExtension: ext), text)
        }
    }

    func testEmptyAndUnknownExtensionsRenderAsMarkdown() {
        let text = "# Heading"
        XCTAssertEqual(FileContentRenderer.markdownBody(text: text, pathExtension: ""), text)
        XCTAssertEqual(FileContentRenderer.markdownBody(text: text, pathExtension: "weird"), text)
    }

    // MARK: - JSON truncation

    func testJSONUnderLimitIsWrappedUnchanged() {
        let text = "{\"a\":1}"
        XCTAssertEqual(FileContentRenderer.truncatedJSONBody(text),
                       "```json\n\(text)\n```")
    }

    func testJSONExactlyAtLimitIsNotTruncated() {
        let text = String(repeating: "a", count: FileContentRenderer.jsonByteLimit)
        let result = FileContentRenderer.truncatedJSONBody(text)
        XCTAssertTrue(result.hasPrefix("```json\n" + text))
        XCTAssertFalse(result.contains("File truncated"))
    }

    func testJSONOverLimitIsTruncatedWithNotice() {
        // Multi-byte characters must not be split mid-UTF-8 sequence.
        let text = String(repeating: "字", count: FileContentRenderer.jsonByteLimit)
        let result = FileContentRenderer.truncatedJSONBody(text)
        XCTAssertTrue(result.contains("File truncated"))
        XCTAssertTrue(result.hasPrefix("```json"))
        // Re-encoding the result must produce valid UTF-8 (no partial character).
        XCTAssertNotNil(result.data(using: .utf8))
        let fenceContents = result
            .replacingOccurrences(of: "```json\n", with: "")
            .components(separatedBy: "\n```")[0]
        XCTAssertLessThanOrEqual(fenceContents.utf8.count,
                                 FileContentRenderer.jsonByteLimit)
    }

    // MARK: - Extension registry

    func testSupportedExtensionsCoverEveryDeclaredType() {
        let supported = FileContentRenderer.supportedExtensions
        XCTAssertTrue(supported.contains("json"))
        XCTAssertTrue(supported.contains("md"))
        XCTAssertTrue(supported.contains("swift"))
        XCTAssertTrue(supported.contains("tsx"))
        XCTAssertFalse(supported.contains(""))
    }
}
