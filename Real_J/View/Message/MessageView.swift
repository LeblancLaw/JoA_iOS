import SwiftUI
import Starscream
import Alamofire

class ChatRoom: Identifiable, ObservableObject {
    @Published var id: Int64
    @Published var user: User
    @Published var unCheckedMessage: String
    @Published var lastMessage: String
    @Published var chatRooms: [ChatRoom] = [] // 추가
    @Published var profileImage: Image?

    init(id: Int64, user: User, unCheckedMessage: String, lastMessage: String) {
        self.id = id
        self.user = user
        self.unCheckedMessage = unCheckedMessage
        self.lastMessage = lastMessage
    }
}

struct RoomDTO: Decodable {
    let roomId: Int64
    let name: String
    let urlCode: String?
    let content: String?
    let unCheckedMessage: String
}

struct ResponseDTO: Decodable {
    let status: Bool
    let code: String?
    let data: RoomListDTO?
}

struct RoomListDTO: Decodable {
    let roomListVOs: [RoomDTO]
}


struct MessageView: View {
    @State private var chatRooms: [ChatRoom] = []
    @ObservedObject var messageWebSocketManager: WebSocketManager // MessageView용 웹소켓 매니저
    @EnvironmentObject var userData: UserData
    @State private var webSocketTimer: Timer?
    @State private var isRefreshing = false

    
    func startWebSocketCalling() {
        // 타이머를 시작하고 30초마다 WebSocketManager의 함수를 호출
        webSocketTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            self.messageWebSocketManager.disconnect()
            self.messageWebSocketManager.establishConnection()
        }
    }
    
    func loadChatRooms(memberId: Int64) {
        if let memberId = userData.userId {
            let url = "https://real.najoa.net/joa/room-in-members/\(memberId)"
            AF.request(url, method: .get)
                .responseDecodable(of: ResponseDTO.self) { response in
                    print("Response: \(response.response)")
                    print("Data: \(response.data)")
                    print("Error: \(response.error)")
                    switch response.result {
                    case .success(let responseDTO):
                        if responseDTO.status {
                            if let roomListDTO = responseDTO.data {
                                // 방 목록이 있는 경우
                                self.chatRooms = roomListDTO.roomListVOs.map { roomDTO in
                                    let user = User(id: String(roomDTO.roomId), name: roomDTO.name, profileImageURL: roomDTO.urlCode ?? "")
                                    print(roomDTO.roomId) //룸 아이디확인하기
                                    return ChatRoom(id: roomDTO.roomId, user: user, unCheckedMessage: roomDTO.unCheckedMessage, lastMessage: roomDTO.content ?? "")
                                }
                                self.messageWebSocketManager.chatRooms = self.chatRooms
                            }
                        } else {
                            if let code = responseDTO.code {
                                switch code {
                                case "M001":
                                    self.displayPopup(title: "사용자가 존재하지 않습니다!", message: "사용자가 존재하지 않습니다! 회원가입 혹은 로그인 해주세요.")
                                case "M004":
                                    self.displayPopup(title: "이용불가!", message: "회원님은 일시정지 대상으로 JoA 이용이 일시적으로 불가능합니다.")
                                case "M014":
                                    self.displayPopup(title: "이용불가!", message: "회원님은 영구정지 대상으로 JoA 이용이 불가능합니다.")
                                case "RIM001":
                                    self.displayPopup(title: "채팅방 찾을 수 없음", message: "채팅방을 찾을 수 없습니다.")
                                case "MG003":
                                    self.displayPopup(title: "메시지 복호화 실패", message: "채팅방을 찾을 수 없습니다. 지속적인 문제 발생 시 관리자에게 문의해주세요.")
                                default:
                                    self.displayPopup(title: "에러", message: "서버에서 유효한 응답을 받지 못했습니다. \n 관리자에게 문의하세요.")
                                }
                            }
                        }
                    case .failure(let error):
                        print("네트워크 오류: \(error.localizedDescription)")
                    }
                }
        }
    }


    func displayPopup(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        
        if let viewController = UIApplication.shared.windows.first?.rootViewController {
            viewController.present(alertController, animated: true, completion: nil)
        }
    }
    
