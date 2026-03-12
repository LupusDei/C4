import Testing
@testable import DesignKit

@Test func designKitVersion() async throws {
    #expect(DesignKit.version == "0.1.0")
}
