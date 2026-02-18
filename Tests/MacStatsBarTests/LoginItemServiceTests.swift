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

    func testSetEnabledTrueWhenAlreadyEnabledDoesNotCallRegisterAgain() throws {
        let backend = StubLoginItemBackend(isEnabled: true)
        let service = LoginItemService(backend: backend)

        try service.setEnabled(true)

        XCTAssertEqual(backend.registerCallCount, 0)
        XCTAssertEqual(backend.unregisterCallCount, 0)
        XCTAssertTrue(service.isEnabled)
    }

    func testSetEnabledFalseWhenAlreadyDisabledDoesNotCallUnregisterAgain() throws {
        let backend = StubLoginItemBackend(isEnabled: false)
        let service = LoginItemService(backend: backend)

        try service.setEnabled(false)

        XCTAssertEqual(backend.registerCallCount, 0)
        XCTAssertEqual(backend.unregisterCallCount, 0)
        XCTAssertFalse(service.isEnabled)
    }

    func testSetEnabledTruePropagatesRegisterFailure() {
        let backend = StubLoginItemBackend(
            isEnabled: false,
            registerError: StubLoginItemBackend.TestError.registerFailed
        )
        let service = LoginItemService(backend: backend)

        XCTAssertThrowsError(try service.setEnabled(true)) { error in
            XCTAssertEqual(error as? StubLoginItemBackend.TestError, .registerFailed)
        }
        XCTAssertEqual(backend.registerCallCount, 1)
        XCTAssertFalse(service.isEnabled)
    }

    func testSetEnabledFalsePropagatesUnregisterFailure() {
        let backend = StubLoginItemBackend(
            isEnabled: true,
            unregisterError: StubLoginItemBackend.TestError.unregisterFailed
        )
        let service = LoginItemService(backend: backend)

        XCTAssertThrowsError(try service.setEnabled(false)) { error in
            XCTAssertEqual(error as? StubLoginItemBackend.TestError, .unregisterFailed)
        }
        XCTAssertEqual(backend.unregisterCallCount, 1)
        XCTAssertTrue(service.isEnabled)
    }
}

private final class StubLoginItemBackend: LoginItemBackend {
    enum TestError: Error, Equatable {
        case registerFailed
        case unregisterFailed
    }

    private(set) var isEnabled: Bool
    private(set) var registerCallCount = 0
    private(set) var unregisterCallCount = 0
    private let registerError: (any Error)?
    private let unregisterError: (any Error)?

    init(
        isEnabled: Bool,
        registerError: (any Error)? = nil,
        unregisterError: (any Error)? = nil
    ) {
        self.isEnabled = isEnabled
        self.registerError = registerError
        self.unregisterError = unregisterError
    }

    func register() throws {
        registerCallCount += 1
        if let registerError {
            throw registerError
        }
        isEnabled = true
    }

    func unregister() throws {
        unregisterCallCount += 1
        if let unregisterError {
            throw unregisterError
        }
        isEnabled = false
    }
}
