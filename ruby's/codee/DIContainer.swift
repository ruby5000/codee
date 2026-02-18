import Foundation

// MARK: - Dependency Injection Container
class DIContainer {
    static let shared = DIContainer()
    
    private init() {}
    
    // MARK: - Services
    lazy var creditAPIService: CreditAPIServiceProtocol = CreditAPIService()
    lazy var networkMonitor: AppNetworkMonitor = AppNetworkMonitor.shared
    
    // MARK: - View Models
    func makeCreditViewModel() -> CreditViewModelProtocol {
        return CreditViewModel(
            creditAPIService: creditAPIService,
            networkMonitor: networkMonitor
        )
    }
}
