import ServiceManagement

public protocol LoginItemBackend {
    var isEnabled: Bool { get }
    func register() throws
    func unregister() throws
}

public protocol LoginItemServicing {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

public final class LoginItemService: LoginItemServicing {
    private let backend: any LoginItemBackend

    public init(backend: any LoginItemBackend = ServiceManagementLoginItemBackend()) {
        self.backend = backend
    }

    public var isEnabled: Bool {
        backend.isEnabled
    }

    public func setEnabled(_ enabled: Bool) throws {
        guard backend.isEnabled != enabled else {
            return
        }

        if enabled {
            try backend.register()
        } else {
            try backend.unregister()
        }
    }
}

public struct ServiceManagementLoginItemBackend: LoginItemBackend {
    private let service: SMAppService

    public init(service: SMAppService = .mainApp) {
        self.service = service
    }

    public var isEnabled: Bool {
        service.status == .enabled
    }

    public func register() throws {
        try service.register()
    }

    public func unregister() throws {
        try service.unregister()
    }
}
