//
import FirebaseFirestore
import FirebaseAuth


class ChatViewController: UIViewController, UISearchBarDelegate {
    var searchBar: UISearchBar?
    var searchResults: [String] = []
    var modalViewController: UIViewController?
    var modalTableView: UITableView?
    var id: String?
    var friendID: String?
    
    var friendList: [FriendInfo] = []
    
    
    let dispatchGroup = DispatchGroup()

    @IBOutlet weak var friendListTableView: UITableView!
    @IBAction func logOutBtn(_ sender: UIButton) {
        do {
                try Auth.auth().signOut()
                // 로그아웃 성공 후, 루트 뷰 컨트롤러를 초기화하여 로그인 화면으로 이동
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let goViewController = storyboard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
                UIApplication.shared.windows.first?.rootViewController = goViewController
            } catch {
                print("로그아웃 오류: \(error.localizedDescription)")
            }

    }

    @IBAction func searchBtn(_ sender: UIButton) {
        print("click")
        showSearchModal()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad(): "+self.id!)
        fetchFriendList()
        friendListTableView.dataSource = self
        friendListTableView.delegate = self
        friendListTableView.register(FriendListCell.self, forCellReuseIdentifier: "FriendListCell")



    }
    
    func setID(_ id:String){
        self.id=id;
    }
    
    func fetchFriendList() {
        print("성공")
        print("fetchFriendList() " + id!)
            

            // 사용자가 참여한 채팅방 목록을 가져오기
            let db = Firestore.firestore()
            db.collection("chatRooms")
                .whereField("users", arrayContains: id)
                .getDocuments { [weak self] (querySnapshot, error) in
                    guard let self = self else { return }

                    if let error = error {
                        print("Error fetching friend list: \(error.localizedDescription)")
                        return
                    }
                    print("채팅방 목록 가져오는 로직 끝")

                    self.friendList = [] // 대화 상대방 목록 배열 초기화

                    for document in querySnapshot!.documents {
                        let chatRoomId = document.documentID
                        let chatUsers = document.data()["users"] as? [String] ?? []

                        // 대화 상대방의 ID를 가져오기
                        let friendId = chatUsers.filter { $0 != self.id }.first
                            
                        self.dispatchGroup.enter() // 디스패치 그룹에 진입
                        
                        // 마지막 대화 내용 가져오기
                        self.fetchLastMessage(chatRoomId: chatRoomId) { lastMessage in
                            // 대화 상대방 정보를 가져온 후 FriendInfo 객체를 생성하여 대화 상대방 목록에 추가
                            if let friendId = friendId {
                                let friendInfo = FriendInfo(friendId: friendId, lastMessage: lastMessage)
                                self.friendList.append(friendInfo)
//                                print("friendId: \(friendInfo.friendId), lastMessage: \(friendInfo.lastMessage)")
                                self.dispatchGroup.leave()
                            }
                        }
                    }
                    self.dispatchGroup.notify(queue: .main) {
                            // 대화 상대방 목록을 모두 가져온 후에 UI를 업데이트
                            self.updateFriendListUI()
                        }
                }
        }

        func fetchLastMessage(chatRoomId: String, completion: @escaping (String) -> Void) {
            // 마지막 대화 내용을 가져오는 로직을 구현
            // 예시로 Firestore에서 마지막 대화 내용을 가져오는 코드를 작성하겠습니다.
            let db = Firestore.firestore()
            db.collection("chatRooms").document(chatRoomId).collection("messages")
                .order(by: "sentDate", descending: true)
                .limit(to: 1)
                .getDocuments { (querySnapshot, error) in
                    if let error = error {
                        print("Error fetching last message: \(error.localizedDescription)")
                        completion("")
                        return
                    }

                    guard let document = querySnapshot?.documents.first else {
                        completion("")
                        return
                    }

                    let lastMessage = document.data()["text"] as? String ?? ""
                    completion(lastMessage)
                    print("마지막 메세지 가지오는 함수 성공")
                    
                    }
        }

        func updateFriendListUI() {
            // 대화 상대방 목록을 업데이트하고 UI를 갱신하는 로직을 구현
            // 예시로 테이블뷰를 사용하여 대화 상대방 목록을 보여주는 코드를 작성하겠습니다.

            // 테이블뷰를 업데이트
            DispatchQueue.main.async {
                self.friendListTableView.reloadData()
                print("테이블 뷰 업데이트 끝")
            }
        }
    