//    func loadChatRooms(memberId: Int64) {
//        // 더미 데이터 생성
//        let dummyRoomDTOs: [RoomDTO] = [
//            RoomDTO(roomId: 1, name: "한요한", urlCode: "me.png", content: "Hello, how are you?", unCheckedMessage: "2"),
//            RoomDTO(roomId: 2, name: "이도현", urlCode: "me.png", content: "Hi there!", unCheckedMessage: "1"),
//            RoomDTO(roomId: 3, name: "김승민", urlCode: "me.png", content: "Hey!", unCheckedMessage: "0"),
//        ]
//
//        self.chatRooms = dummyRoomDTOs.map { roomDTO in
//            let user = User(id: String(roomDTO.roomId), name: roomDTO.name, profileImageURL: roomDTO.urlCode ?? "")
//            let unCheckedMessage = roomDTO.unCheckedMessage
//            let lastMessage = roomDTO.content ?? ""
//            return ChatRoom(id: roomDTO.roomId, user: user, unCheckedMessage: unCheckedMessage, lastMessage: lastMessage)
//        }
//
//        // 데이터를 가져온 후 messageWebSocketManager.chatRooms 배열 업데이트
//        self.messageWebSocketManager.chatRooms = self.chatRooms
//    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [
                    Color(hex: "FFFFFF"),
                    Color(hex: "77EFFF"),
                    Color(hex: "CBF9FF"),
                    Color(hex: "FFFFFF")
                ]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                    Spacer()
                    Spacer()
                    
                    HStack {
                        Image("main")
                            .resizable()
                            .frame(width: 60, height: 60)
                        VStack {
                            Text("채팅")
                                .font(.custom("NeoDunggeunmoPro-Regular", size: 35))
                                .foregroundColor(.black)
                            
                            Text("24시간 동안 서로를 알아가보세요! \n채팅방을 연장하면 일주일 더 상대를 알아갈 수 있어요.")
                                .multilineTextAlignment(.center)
                                .font(.custom("Galmuri14", size: 10))
                                .foregroundColor(.black)
                        }
                    }
                    
                    ScrollView {
                        ForEach(messageWebSocketManager.chatRooms) { room in
                            NavigationLink(destination: ChatViewContainer(user: room.user, roomId: room.id, memberId: userData.userId ?? 0)) {
                                HStack {
                                    AsyncImage(url: URL(string: "https://j-project-2023.s3.ap-northeast-2.amazonaws.com/\(room.user.profileImageURL)")) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .frame(width: 60, height: 60)
                                                .aspectRatio(contentMode: .fit)
                                                .clipShape(Circle())
                                                .padding(.trailing, 5)
                                        } else if phase.error != nil {
                                            Image("me.png") // 이미지 로딩 에러 시 기본 이미지 표시
                                                .resizable()
                                                .frame(width: 60, height: 60)
                                                .clipShape(Circle())
                                                .padding(.trailing, 5)
                                        }
                                    }
                                }
                                VStack(alignment: .leading) {
                                    Text(room.user.name)
                                        .font(.custom("Galmuri14", size: 20))
                                        .foregroundColor(.black)
                                    
                                    Text(room.lastMessage)
                                        .font(.custom("Galmuri14", size: 15))
                                        .foregroundColor(.black)
                                }
                                Spacer()
                                HStack {
                                    Spacer()
                                    Text(room.unCheckedMessage)
                                        .font(.custom("Galmuri14", size: 12))
                                        .foregroundColor(.black)
                                        .padding(10)
                                        .background(Circle().fill(Color(hex: "ffddff")))
                                }
                                
                            }.frame(width: 350, height: 55)
                                .padding(10) // 간격 조정
                                .background(Color.clear) // 배경색
                                .cornerRadius(10) // 모서리를 둥글게 만듦
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray, lineWidth: 1) // 회색 선
                                )
                            
                        }.onDisappear {
                            // ChatView로 나갈 때 WebSocket 연결을 끊기게 => NavigationLink 바로 밖에 위치해야 작동함
                            self.messageWebSocketManager.disconnect()
                            //                                self.webSocketTimer?.invalidate()
                            //                                self.webSocketTimer = nil
                            print("chatview로 들어가서 웹소켓 끊기")
                        }
                    }
                    // .navigationBarTitle("채팅 목록", displayMode: .inline)
                }.onAppear {
                    if let userId = userData.userId {
                        self.messageWebSocketManager.establishConnection()
                        print("messageView 웹소켓 연결됨")
                        loadChatRooms(memberId: userId)
                        print("함수 호출 됨됨 \(userId)")
                        
                    } else {
                        print("userData.userId is nil")
                    }
                } .onDisappear {
                    // 화면이 사라질 때 웹소켓 연결을 끊습니다.
                    self.messageWebSocketManager.disconnect()
                    print("message View 나가서 웹소켓 끊기")
                    //                    self.webSocketTimer?.invalidate()
                    //                    self.webSocketTimer = nil
                }
            }
        }
        }
    }

