import SwiftUI
import Alamofire
import Starscream
import Foundation
import Combine

// 상대 정보 받는 구조체
struct UserInfo: Decodable {
    let name: String
    let urlCode: String?
    let bio: String?
}

// 사용자 모델: 채팅에 참여하는 사용자 정보를 담는 구조체
struct User: Identifiable {
    let id: String
    let name: String
    let profileImageURL: String
}

// 채팅 메시지 모델: 각 채팅 메시지 정보를 담는 구조체
struct Message: Identifiable, Codable {
    let id: String
    let content: String
    let userID: String
    let timestamp: Date
    let isMyMessage: Bool // 이 메시지가 내가 보낸 메시지인지 구분하기 위한 프로퍼티
    var isRead: Bool // 읽음 여부를 나타내는 프로퍼티
    let messageId: Int
}


//백엔드 응답 값 담는 구조체
struct UserInfoResponse: Decodable {
    let status: Bool
    let code: String?
    let data: UserInfo?
}

//투표 결과 저장하는 구조체
struct CheckVoteResponse: Decodable {
    let status: Bool
    let data: VoteResult?
    let code: String?
    
    struct VoteResult: Decodable {
        let roomId: Int64
        let memberId: Int64
        let result: String
    }
}

// 채팅 뷰 모델: 채팅 화면에서 사용되는 데이터와 기능을 담는 클래스
class ChatViewModel: ObservableObject {
    @Published var isRoomExtended: Bool = false
    @Published var userInfo: UserInfo?
    // 발송된 메시지 목록을 관리할 Observable 배열
    @Published var messages: [Message] = []
    @Published var profileImage: UIImage?
    
    @Environment(\.presentationMode) var presentationMode
    
    
    var loadedMessages: Set<String> = Set()
    
    @Published var isRead: Bool = false // isRead를 @Published 속성으로 변경
    
    func updateIsRead(_ value: Bool) {
        isRead = value
    }
    
    var reconnectTimer: Timer?
    let reconnectInterval: TimeInterval = 30.0 // 10초마다 재연결 시도
    
    var socket: WebSocket!
    var roomId: Int64 // roomId 추가
    var memberId: Int64 // memberId 추가
    
    
    init(roomId: Int64, memberId: Int64) {
        self.roomId = roomId
        self.memberId = memberId
        
        // 웹소켓 설정 및 연결
        let url = URL(string: "https://real.najoa.net/ws?roomId=\(roomId)&memberId=\(memberId)")!
        print("WebSocket URL: \(url)") // URL 출력
        
        
        socket = WebSocket(request: URLRequest(url: url))
        socket.delegate = self
        socket.connect()
        startReconnectTimer()
    }
    
