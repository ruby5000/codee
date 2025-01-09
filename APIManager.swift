import Alamofire
import Foundation

class APIManager {
    
    static let shared = APIManager()
    
    private init() {}
    
    func apiCalling(url: String, params: Parameters, completion: @escaping(Result<[Post], Error>) -> Void) {
        AF.request(url, parameters: params).responseDecodable(of: [Post].self) { response in
            switch response.result {
            case .success(let suc):
                completion(.success(suc))
            case .failure(let err):
                completion(.failure(err as Error))
            }
        }
    }
}

struct Post: Codable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}
