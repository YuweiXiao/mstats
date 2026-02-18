import XCTest
@testable import MacStatsBar

final class LoginItemServiceTests: XCTestCase {
    func testSetEnabledTrueRegistersBackendAndReflectsEnabledState() throws {
        let backend = StubLoginItemBackend(isEnabled: false)
        let service = LoginItemService(backend: backend)

        try service.setEnabled(true)

        XCTAssertEqual(backend.registerCallCount, 1)
        XCTAssertEqual(backend.unregisterCallCount, 0)
        XCTAssertTrue(service.isEnabled)
    }

    func testSetEnabledFalseUnregistersBackendAndReflectsDisabledState() throws {
        let backend = StubLoginItemBackend(isEnabled: true)
        let service = LoginItemService(backend: backend)

        try service.setEnabled(false)

        XCTAssertEqual(backend.registerCallCount, 0)
        XCTAssertEqual(backend.unregisterCallCount, 1)
        XCTAssertFalse(service.isEnabled)
    }
}

private final class StubLoginItemBackend: LoginItemBackend {
    private(set) var isEnabled: Bool
    private(set) var registerCallCount = 0
    private(set) var unregisterCallCount = 0

    init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }

    func register() throws {
        registerCallCount += 1
        isEnabled = true
    }

    func unregister() throws {
        unregisterCallCount += 1
        isEnabled = false
    }
}