    // 타이머를 시작하여 주기적으로 재연결 시도
    func startReconnectTimer() {
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectInterval, repeats: true) { [weak self] _ in
            self?.socket.connect()
        }
    }
    // 타이머를 시작하여 주기적으로 재연결 시도
    func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    // 메시지를 입력하는 텍스트 필드에 바인딩할 변수
    @Published var newMessage: String = ""
    
    // 투표 결과를 저장할 변수
    @Published var voteResult: [CheckVoteResponse] = []
    
    
    //MARK: - 채팅방 입장 시 상대 정보 가져오기
    func loadUserInfo(roomId: Int64, memberId: Int64) {
        let url = "https://real.najoa.net/joa/room-in-members/chatting-page"
        let parameters: [String: Any] = [
            "roomId": roomId,
            "memberId": memberId
        ]
        
        AF.request(url, method: .get, parameters: parameters)
            .responseDecodable(of: UserInfoResponse.self) { [weak self] response in
                guard let self = self else { return }
                
                switch response.result {
                case .success(let userInfoResponse):
                    if userInfoResponse.status {
                        // 백엔드 응답이 성공인 경우
                        let userInfo = userInfoResponse.data
                        self.userInfo = userInfo
                        
                        // Print received user info values
                        print("Received user info:")
                        print("Name:", userInfo?.name)
                        print("URL Code:", userInfo?.urlCode ?? "Not available")
                        print("Bio:", userInfo?.bio ?? "Not available")
                        
                        if let urlCode = userInfo?.urlCode {
                            let imageUrlString = "https://j-project-2023.s3.ap-northeast-2.amazonaws.com/\(urlCode)"
                            // 이미지를 비동기로 불러오기
                            AF.request(imageUrlString).responseData { response in
                                switch response.result {
                                case .success(let data):
                                    if let loadedImage = UIImage(data: data) {
                                        self.profileImage = loadedImage
                                    } else {
                                        self.profileImage = UIImage(named: "me.png")
                                    }
                                case .failure(_):
                                    self.profileImage = UIImage(named: "me.png")
                                }
                            }
                        } else {
                            self.profileImage = UIImage(named: "me.png")
                        }
                    } else {
                        // 백엔드 응답이 실패인 경우
                        if let code = userInfoResponse.code {
                            switch code {
                            case "M001":
                                self.displayPopup(title: "사용자가 없습니다", message: "해당 사용자를 찾을 수 없습니다.")
                            case "RIM001":
                                self.displayPopup(title: "알 수 없는 오류", message: "지속적인 문제 발생 시 고객센터로 문의 부탁드립니다.")
                            case "R003":
                                self.displayPopup(title: "방이 없습니다", message: "해당 채팅방에 대한 정보가 없습니다.")
                            default:
                                self.displayPopup(title: "알 수 없는 오류", message: "알 수 없는 오류가 발생했습니다.")
                            }
                        }
                    }
                case .failure(let error):
                    print("Failed to load user info:", error.localizedDescription)
                }
                
                if let statusCode = response.response?.statusCode {
                    print("Response Status Code:", statusCode)
                }
            }
    }
    
    
    //MARK: - 방 생성 24시간 여부 판단
    func checkRoomCreationTime(roomId: Int64) {
        
        print("roomId를 백엔드로 전송 중: \(roomId)")
        
        let apiURL = "https://real.najoa.net/joa/rooms/\(roomId)"
        //        let parameters: [String: Any] = ["roomId": roomId]
        
        AF.request(apiURL, method: .get)
            .response { response in
                switch response.result {
                case .success:
                    if let statusCode = response.response?.statusCode {
                        switch statusCode {
                        case 204:
                            // 24시간이 지났을 때만 voteForRoomExtension 호출
                            print("방 생성 24시간 여부 판단")
                            self.voteForRoomExtension(roomId: roomId, memberId: self.memberId, result: "0")
                            
                        case 400:
                            // 24시간이 지났음을 알리는 팝업
                            self.displayPopup(title: "24시간 지남", message: "24시간이 지나 채팅방 연장이 불가능합니다!")
                            
                        case 404:
                            // 잘못된 roomId임을 알리는 팝업
                            self.displayPopup(title: "존재하지 않는 방입니다.", message: "문제가 지속될 시 관리자에게 문의해주세요.")
                            
                        default:
                            break
                        }
                    }
                case .failure(let error):
                    // 기타 에러 처리
                    print("방 생성 시간 확인 에러: \(error.localizedDescription)")
                }
            }
    }
    
    //팝업 띄우는 함수
    func displayPopup(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        
        if let viewController = UIApplication.shared.windows.first?.rootViewController {
            viewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    struct ErrorResponse: Codable {
        let status: Bool
        let code: String?
    }
    
    //MARK: - 채팅방 나가기 API
    func updateExpired(roomId: Int64, memberId: Int64) {
        let apiURL = "https://real.najoa.net/joa/room-in-members/out"
        let parameters: [String: Any] = [
            "roomId": roomId,
            "memberId": memberId
        ]
        
        AF.request(apiURL, method: .patch, parameters: parameters, encoding: JSONEncoding.default)
            .responseDecodable(of: ErrorResponse.self) { response in
                print("Response: \(response.response)")
                print("Data: \(response.data)")
                print("Error: \(response.error)")
                switch response.result {
                case .success(let errorResponse):
                    print("채팅방 나가기 완료")
                    if let errorCode = errorResponse.code {
                        switch errorCode {
                        case "RIM001":
                            self.displayPopup(title: "채팅방을 찾을 수 없음", message: "사용자와 연결된 채팅방을 찾을 수 없습니다.")
                            print("zz")
                        case "R003":
                            self.displayPopup(title: "채팅방을 찾을 수 없음", message: "roomId")
                            print("r003")
                        case "M001":
                            self.displayPopup(title: "사용자를 찾을 수 없음", message: "사용자를 찾을 수 없습니다.")
                        default:
                            break
                        }
                    }
                case .failure(let error):
                    print("API 호출 에러: \(error.localizedDescription)")
                }
        }
    }

    //투표 결과 저장하기 API
    func voteForRoomExtension(roomId: Int64, memberId: Int64, result: String) {
        let apiURL = "https://real.najoa.net/joa/room-in-members/result"
        let parameters: [String: Any] = ["roomId": roomId, "memberId": memberId, "result": result]
        
        AF.request(apiURL, method: .post, parameters: parameters, encoding: JSONEncoding.default)
             .responseDecodable(of: CheckVoteResponse.self) { response in
                 print("Response: \(response.response)")
                 print("Data: \(response.data)")
                 print("Error: \(response.error)")
                 switch response.result {
                 case .success(let CheckVoteResponse):
                     print("투표 결과 저장 API 응답 데이터: \(CheckVoteResponse)")
                     if CheckVoteResponse.status {
                         print("투표 결과가 성공적으로 저장되었습니다.")
                         // 결과에 따라 팝업 표시
                         if let result = CheckVoteResponse.data?.result {
                             if result == "2" {
                                 // 상대방의 투표를 기다려주세요! 팝업 표시
                                 self.displayPopup(title: "연장 신청 완료!", message: "상대방도 연장하기를 누르면 7일간 채팅기간이 연장돼요!")
                             } else if result == "1" {
                                 // 투표가 모두 완료되었을 때의 처리
                                 self.displayPopup(title: "연장 신청 완료!", message: "상대방도 연장하기를 누르면 7일간 채팅기간이 연장돼요!")
                             } else if result == "0" {
                                 // 투표가 모두 완료되었을 때의 처리
                                 self.updateCreatedAtStatus(roomId: roomId, status: "0")
                             }
                         }
                     } else {
                         // 백엔드 응답이 실패인 경우
                         print("투표 결과 저장에 실패했습니다.")
                         if let errorCode = CheckVoteResponse.code {
                             switch errorCode {
                             case "RIM003":
                                 self.displayPopup(title: "투표 실패", message: "이미 채팅방 연장에 대한 투표가 존재합니다.")
                             case "M001":
                                 self.displayPopup(title: "투표 실패", message: "사용자가 존재하지 않습니다.")
                             case "R003":
                                 self.displayPopup(title: "투표 실패", message: "채팅방이 존재하지 않습니다.")
                             case "RIM001":
                                 self.displayPopup(title: "투표 실패", message: "채팅방을 찾을 수 없습니다.")
                             default:
                                 break
                             }
                         }
                     }
                 case .failure(let error):
                     print("투표 결과 저장 API 오류: \(error.localizedDescription)")
                 }
             }
    }

    //MARK: - 방 상태 업데이트 api
    func updateCreatedAtStatus(roomId: Int64, status: String) {
        let apiURL = "https://real.najoa.net/joa/rooms/\(roomId)"
        
        AF.request(apiURL, method: .patch, encoding: JSONEncoding.default)
            .responseJSON { response in
                switch response.result {
                case .success(let data):
                    print("백엔드 응답 데이터: \(data)")
                    self.displayPopup(title: "연장 성공", message: "채팅방 연장에 성공했어요🎉 \n 7일간 채팅을 더 이용할 수 있어요!")
                    
                case .failure(let error):
                    print("API 호출 에러: \(error.localizedDescription)")
                    if let statusCode = response.response?.statusCode {
                        switch statusCode {
                        case 404:
                            self.displayPopup(title: "채팅방 연장 실패", message: "채팅방을 찾을 수 없습니다.")
                        case 409:
                            self.displayPopup(title: "채팅방 연장 실패", message: "이미 연장된 채팅방입니다.")
                        default:
                            break
                        }
                    }
                }
            }
    }
     
    func showPopup(roomId: Int64, memberId: Int64) {
        // 연장 팝업 띄우기
        let alert = UIAlertController(
            title: "연장하기",
            message: "방을 연장하시겠습니까?",
            preferredStyle: .alert
        )
        let confirmAction = UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            // 방 연장 API 호출
            self.checkRoomCreationTime(roomId: roomId)
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        if let rootViewController = UIApplication.shared.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true, completion: nil)
        }
    }

    func showSuccessPopup() {
        let successAlert = UIAlertController(title: "연장 신청 완료!", message: "상대방도 연장하기를 누르면 7일간 채팅기간이 연장돼요!", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "확인", style: .default, handler: nil)
        successAlert.addAction(okAction)
        
        UIApplication.shared.windows.first?.rootViewController?.present(successAlert, animated: true, completion: nil)
    }
    
    //MARK: - 메세지 가져오는 api
    struct MessageResponse: Decodable {
        let status: Bool
        let code: String?
        let data: MessageData?
        
        struct MessageData: Decodable {
            let messageResponseList: [MessageContent]
            
            struct MessageContent: Decodable {
                let content: String
            }
        }
    }
    func loadMessages(roomId: Int64, memberId: Int64) {
        self.messages.removeAll()
        
        let url = "https://real.najoa.net/joa/messages"
        let parameters: [String: Any] = [
            "roomId": roomId,
            "memberId": memberId
        ]
        
        AF.request(url, method: .get, parameters: parameters)
            .responseDecodable(of: MessageResponse.self) { response in
                print("Response: \(response.response)")
                print("Data: \(response.data)")
                print("Error: \(response.error)")
                
                switch response.result {
                case .success(let messageResponse):
                    // API 호출이 성공한 경우
                    if messageResponse.status {
                        if let messageData = messageResponse.data {
                            print("API Response Data:")
                            for messageContent in messageData.messageResponseList {
                                print("- Content:", messageContent.content)
                                
                                // "L"과 "R" 문자를 파싱하여 isMyMessage 설정
                                let isMyMessage = messageContent.content.contains("R") // "R"이 포함된 경우
                                let (isRead, displayContent) = parseMessageContent(messageContent.content)
                                
                                let newMessage = Message(
                                    id: UUID().uuidString,
                                    content: messageContent.content,
                                    userID: "1",
                                    timestamp: Date(),
                                    isMyMessage: isMyMessage,
                                    isRead: isRead, // 읽음/안 읽음 상태 설정
                                    messageId: self.parseMessageId(messageContent.content) // Add 'self.'
                                )
                                
                                print("isRead:", isRead)
                                self.loadedMessages.insert(messageContent.content) // Add the message to the loaded set
                                
                                DispatchQueue.main.async {
                                    self.messages.append(newMessage)
                                }
                            }
                        } else {
                            print("API Response Data is nil.")
                        }
                    } else {
                        // API 호출이 성공했지만 백엔드 응답이 실패한 경우
                        if let code = messageResponse.code, code == "R003" {
                            // "R003"은 방이 존재하지 않음을 나타냄
                            self.displayPopup(title: "방이 존재하지 않습니다!", message: "해당 채팅방에 대한 정보가 없습니다.")
                        } else if let code = messageResponse.code, code == "M001" {
                            // "R003"은 방이 존재하지 않음을 나타냄
                            self.displayPopup(title: "사용자 찾을 수 없다!", message: "해당 채팅방에 대한 정보가 없습니다.")
                        } else if let code = messageResponse.code, code == "RIM001" {
                            // "R003"은 방이 존재하지 않음을 나타냄
                            self.displayPopup(title: "알 수 없는 오류", message: "지속적인 문제 발생 시 고객센터를 통해 문의해주세요.")
                        } else if let code = messageResponse.code, code == "MG003" {
                            // "R003"은 방이 존재하지 않음을 나타냄
                            self.displayPopup(title: "복호화 실패", message: "지속적인 문제 발생 시 고객센터를 통해 문의해주세요.")
                        } else {
                            // 다른 예외 코드 처리
                            self.displayPopup(title: "알 수 없는 오류", message: "알 수 없는 오류가 발생했습니다.")
                        }
                    }
                    
                    // 출력 상태 코드
                    if let statusCode = response.response?.statusCode {
                        print("API Response Status Code:", statusCode)
                    }
                    
                case .failure(let error):
                    // API 호출이 실패한 경우
                    print("API Request Failure:", error.localizedDescription)
                }
            }
    }
    
    // 메시지 content에서 messageId를 추출하는 함수
    func parseMessageId(_ content: String) -> Int {
        let components = content.components(separatedBy: " ")
        guard components.count >= 2, let messageId = Int(components[1]) else {
            return 0 // 적절한 messageId가 없는 경우 0으로 기본값 설정
        }
        return messageId
    }

    
    //MARK: - 메세지 보내기 API
    func sendMessage(roomId: Int64, memberId: Int64, content: String) {
        let newMessage = Message(
            id: UUID().uuidString,
            content: content,
            userID: "userId",
            timestamp: Date(),
            isMyMessage: true,
            isRead: false,
            messageId: 0
        )
        
        print("메세지 보낼 때 isRead:", isRead)
        //self.loadedMessages.insert(messageResponse.content)
        
        DispatchQueue.main.async {
            self.messages.append(newMessage)
            print("메세지 ui에 잘 표시되는 즁")
        }
        // 웹소켓을 통해 메시지 전송
        sendMessageWebSocket(roomId: roomId, memberId: memberId, content: content, isRead: false)
    }
    
    //웹소켓
    func sendMessageWebSocket(roomId: Int64, memberId: Int64, content: String, isRead: Bool) {
        let messageData: [String: Any] = [
            "M": "M",
            "roomId": roomId,
            "memberId": memberId,
            "Content": content,
            "isRead" : true
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: messageData)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            let finalMessage = "M \(roomId) \(memberId) \(content)"
            print("보낸 메시지:", finalMessage)
            socket.write(string: finalMessage)
            
            print("sendMessageWebSocket에서 isRead = ", isRead)
            
        } catch {
            print("JSON 인코딩 에러: \(error.localizedDescription)")
        }
    }
    func updateIsReadForSentMessage(content: String) {
        for index in 0..<messages.count {
            if messages[index].content == content {
                messages[index].isRead = true
                break
            }
        }
    }
}


