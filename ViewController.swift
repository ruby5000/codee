import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var currentPage = 1
    let pageSize = 10
    var isFetchingData = false
    var allPosts: [Post] = [] // Store all posts
    var displayedPosts: [Post] = [] // Posts to display on the current page
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableview.register(UINib(nibName: "dataCell", bundle: .main), forCellReuseIdentifier: "dataCell")
        tableview.delegate = self
        tableview.dataSource = self
        activityIndicator.hidesWhenStopped = true
        fetchAllPosts()
    }
    
    private func fetchAllPosts() {
        activityIndicator.startAnimating()
        
        APIManager.shared.fetchAllPosts { [weak self] result in
            guard let self = self else { return }
            
            self.activityIndicator.stopAnimating()
            
            switch result {
            case .success(let posts):
                self.allPosts = posts
                self.loadMoreData() // Load the first page
            case .failure(let error):
                print("API Error: \(error.localizedDescription)")
            }
        }
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedPosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "dataCell", for: indexPath) as! dataCell
        let post = displayedPosts[indexPath.row]
        cell.customTextLabel?.text = post.title
        cell.customDetailTextLabel?.text = post.body
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        if offsetY > contentHeight - height {
            guard !isFetchingData else { return }
            
            isFetchingData = true
            
            // Calculate the range of posts to display
            let startIndex = (currentPage - 1) * pageSize
            let endIndex = min(startIndex + pageSize, allPosts.count)
            
            guard startIndex < endIndex else {
                isFetchingData = false
                return // No more data to load
            }
            
            // Add the new posts to the displayedPosts array
            let newPosts = Array(allPosts[startIndex..<endIndex])
            displayedPosts.append(contentsOf: newPosts)
            
            // Increment the page for the next load
            currentPage += 1
            
            // Reload the table view
            DispatchQueue.main.async {
                self.tableview.reloadData()
                self.isFetchingData = false
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}