struct ChatViewContainer: View {
    
    let user: User
    let roomId: Int64
    let memberId: Int64
    
    var body: some View {
        // ChatView에 대한 초기화 및 웹소켓 연결을 수행
        ChatView(user: user, roomId: roomId, memberId: memberId)
    }
}

class WebSocketManager: ObservableObject, WebSocketDelegate {
    @Published var chatRooms: [ChatRoom] = []
    @Published var isConnected = false
    @Published var receivedMessages: [ChatRoom] = [] //1027 추가
    @EnvironmentObject var userData: UserData

    private var socket: WebSocket?
    private let memberId: Int64
    
        // 채팅방을 업데이트하고 가장 최근 메시지를 기준으로 정렬하는 메서드
        func updateChatRooms(with newMessage: ChatRoom) {
            if let existingIndex = chatRooms.firstIndex(where: { $0.id == newMessage.id }) {
                chatRooms.remove(at: existingIndex)
            }
            chatRooms.insert(newMessage, at: 0) // 새 메시지를 가장 위에 추가
           // chatRooms.sort { $0.lastMessage > $1.lastMessage } // 가장 최근 메시지를 기준으로 정렬
            objectWillChange.send() // SwiftUI에 변경을 알립니다
        }
    
    func disconnect() {
        socket?.disconnect()
    }
    
    init(memberId: Int64) {
        self.memberId = memberId
    }
    
    func reconnectWebSocket() {
        // 연결이 끊어진 경우 다시 연결을 시도
        establishConnection()
    }
    
    func establishConnection() {
        //let socketURL = URL(string: "https://real.najoa.net/ws?memberId=21)")! // 실제 웹소켓 서버 URL로 변경
        let socketURL = URL(string: "https://real.najoa.net/ws?memberId=\(memberId)")! // 실제 웹소켓 서버 URL로 변경
        
        socket = WebSocket(request: URLRequest(url: socketURL))  // Use URLRequest
        socket?.delegate = self
        socket?.connect()
    }
    
    func parseWebSocketText(_ text: String) -> ChatRoom? {
        print("파싱됐는댜")
        print("WebSocket message: \(text)")
        
        
        let components = text.components(separatedBy: " ") // 문자열을 공백으로 분리
        print("Components count: \(components.count)")
        print("Components: \(components)")
        
        if components.count >= 5 {
            let roomId = Int64(components[0]) ?? 0
            let name = components[1]
            let urlCode = components[2]
            let unCheckedMessage = components[3]
            let lastMessage = components[4...].joined(separator: " ")
            
            let user = User(id: String(roomId), name: name, profileImageURL: urlCode)
            let newMessage = ChatRoom(id: roomId, user: user, unCheckedMessage: unCheckedMessage, lastMessage: lastMessage)
            
            DispatchQueue.main.async {
                self.processReceivedMessage(newMessage)
            }
        }
        return nil
    }
    