extension ChatViewModel: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected:
            print("메세지 보내기 웹소켓 연결 성공")
        case .disconnected(let reason, let code):
            print("메세지 보내기 웹소켓 연결 해제 - Reason: \(reason), Code: \(code)")
            if code == 1011 {
                    let messageToShow = "상대방이 JoA를 탈퇴하였습니다."
                reason.contains("상대방이 JoA를 탈퇴하였습니다.")
                    print(messageToShow)
                    // 이후에 이 메시지를 사용하거나 표시하는 등의 작업을 할 수 있습니다.
                }
            stopReconnectTimer()
        case .binary(let data):
            if let message = String(data: data, encoding: .utf8) {
                print("웹소켓에서 수신한 메시지: \(message)")
            } else {
                print("웹소켓에서 수신한 데이터를 문자열로 변환할 수 없습니다.")
            }
        case .ping, .pong, .viabilityChanged, .reconnectSuggested, .cancelled, .error:
            break
        case .text(let message):
            print("웹소켓에서 수신한 텍스트 메시지: \(message)")
            if message == "0" {
                // "0" 메시지를 수신한 경우 이전 메시지 중에서 isRead가 false인 메시지를 true로 변경
                updatePreviousMessagesAsRead()
                updateIsRead(true)
                isRead = true
            } else {
                if message.contains("상대방이 JoA를 탈퇴하였습니다.") || message.contains("채팅방 유효기간이 24시간을 초과하였습니다.") || message.contains("상대방이 채팅방을 나갔습니다.") || message.contains("신고된 채팅방입니다.") || message.contains("채팅방 유효기간이 7일을 초과하였습니다."){
                    
                    let newMessage = Message(
                        id: UUID().uuidString,  // 또는 적절한 값 사용
                        content: message,
                        userID: "userId2",
                        timestamp: Date(),
                        isMyMessage: false,
                        isRead: isRead, messageId: 1
                    )
                    
                    DispatchQueue.main.async {
                        self.messages.append(newMessage)
                    }
                } else {
                    // 특정 조건을 만족하지 않을 때는 파싱을 진행
                    parseWebSocketMessage(message)
                }
            }
            // 수정된 함수: 웹소켓으로 받은 메시지를 파싱하여 UI에 표시
            func parseWebSocketMessage(_ message: String) {
                let components = message.components(separatedBy: " ")
                
                if let messageId = Int(components[0]) {
                    let content = components[1...].joined(separator: " ")
                    
                    let displayContent = content.replacingOccurrences(of: "\(messageId) ", with: " ")
                    
                    
                    let newMessage = Message(
                        id: "\(messageId)",
                        content: displayContent,
                        userID: "userId2",
                        timestamp: Date(),
                        isMyMessage: false,
                        isRead: isRead,
                        messageId: messageId
                    )
                    
                    DispatchQueue.main.async {
                        self.messages.append(newMessage)
                    }
                }
            }
        }
    }
    
    func updatePreviousMessagesAsRead() {
        for index in 0..<messages.count {
          //  if messages[index].isRead == false {
                messages[index].isRead = true
            //}
        }
    }
}

