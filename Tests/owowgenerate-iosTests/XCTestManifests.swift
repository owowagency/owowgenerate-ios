import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(owowgenerate_iosTests.allTests),
    ]
}
#endif
