//
//  ChatRoomViewController.swift
//  myProject
//
//  Created by 이서연 on 2023/06/19.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import Photos
import FirebaseFirestore

class ChatRoomViewController: MessagesViewController {
    
    
    var friendID: String?
    var id: String?
    
    var sender: Sender {
        return Sender(senderId: id ?? "any_unique_id", displayName: friendID ?? "Steven")
    }
    var messages: [MessageType] = []
    
    let db = Firestore.firestore()
    
    var chatRoomId: String!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        print("friendID: " + (friendID ?? ""))
        print("id: " + (id ?? ""))
        
        if let id = id {
            chatRoomId = "\(id)_\(Date().timeIntervalSince1970)"
        }
        
        // MessageKit 설정
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        // 입력창 설정
        messageInputBar.delegate = self
        
        //        let message1 = Message(sender: sender, messageId: UUID().uuidString, sentDate: Date(), kind: .text("Hello!"))
        //        let message2 = Message(sender: sender, messageId: UUID().uuidString, sentDate: Date(), kind: .text("How are you?"))
        //        let message3 = Message(sender: sender, messageId: UUID().uuidString, sentDate: Date(), kind: .text("Nice to meet you!"))
        //        messages.append(contentsOf: [message1, message2, message3])
        
        fetchMessages()
        setupInputBar()

        
    }
    func setupInputBar() {
            messageInputBar.delegate = self
            
            // 하트 이모티콘 버튼 생성
            let heartButton = InputBarButtonItem()
            heartButton.setSize(CGSize(width: 36, height: 36), animated: false)
            heartButton.setImage(UIImage(named: "heart_icon"), for: .normal)
            heartButton.onTouchUpInside { [weak self] _ in
                self?.inputBarDidPressHeartButton()
            }
            
            messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
            messageInputBar.setStackViewItems([heartButton], forStack: .left, animated: false)
        }
        
        func inputBarDidPressHeartButton() {
            // 하트 이모티콘을 전송
            let heartMessage = Message(sender: currentSender, messageId: UUID().uuidString, sentDate: Date(), kind: .text("❤️"))
            messages.append(heartMessage)
            messagesCollectionView.reloadData()
            messagesCollectionView.scrollToLastItem(animated: true)
            saveMessageToFirestore(message: heartMessage)
        }
    
    func fetchMessages() {
        guard let id = id, let friendID = friendID else {
            return
        }
        
        let ascendingQuery = db.collection("chatRooms")
            .whereField("users", arrayContainsAny: [id, friendID])
            .order(by: "users", descending: false)
        
        let descendingQuery = db.collection("chatRooms")
            .whereField("users", arrayContainsAny: [id, friendID])
            .order(by: "users", descending: true)
        
        var mergedData: [QueryDocumentSnapshot] = []
        
        // Fetch ascending order data
        ascendingQuery.getDocuments { [weak self] (ascendingSnapshot, error) in
            guard let ascendingDocuments = ascendingSnapshot?.documents else {
                print("Error fetching ascending documents: \(error?.localizedDescription ?? "")")
                return
            }
            mergedData.append(contentsOf: ascendingDocuments)
            
            // Fetch descending order data
            descendingQuery.getDocuments { [weak self] (descendingSnapshot, error) in
                guard let descendingDocuments = descendingSnapshot?.documents else {
                    print("Error fetching descending documents: \(error?.localizedDescription ?? "")")
                    return
                }
                
                let dispatchGroup = DispatchGroup()
                var messages: [Message] = []
                
                for document in ascendingDocuments {
                    dispatchGroup.enter()
                    
                    let messageId = document.documentID
                    let messageRef = document.reference.collection("messages")
                    
                    messageRef.getDocuments { (messageSnapshot, error) in
                        defer {
                            dispatchGroup.leave()
                        }
                        
                        guard let messageDocument = messageSnapshot?.documents.first,
                              let data = messageDocument.data() as? [String: Any], // Modify this line
                              let senderId = data["senderId"] as? String,
                              let displayName = data["displayName"] as? String,
                              let sentDate = data["sentDate"] as? Timestamp,
                              let text = data["text"] as? String else {
                            return
                        }
                        
                        let sender = Sender(senderId: senderId, displayName: displayName)
                        let message = Message(sender: sender, messageId: messageId, sentDate: sentDate.dateValue(), kind: .text(text))
                        messages.append(message)
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    self?.messages = messages.sorted(by: { $0.sentDate < $1.sentDate })
                    self?.messagesCollectionView.reloadData()
                    self?.messagesCollectionView.scrollToLastItem(animated: true)
                }
            }
        }
    }
}
extension ChatRoomViewController: MessagesDataSource {
    var currentSender: SenderType {
        return sender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section == 0 {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // Customize the date format as needed
            let dateString = formatter.string(from: message.sentDate)
            
            return NSAttributedString(string: dateString, attributes: [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10),
                NSAttributedString.Key.foregroundColor: UIColor.darkGray
            ])
        }
        return nil
    }
    
    // Implement other necessary methods if needed
}