func parseMessageContent(_ content: String) -> (isRead: Bool, displayContent: String) {
    // 메시지 내용을 공백으로 분할
    let components = content.components(separatedBy: " ")
    
    if components.count >= 3 {
        let messageId = components[1]
        let isReadValue = components[2]
        
        if components.count >= 2 {
               let isReadValue = components[2]
                let messageId = components[1]
               
               if isReadValue == "0" {
                   return (isRead: true, displayContent: components[3...].joined(separator: " "))
               } else if isReadValue == "1" {
                   return (isRead: false, displayContent: components[3...].joined(separator: " "))
               }
           }
    }
    // "0" 또는 "1"이 없는 경우 기본적으로 isRead = true로 설정
    return (isRead: false, displayContent: content)
}

struct MessageBubble: View {
    let message: Message
    let isMyMessage: Bool
    @State private var isReportingAlertPresented = false
    @State private var isShowingHint = false
    @State private var reportContent: String = ""
    @State private var selectedReportCategory: Int? // 변경된 부분
    @EnvironmentObject var userData: UserData

    var body: some View {
        
        HStack {
            if message.isMyMessage {
                Spacer()
                let parsedContent = parseMessageContent(message.content)
                
                if !parsedContent.isRead && isMyMessage && !message.isRead{
                    Text("안 읽음")
                        .foregroundColor(.red)
                        .font(.custom("GalmuriMono11", size: 10))
                }else if parsedContent.isRead && isMyMessage && message.isRead{
                    Text("")
                        .foregroundColor(.red)
                        .font(.custom("GalmuriMono11", size: 10))
                }
                
                Text(parseMessageContent(message.content).displayContent)
                    .padding(EdgeInsets(top: 10, leading: 13, bottom: 20, trailing: 13))
                    .font(.custom("GalmuriMono11", size: 13))
                    .background(
                        Image("message.png") // 사용자 메시지 이미지
                            .resizable(capInsets: EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12), resizingMode: .stretch)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    )
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                let parsedContent = parseMessageContent(message.content)
                
                Text(parseMessageContent(message.content).displayContent)
                    .padding(EdgeInsets(top: 15, leading: 15, bottom: 20, trailing: 15))
                    .font(.custom("GalmuriMono11", size: 13))
                    .foregroundColor(.black)
                    .background(
                        Image("Lmessage.png")
                            .resizable(capInsets: EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0), resizingMode: .stretch)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            if !message.isMyMessage {
                Button(action: {
                    isShowingHint = true
                }) {
                    Image(systemName: "heart.slash.fill")
                        .frame(width: 20, height: 20)
                }
                .foregroundColor(Color(hex: "cf7dff"))
                Spacer()
            }
        }
        .padding(.horizontal, 10)
        
        if isShowingHint {
            VStack {
                HStack {
                    Text("메시지 신고하기")
                        .font(.custom("NeoDunggeunmoPro-Regular", size: 23))
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        isShowingHint = false
                    }) {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.black)
                            .frame(width: 20, height: 20)
                    }
                    .padding(.horizontal)
                    
                    Menu {
                        ForEach(0..<3, id: \.self) { index in
                            Button(action: {
                                selectedReportCategory = index + 1
                            }) {
                                Text(reportCategories(index))
                            }
                        }
                    } label: {
                        Image(systemName: "list.dash")
                            .foregroundColor(.black)
                            .frame(width: 20, height: 20)
                    }
                }
                