    func processReceivedMessage(_ newMessage: ChatRoom) {
        // 기존에 채팅방이 이미 존재하는지 확인하고 업데이트하거나 추가합니다.
        if let existingIndex = chatRooms.firstIndex(where: { $0.id == newMessage.id }) {
            chatRooms[existingIndex].user = newMessage.user
            chatRooms[existingIndex].unCheckedMessage = newMessage.unCheckedMessage
            chatRooms[existingIndex].lastMessage = newMessage.lastMessage
            
            // 기존에 있던 채팅방을 배열의 맨 앞으로 이동시킵니다.
            let movedChatRoom = chatRooms.remove(at: existingIndex)
            chatRooms.insert(movedChatRoom, at: 0)
        } else {
            // 채팅방을 추가하고 배열의 맨 앞으로 이동시킵니다.
            chatRooms.insert(newMessage, at: 0)
        }
        
        objectWillChange.send() // SwiftUI에 변경을 알립니다
    }
    
    func loadChatRooms(memberId: Int64) {
        
        if let memberId = userData.userId {
            let url = "https://real.najoa.net/joa/room-in-members?memberId=\(memberId)"
            
            AF.request(url, method: .get)
                .responseDecodable(of: [RoomDTO].self) { response in
                    switch response.result {
                    case .success(let roomListDTO):
                        self.chatRooms = roomListDTO.map { roomDTO in
                            let user = User(id: String(roomDTO.roomId), name: roomDTO.name, profileImageURL: roomDTO.urlCode ?? "")
                            let unCheckedMessage = roomDTO.unCheckedMessage
                            let lastMessage = roomDTO.content ?? ""
                            return ChatRoom(id: roomDTO.roomId, user: user, unCheckedMessage: unCheckedMessage, lastMessage: lastMessage)
                        }
                        print("(룸리스트 가져온거 2\(roomListDTO))")
                        
                    case .failure(let error):
                        print("load chat room API 에러:", error.localizedDescription)
                        if let statusCode = response.response?.statusCode, statusCode == 401 {
                            self.displayPopup(title: "이용불가!", message: "회원님은 일시정지 대상으로 JoA 이용이 일시적으로 불가능합니다.")
                        }
                    }
                }
        }
    }
    
    func displayPopup(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        
        if let viewController = UIApplication.shared.windows.first?.rootViewController {
            viewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected:
            isConnected = true
            print("WebSocket connected = messageview 입장해서")
        case .disconnected(let reason, let code):
            isConnected = false
            if code == 1000 {
                reconnectWebSocket()
            }
            print("WebSocket disconnected: \(reason) with code \(code)")
        case .text(let text):
            print("WebSocket received text: \(text)")
          //  print("WebSocket received text: \(text)")
            if let chatRoom = parseWebSocketText(text) {
                if let existingIndex = chatRooms.firstIndex(where: { $0.id == chatRoom.id }) {
                    chatRooms[existingIndex] = chatRoom
                } else {
                    chatRooms.append(chatRoom)
                }
                objectWillChange.send() // SwiftUI에 변경 알림
            }
        default:
            break
        }
    }
}

//struct MessageView_Previews: PreviewProvider {
//    static var previews: some View {
//        let dummyMemberId: Int64 = 2104662737 // 더미 memberId 설정
//        let dummyWebSocketManager = WebSocketManager(memberId: dummyMemberId)
//        
//        // 더미 채팅룸 데이터 생성
//        let dummyChatRooms: [ChatRoom] = [
//            ChatRoom(id: 4, user: User(id: "4", name: "홍향미", profileImageURL: ""), unCheckedMessage: "2", lastMessage: "Hello"),
//            ChatRoom(id: 2, user: User(id: "2", name: "한요한", profileImageURL: ""), unCheckedMessage: "1", lastMessage: "Hi"),
//            ChatRoom(id: 3, user: User(id: "3", name: "한태산", profileImageURL: ""), unCheckedMessage: "0", lastMessage: ""),
//        ]
//        
//        dummyWebSocketManager.chatRooms = dummyChatRooms
//        
//        return MessageView(messageWebSocketManager: dummyWebSocketManager)
//            .environmentObject(UserData())
//    }
//}