    func showSearchModal() {
        print("make modal start")
        let modalViewController = UIViewController()
        modalViewController.modalPresentationStyle = .overCurrentContext
        modalViewController.view.backgroundColor = UIColor(white: 0, alpha: 0.5)
        modalViewController.view.frame = view.bounds

        let searchView = UIView(frame: CGRect(x: 50, y: 100, width: view.bounds.width - 100, height: view.bounds.height - 200))
        searchView.backgroundColor = .white
        searchView.layer.cornerRadius = 10
        modalViewController.view.addSubview(searchView)

        searchBar = UISearchBar(frame: CGRect(x: 10, y: 10, width: searchView.bounds.width - 20, height: 44))
        searchBar?.autocapitalizationType = .none
        searchBar?.delegate = self
        searchView.addSubview(searchBar!)

        let tableView = UITableView(frame: CGRect(x: 10, y: 118, width: searchView.bounds.width - 20, height: searchView.bounds.height - 128))
            tableView.dataSource = self
            tableView.delegate = self
            tableView.register(FriendListCell.self, forCellReuseIdentifier: "FriendListCell")
            searchView.addSubview(tableView)

        searchView.addSubview(tableView)

        self.modalViewController = modalViewController
        self.modalTableView = tableView

        present(modalViewController, animated: true, completion: nil)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissSearchModal))
                tapGesture.cancelsTouchesInView = false
                modalViewController.view.addGestureRecognizer(tapGesture)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchTerm = searchBar.text else {
            return
        }
        searchUsers(with: searchTerm)
        print(searchTerm)
        searchBar.resignFirstResponder() // 검색 후 키보드 닫기
    }

    func searchUsers(with searchTerm: String) {
        print("start search")
        let db = Firestore.firestore()
        let usersCollection = db.collection("userInfo")

        usersCollection.whereField("id", isEqualTo: searchTerm)
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }

                if let error = error {
                    print("검색 결과 가져오기 오류: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("검색 결과 없음")
                    return
                }

                self.searchResults = []

                let lowercasedSearchTerm = searchTerm.lowercased()

                for document in documents {
                    if let id = document.data()["id"] as? String {
                        let lowercasedID = id.lowercased()
                        if lowercasedID.contains(lowercasedSearchTerm) {
                            print("id: " + id)
                            self.searchResults.append(id)
                        }
                    }
                }


                // 검색 결과 사용
                print(self.searchResults)

                // 검색 결과를 tableView에 업데이트
                DispatchQueue.main.async {
                    self.modalTableView?.reloadData()
                }
            }
    }

    @objc func dismissSearchModal() {
        self.modalViewController?.dismiss(animated: true, completion: nil)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        dismissSearchModal()
    }
}

extension ChatViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            if tableView == friendListTableView {
                // friendListTableView의 경우 friendList 배열의 아이템 수를 반환
                return friendList.count
            } else {
                // modalTableView의 경우 searchResults 배열의 아이템 수를 반환
                return searchResults.count
            }
        }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            if tableView == friendListTableView {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FriendListCell", for: indexPath) as! FriendListCell
                let friendInfo = friendList[indexPath.row]
                cell.configure(with: friendInfo)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "FriendListCell", for: indexPath) as! FriendListCell
                let friendInfo = searchResults[indexPath.row]
                cell.textLabel?.text = friendInfo
                    return cell
            }
        }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == friendListTableView {
            let friendInfo = friendList[indexPath.row]
            showChatViewController(with: friendInfo.friendId)
        } else {
            let friendInfo = searchResults[indexPath.row]
            showChatViewController(with: friendInfo)
        }
    }
    
    

    func showChatViewController(with friendID: String) {
        // 채팅할 수 있는 뷰 컨트롤러를 초기화하고, friendID를 전달합니다.
        let chatVC = ChatRoomViewController()
        chatVC.friendID = friendID
        chatVC.id = self.id

        navigationController?.pushViewController(chatVC, animated: true)
    }

   
}

struct FriendInfo {
    let friendId: String
    let lastMessage: String
}

class FriendListCell: UITableViewCell {
    private let friendIdLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 17)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let lastMessageLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }

    private func setupUI() {
        addSubview(friendIdLabel)
        addSubview(lastMessageLabel)
        
        NSLayoutConstraint.activate([
            friendIdLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            friendIdLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            friendIdLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            lastMessageLabel.topAnchor.constraint(equalTo: friendIdLabel.bottomAnchor, constant: 4),
            lastMessageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            lastMessageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            lastMessageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with friendInfo: FriendInfo) {
        friendIdLabel.text = friendInfo.friendId
        lastMessageLabel.text = friendInfo.lastMessage
    }
}