                // 힌트 내용 대신 신고 내용 입력 필드
                TextField("신고 내용을 입력하세요.", text: $reportContent)
                    .font(.custom("GalmuriMono11", size: 16))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                // "exclamationmark.triangle.fill" 아이콘 대신 "checkmark.circle.fill" 아이콘으로 변경
                Button(action: {
                    if selectedReportCategory == nil {
                        showAlert(title: "입력 오류", message: "신고 카테고리를 선택해주세요!")
                    } else if reportContent.isEmpty {
                        showAlert(title: "입력 오류", message: "신고 사유를 정확하게 입력해주세요!")
                    } else {
                        displayConfirmationPopup()
                    }
                }) {
                    Text("신고하기")
                        .font(.custom("GalmuriMono11", size: 15))
                        .foregroundColor(.black)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "edc639"))
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .frame(maxWidth: .infinity)
            .transition(.move(edge: .bottom))
            .animation(.easeInOut)
        }
    }
    
    func reportCategories(_ index: Int) -> String {
        switch index {
        case 0:
            return "욕설/비방/혐오/차별적 표현"
        case 1:
            return "성희롱"
        case 2:
            return "기타"
        default:
            return ""
        }
    }
    
    func displayConfirmationPopup() {
        let alertController = UIAlertController(title: "허위 신고 경고", message: "허위 신고는 JoA의 운영 체제에 의해 불이악 대상이 됩니다. 해당 내용을 신고하시겠습니까?", preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: "취소", style: .default, handler: nil))

        alertController.addAction(UIAlertAction(title: "확인", style: .destructive, handler: { _ in
                    if let reportCategory = selectedReportCategory { // 변경된 부분
                        reportMessage(message, reportCategory: reportCategory)
                        reportContent = ""
                        isShowingHint = false
                    }
                }))

        if let viewController = UIApplication.shared.windows.first?.rootViewController {
            viewController.present(alertController, animated: true, completion: nil)
        }
    }

    func reportMessage(_ message: Message, reportCategory: Int) {
        // 신고 API 호출
        let apiURL = "https://real.najoa.net/joa/reports/message"
        let parameters: [String: Any] = [
            "messageId": message.messageId,
            "categoryId": reportCategory, // 신고 카테고리 ID를 적절히 설정
            "content": reportContent // 신고 내용 입력
        ]
        print("내가 보낸 값, \(parameters)")
        
        AF.request(apiURL, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseData { response in
                print("Response: \(response.response)")
                print("Data: \(response.data)")
                print("Error: \(response.error)")
                switch response.result {
                case .success(_):
                    if let statusCode = response.response?.statusCode, statusCode == 204 {
                        showAlert(title: "신고 접수 완료", message: "빠른 시일 내에 처리하겠습니다!")
                    } else {
                        // 다른 상태 코드로 인한 실패 처리
                        if let data = response.data {
                            do {
                                let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                                if let code = errorResponse.code {
                                    switch code {
                                    case "MG001":
                                        showAlert(title: "메시지가 없습니다!", message: "메시지가 없습니다!")
                                    case "MR001":
                                        showAlert(title: "이미 신고된 항목", message: "이미 신고된 항목입니다! 얼른 처리해서 알려드리겠습니다!")
                                    case "M001":
                                        showAlert(title: "사용자를 찾을 수 없습니다", message: "사용자를 찾을 수 없습니다.")
                                    case "RC001":
                                        showAlert(title: "신고 항목 미선택", message: "신고항목 선택 후 진행해주세요")
                                    default:
                                        print("Unknown error code: \(code)")
                                    }
                                }
                            } catch {
                                print("Error decoding error response: \(error)")
                            }
                        }
                    }
                case .failure(let error):
                    print("API 호출 에러: \(error.localizedDescription)")
                }
            }
    }

    struct ErrorResponse: Codable {
        let status: Bool
        let code: String?
    }

    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        
        // 현재 화면에 팝업을 표시
        if let viewController = UIApplication.shared.windows.first?.rootViewController {
            viewController.present(alertController, animated: true, completion: nil)
        }
    }
}

