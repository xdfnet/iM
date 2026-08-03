import XCTest

final class CodeFenceInfoTests: XCTestCase {

    func testBareLanguageBecomesLowercaseLanguageWithEmptyMetadata() {
        let info = CodeFenceInfo(rawInfoString: "Swift")
        XCTAssertEqual(info.language, "swift")
        XCTAssertEqual(info.metadata, "")
    }

    func testFirstWhitespaceSeparatedTokenIsTheLanguage() {
        let info = CodeFenceInfo(rawInfoString: "mermaid some-name")
        XCTAssertEqual(info.language, "mermaid")
        XCTAssertEqual(info.metadata, "some-name")
    }

    func testTabsAlsoSeparateLanguageFromMetadata() {
        let info = CodeFenceInfo(rawInfoString: "ts\ttitle=\"foo.ts\"")
        XCTAssertEqual(info.language, "ts")
        XCTAssertEqual(info.metadata, "title=\"foo.ts\"")
    }

    func testMetadataPreservesInternalWhitespaceAndCasing() {
        let info = CodeFenceInfo(rawInfoString: "ts  Title=\"Foo Bar\"  {1,3}")
        XCTAssertEqual(info.language, "ts")
        XCTAssertEqual(info.metadata, "Title=\"Foo Bar\"  {1,3}")
    }

    func testLeadingAndTrailingWhitespaceIsTrimmedBeforeSplitting() {
        let info = CodeFenceInfo(rawInfoString: "   mermaid   some-name   ")
        XCTAssertEqual(info.language, "mermaid")
        XCTAssertEqual(info.metadata, "some-name")
    }

    func testNilInfoStringYieldsEmptyValues() {
        let info = CodeFenceInfo(rawInfoString: nil)
        XCTAssertEqual(info.language, "")
        XCTAssertEqual(info.metadata, "")
    }

    func testEmptyInfoStringYieldsEmptyValues() {
        let info = CodeFenceInfo(rawInfoString: "")
        XCTAssertEqual(info.language, "")
        XCTAssertEqual(info.metadata, "")
    }

    func testWhitespaceOnlyInfoStringYieldsEmptyValues() {
        let info = CodeFenceInfo(rawInfoString: "   \t  ")
        XCTAssertEqual(info.language, "")
        XCTAssertEqual(info.metadata, "")
    }
}
