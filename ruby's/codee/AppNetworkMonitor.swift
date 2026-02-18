import Network

final class AppNetworkMonitor {
    static let shared = AppNetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "AppNetworkMonitorQueue")

    private(set) var isConnected: Bool = true

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            self?.isConnected = connected
        }
        monitor.start(queue: queue)
    }

    func isConnectedToInternet() -> Bool {
        return isConnected
    }
}
