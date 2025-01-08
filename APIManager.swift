import Alamofire
import Foundation

class APIManager {
    
    static let shared = APIManager()
    
    private init() {}
    
    func fetchAllPosts(completion: @escaping (Result<[Post], Error>) -> Void) {
        let url = "https://jsonplaceholder.typicode.com/posts"
        
        AF.request(url).responseDecodable(of: [Post].self) { response in
            switch response.result {
            case .success(let posts):
                completion(.success(posts))
            case .failure(let afError):
                completion(.failure(afError as Error)) // Convert AFError to Error
            }
        }
    }
    
    func apicalling(url: String, params: Parameters, completion: @escaping (Result<[Post], Error>) -> Void) {
    
        AF.request(url).responseDecodable(of: [Post].self) {response in
            switch response.result {
            case .success(let post):
                completion(.success(post))
            case .failure(_):
                completion(.failure(Error.self as! Error))
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