struct ChatView: View {
    //세션 id 저장
    @EnvironmentObject var userData: UserData
  //  @StateObject private var viewModel: ChatViewModel
    
    let user: User // 상대방 사용자 정보 전달받음
    let roomId: Int64
    let memberId: Int64 // 이 부분을 추가
    
    @State private var isLeaveChatRoomAlertPresented = false
    @State private var isMessageAlertPresented = false
    @State private var isConfirmationPopupPresented = false // 올바르지 않은 단어 사용할 경우 팝업 상태 속성
    
    @Environment(\.presentationMode) var presentationMode
    @State private var showAlert = false

    @ObservedObject private var viewModel: ChatViewModel
    
    @State private var isMenuVisible = false // 드롭다운 메뉴 표시 여부
    @State private var showTooltip = false
    @State private var timer: Timer?

    func startWebSocketConnection() {
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            self.viewModel.socket.connect()
        }
    }

    public init(user: User, roomId: Int64, memberId: Int64) {
        self.user = user
        self.roomId = roomId
        self.memberId = memberId
        _viewModel = ObservedObject(wrappedValue: ChatViewModel(roomId: roomId, memberId: memberId))
        viewModel.startReconnectTimer() // reconnectTimer 시작
    }

    var body: some View {
        let gradientColors: [Color] = [
            Color(hex: "FFFFFF"),
            Color(hex: "77EFFF"),
            Color(hex: "CBF9FF"),
            Color(hex: "FFFFFF")
        ]
        
        ZStack {
            LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack{
                    if let userInfo = viewModel.userInfo {
                        // 상대방 프로필 이미지
                        if let profileImage = viewModel.profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } else {
                            Image("me.png")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        }
                        
                        VStack{
                            Text(userInfo.name)
                                .font(.custom("NeoDunggeunmoPro-Regular", size: 20))
                            
                            if let bio = userInfo.bio {
                                Text(bio)
                                    .font(.custom("GalmuriMono11", size: 10))
                            }
                        }
                        .padding(.trailing, 20)
                    }
                    
                    Menu {
                        Button(action: {
                            isLeaveChatRoomAlertPresented = true
                            print("isLeaveChatRoomAlertPresented:", isLeaveChatRoomAlertPresented)
                        }) {
                            Label("나가기", systemImage: "arrow.left.square")
                        }
                        
                        Button(action: {
                            // 연장하기 버튼 클릭 시 실행할 코드
                            if let userId = userData.userId {
                                viewModel.showPopup(roomId: roomId, memberId: userId)
                            }
                        }) {
                            Label("연장하기", systemImage: "clock.arrow.circlepath")
                        }
                    } label: {
                        HStack {
                            Image(systemName: "heart.rectangle")
                                .foregroundColor(Color(hex: "ff596a"))
                                .imageScale(.large) // 아이콘의 크기 설정
                        }
                    }.alert(isPresented: $isLeaveChatRoomAlertPresented) {
                        Alert(
                            title: Text("채팅방 나가기"),
                            message: Text("정말 채팅방을 나가시겠습니까?"),
                            primaryButton: .default(Text("확인"), action: {
                                // 확인 버튼 눌렀을 때 실행할 코드
                                if let userId = userData.userId {
                                    viewModel.updateExpired(roomId: roomId, memberId: userId)
                                    //presentationMode.wrappedValue.dismiss()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }
                            }),
                            secondaryButton: .cancel(Text("취소"))
                        )
                    }
                    
                    
                    Image(systemName: "questionmark.circle")
                        .imageScale(.medium)
                        .padding(.leading, 5)
                        .onTapGesture {
                            // 버튼을 누를 때 툴팁을 표시
                            showTooltip.toggle()
                            // 5초 후에 툴팁을 자동으로 닫기
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                                showTooltip = false
                            }
                        }
                    //      .padding(.trailing, 80) 왼쪽 여백
                        .overlay(
                            TooltipOverlay(message: "상대방이 무분별한 욕설, 비방 등 기분이 나쁠만한 언행을 한다면, 주저하지 말고 메시지 신고 버튼을 눌러서 JoA 운영자에게 알려주세요!")
                                .opacity(showTooltip ? 1 : 0)
                                .animation(.easeInOut(duration: 0.3))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .offset(x:-80) // 버튼 아래로 이동
                                .opacity(1)
                        )
                        .onTapGesture {
                            // 다른 부분을 탭했을 때 툴팁 닫기
                            showTooltip = false
                        }
                }
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(viewModel.messages) { message in
                                if message.content.contains("상대방이 JoA를 탈퇴하였습니다.") ||
                                    message.content.contains("채팅방 유효기간이 24시간을 초과하였습니다.") ||
                                    message.content.contains("상대방이 채팅방을 나갔습니다.") ||
                                    message.content.contains("신고된 채팅방입니다.") ||
                                    message.content.contains("채팅방 유효기간이 7일을 초과하였습니다.") {
                                    SystemMessageView(message: message.content)
                                } else {
                                    MessageBubble(message: message, isMyMessage: message.isMyMessage)
                                        .id(message.id)
                                }
                            }
                        }
                    }
                    .onAppear {
                        // 스크롤뷰를 처음에 가장 아래로 스크롤
                        withAnimation {
                            proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                            //self.viewModel.socket.connect()
                        }
                        // 키보드 나타남 이벤트 등록
//                        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
//                            // 키보드 높이만큼 스크롤 조정
//                            withAnimation {
//                                proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
//                            }
//                        }
                    }
                    .onChange(of: viewModel.messages.count) { _ in
                        // 새 메시지가 추가되면 자동으로 스크롤
                        withAnimation {
                            proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                        }
                    }
                    .coordinateSpace(name: "scroll")
                }
                
                HStack {
                    TextField("메시지를 입력하세요", text: $viewModel.newMessage)
                        .font(.custom("GalmuriMono11", size: 14))
                        .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                        .background(Color.white)
                        .cornerRadius(10)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.default)
                    
                    Button(action: {
                        if let userId = userData.userId, !viewModel.newMessage.trimmingCharacters(in: .whitespaces).isEmpty {
                            let filteredMessage = viewModel.filterProfanity(viewModel.newMessage)
                            viewModel.sendMessage(roomId: roomId, memberId: memberId, content: filteredMessage)
                            viewModel.newMessage = "" // 메시지 전송 후 입력 필드를 비워줍니다.
                        } else {
                            isMessageAlertPresented = true // 빈 메시지 또는 띄어쓰기만 있는 메시지일 때 경고 팝업 표시
                        }
                    }) {
                        VStack {
                            Image(systemName: "paperplane.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(Color(hex: "ffaba1"))
                                .clipShape(Rectangle())
                                .cornerRadius(10)
                                .padding(EdgeInsets(top: 5, leading: 5, bottom: 0, trailing: 5))
                        }
                        .alert(isPresented: $isMessageAlertPresented) {
                            Alert(
                                title: Text("메시지 입력"),
                                message: Text("메시지를 입력하고 보내주세요!"),
                                dismissButton: .default(Text("확인"))
                            )
                        }
                    }
                    .padding()
                    .onAppear {
                        startWebSocketConnection()
                        if let userId = userData.userId {
                            viewModel.loadMessages(roomId: roomId, memberId: userId)
                            viewModel.loadUserInfo(roomId: roomId, memberId: userId)
                            
                            let cancellable = Just(0)
                                .delay(for: .seconds(0.3), scheduler: DispatchQueue.main)
                                .sink { _ in
                                    self.viewModel.socket.connect()
                                    print("웹소켓 연결됨 chatview")
                                }
                        }
                    }.onDisappear {
                        // 화면이 사라질 때 웹소켓 연결을 끊습니다.
                        self.viewModel.socket.disconnect()
                        self.viewModel.stopReconnectTimer()
                        print("웹소켓 꺼졌음 chatview")
                    }
                }
            }
        }
    }
    
    // 웹소켓에서 수신한 문장 5개 보이게 하는 거
    struct SystemMessageView: View {
        let message: String
        
        var body: some View {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.gray.opacity(0.6)) // 회색의 투명도 조절
                .padding(5)
                .overlay(
                    Text(message)
                        .foregroundColor(.white)
                        .font(.custom("GalmuriMono11", size: 14))
                        .multilineTextAlignment(.center)
                )
                .frame(height: 40) // 높이를 60으로 설정
        }
    }

    struct TooltipOverlay: View {
        var message: String

        var body: some View {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                        Text(message)
                            .foregroundColor(.black)
                            .padding()
                            .multilineTextAlignment(.center)
                            .font(.custom("Galmuri14", size: 14))
                    }
                    .frame(width: 350, height: 80)
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

//struct ChatView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChatViewModel(roomId: 44, memberId: 5518308257)
//    }
//}