extension ChatRoomViewController: MessagesLayoutDelegate {
    func messageSizeCalculator(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        let maxWidth = UIScreen.main.bounds.width * 0.7 // Maximum width of the message bubble
        let messageInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16) // Insets for the message bubble
        let messageText: String
        
        switch message.kind {
        case .text(let text):
            messageText = text
        default:
            messageText = ""
        }
        
        let messageFont = UIFont.preferredFont(forTextStyle: .body)
        let messageWidth = maxWidth - messageInsets.left - messageInsets.right
        
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        let messageAttributes: [NSAttributedString.Key: Any] = [.font: messageFont]
        let messageSize = CGSize(width: messageWidth, height: .greatestFiniteMagnitude)
        let messageRect = messageText.boundingRect(with: messageSize, options: options, attributes: messageAttributes, context: nil)
        
        let messageInsetsTotalHeight = messageInsets.top + messageInsets.bottom
        let messageHeight = ceil(messageRect.height) + messageInsetsTotalHeight
        
        return CGSize(width: messageWidth, height: messageHeight)
    }
    
    // Other necessary methods can be implemented here
}



extension ChatRoomViewController: MessagesDisplayDelegate {
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        let _: UIColor = isFromCurrentSender(message: message) ? .systemBlue : .lightGray
        return .bubbleTail(corner, .curved)
    }
    
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .systemBlue : .lightGray
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        // AvatarView 설정
    }
    
    // 필요한 메서드를 구현하세요
}

extension ChatRoomViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        let newMessage = Message(sender: currentSender, messageId: UUID().uuidString, sentDate: Date(), kind: .text(text))
        messages.append(newMessage)
        
        inputBar.inputTextView.text = ""
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem(animated: true)
        
        saveMessageToFirestore(message: newMessage)
    }
    
    func saveMessageToFirestore(message: Message) {
        // Firestore에 저장할 데이터 준비
        var documentData: [String: Any] = [
            "senderId": message.sender.senderId,
            "displayName": message.sender.displayName,
            "messageId": message.messageId,
            "sentDate": message.sentDate,
        ]
        
        if case let .text(text) = message.kind {
            documentData["text"] = text
        }
        
        var userFieldData: [String: Any] = [
            "users": [message.sender.senderId, message.sender.displayName],
        ]
        
        
        print("message DB 준비 완료")
        print("senderId: " + message.sender.senderId)
        
        // Firestore에 데이터 저장
        db.collection("chatRooms").document(chatRoomId).collection("messages").document(message.messageId).setData(documentData) { error in
            if let error = error {
                print("Error saving message to Firestore: \(error.localizedDescription)")
            } else {
                print("message data saved!")
            }
        }
        db.collection("chatRooms").document(chatRoomId).setData(userFieldData){ error in
            if let error = error {
                print("Error saving message to Firestore: \(error.localizedDescription)")
            } else {
                print("users data saved!")
            }
        }
    }
}

//extension ChatRoomViewController: UITextViewDelegate {
//    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//        // 엔터(리턴) 키를 눌렀을 때 메시지를 전송하고 텍스트 뷰를 초기화합니다.
//        if text == "\n" {
//            messageInputBar.sendButtonPressed()
//            return false
//        }
//        return true
//    }
//}
