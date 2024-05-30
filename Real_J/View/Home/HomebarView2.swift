import SwiftUI
import Starscream
import Alamofire
import SDWebImageSwiftUI
import Foundation

// create Room 할 때
struct CreateRoom: Codable {
    let action: String? // 액션 (여기서는 "R"로 설정).
    var roomId: Int64? // 방의 ID (임의의 정수로 설정).
    let memberId1: Int64 // 내 거야!
    let memberId2: Int64 // 상대방
    
    enum CodingKeys: String, CodingKey {
        case action, roomId, memberId1, memberId2
    }
}

struct ApiResponse: Decodable {
    let status: Bool
    let data: NearByList?
    let code: String?
}

struct NearByList: Decodable {
    let nearByList: [NearByInfo]?
}

struct NearByInfo: Identifiable, Decodable {
    let id: Int64
    let name: String
    var urlCode: String?
    let bio: String
    let isLiked: Bool
}

// 하트 데이터 보낼 때
struct HeartData: Codable {
    let giveId: Int64 // 하트를 보내는 사용자의 ID (여기서는 ID 1번).
    let takeId: Int64 // 하트를 받는 사용자의 ID (여기서는 ID 2번).
    let named: Bool
}

struct ResponseModel2: Decodable {
    let status: Bool
    let data: RoomData?
    
    struct RoomData: Decodable {
        let roomId: Int
    }
}

struct HeartResponseData: Codable {
    let isMatched: Bool
    let giveName: String
    let takeName: String
    let giveUrlCode: String
    let takeUrlCode: String
}

struct HeartResponseModel: Codable {
    let status: Bool
    let data: HeartResponseData?
    let code: String?
}

struct ResponseModel: Codable {
    let code: String?
    let status: Bool
    let data: RoomData?
    let isMatched: Bool?
    let giveName: String?
    let giveUrlCode: String?
    let takeUrlCode: String?
    let roomExists: Bool?
    let isContained: Bool? // isContained를 ResponseModel에 추가
    let roomId: Int64? // roomId를 추가
}

struct RoomData: Codable {
    let roomId: Int64?
}

class SocketEnvironment: ObservableObject {
    var socket: WebSocket!
    init() {
        // WebSocket URL (Update with your server URL)
        let urlString = "https://real.najoa.net/ws"
        if let url = URL(string: urlString) {
            socket = WebSocket(request: URLRequest(url: url))
            socket.connect()
        }
    }
}

struct ProfileItemView: View {
    @Binding var showCongratulatoryPopup: Bool
    @State private var roomCreated = false //채팅방 목록 불러오기
    @State private var roomID: Int64? // 생성된 채팅방의 ID를 저장할 변수
    @Binding var profile: NearByInfo // 바인딩 타입을 NearByInfo로 변경
    @State private var isLiked: Bool = false // 추가: 상태를 저장할 프로퍼티 추가
    @State private var showAlert = false // 팝업창을 보여줄지 여부
    @State private var alertTitle = "" // 팝업창 타이틀
    @State private var alertMessage = "" // 팝업창 메시지
    @EnvironmentObject var userData: UserData
    @Binding var isAnonymous: Bool // 이 부분을 추가해야 합니다
    @State private var matchedUserId: Int64? = nil // 매칭된 사용자의 ID
    @StateObject var socketEnv = SocketEnvironment() // 상위 뷰에서 생성
    
    @State private var image: Image? // 프로필 사진 이미지 1106 수정
    
    @State private var refreshPage = false //차단 후 새로고침
    
    init(showCongratulatoryPopup: Binding<Bool>, profile: Binding<NearByInfo>, isAnonymous: Binding<Bool>) {
        self._showCongratulatoryPopup = showCongratulatoryPopup
        self._profile = profile
        self._isAnonymous = isAnonymous
        self._matchedUserId = State(initialValue: nil)
    }
    var body: some View { //주변 목록 리스트 ui
        
        HStack {
            ZStack {
                Image("people.png") // 배경 이미지
                    .resizable()
                //.scaledToFill()
                    .frame(width: 420, height: 85) // 배경 이미지 크기 조정
                
                if profile.isLiked {
                    Rectangle() // 직사각형 이미지
                        .stroke(Color.black, lineWidth: 10)
                        .background(Color.white) // 배경 색상 설정
                        .cornerRadius(20) // 모서리 둥글기 설정
                        .frame(width: 420, height: 85) // 이미지 크기 조정
                }
                HStack {
                    if let urlCode = URL(string: "https://j-project-2023.s3.ap-northeast-2.amazonaws.com/\(profile.urlCode)") {
                        AsyncImage(url: URL(string: profile.urlCode ?? "")) { phase in
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
                    } else {
                        Image("me.png") // 이미지 URL이 nil일 때 기본 이미지 표시
                            .resizable()
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .padding(.trailing, 5)
                    }
                }
                .padding(.trailing, 250)
                
                VStack(alignment: .leading) {
                    Text(profile.name)
                        .font(.custom("NeoDunggeunmoPro-Regular", size: 35))
                        .foregroundColor(.black)
                        .padding(.trailing, 10)
                        .gesture(
                            LongPressGesture(minimumDuration: 1)
                                .onEnded { _ in
                                    // 2초 이상 눌렀을 때의 동작
                                    showReportPopup(memberIdToReport: profile.id)
                                }
                        )
                    
                    Text(profile.bio) // "한 줄 소개" 정보를 표시합니다
                        .font(.custom("Galmuri14", size: 12))
                        .foregroundColor(.gray)
                        .padding(.trailing, 10)
                }
                
                HStack{
                    Button(action: {
                        if !isLiked {
                            isLiked.toggle()
                            if let userId = userData.userId {
                                //let heartData = HeartData(giveId: userId, takeId: profile.id, named: isAnonymous)
                                messageReport(memberId1: userId, memberId2: profile.id)
                                //sendHeartData(heartData: heartData)
                            }
                        }
                    }) {
                        if isLiked {
                            Image("heart2.png")
                                .resizable()
                                .frame(width: 45, height: 40)
                        } else {
                            Image("Eheart.png")
                                .resizable()
                                .foregroundColor(.black)
                                .frame(width: 60, height: 60)
                        }
                    }.padding(.leading, 260)
                }
                .alert(isPresented: $showCongratulatoryPopup) {
                    Alert(
                        title: Text("축하합니다!"),
                        message: Text("서로 하트를 눌렀어요! 채팅방이 생성됐습니다."),
                        dismissButton: .default(Text("확인"), action: {
                        })
                    )
                }
            }
        }
    }
    
    // 팝업 표시 함수
    func showReportPopup(memberIdToReport: Int64) {
        let alertController = UIAlertController(title: "차단", message: "\(profile.name) 님을 차단하시겠습니까? \n 차단 후 해당 사용자는 친구 목록에서 보이지 않아요.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            // 확인 버튼이 눌렸을 때의 동작
            if let userId = userData.userId {
                reportMember(memberIdToReport: memberIdToReport)
            }
        })
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        if let viewController = UIApplication.shared.windows.first?.rootViewController {
            viewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    func showReportPopup() {
        showCongratulatoryPopup = true
    }
    
    //MARK: - 차단하기
    func reportMember(memberIdToReport: Int64) {
        let parameters: [String: Any] = [
            "blockerId": userData.userId,
            "blockedId": profile.id
        ]
        print("\(parameters)")
        
        AF.request("https://real.najoa.net/joa/blocks", method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    if let status = response.response?.statusCode {
                        print("API 호출 성공 - Status: \(status), Response: \(value)")
                        
                        if status == 204 {
                            // 성공적으로 차단이 수행되었을 경우
                            DispatchQueue.main.async {
                                self.displayPopup(title: "차단 성공", message: "해당 사용자를 성공적으로 차단했습니다.")
                            }
                        } else {
                            if let responseDict = value as? [String: Any] {
                                if let isSuccess = responseDict["status"] as? Bool {
                                    if isSuccess {
                                        print("해당 사용자를 차단 완료 했습니다!")
                                        DispatchQueue.main.async {
                                            self.refreshPage.toggle()
                                            self.displayPopup(title: "차단 완료", message: "주변 친구 찾아보기 버튼을 새로고침하면 \n 해당 사용자가 이제 뜨지 않아요. \n 신고된 사용자에 대해서는 빠른 조치 해드리겠습니다!")
                                        }
                                        
                                    } else {
                                        if let code = responseDict["code"] as? String {
                                            DispatchQueue.main.async {
                                                self.handleAPIError(code: code)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                case .failure(let error):
                    // API 호출 실패한 경우
                    print("API 호출 실패: \(error)")
                    // Handle the failure case as needed
                }
            }
    }
    
    // API 호출 실패 시 에러 처리
    func handleAPIError(code: String) {
        var errorMessage = ""
        switch code {
        case "M001":
            errorMessage = "사용자를 찾을 수 없습니다. \n 관리자에게 문의하세요."
        case "M002":
            errorMessage = "위치를 찾을 수 없습니다. 위치 서비스 허용 후 재시도 해주세요."
        case "B002":
            errorMessage = "이미 차단한 사용자입니다."
        default:
            errorMessage = "서버에서 유효한 응답을 받지 못했습니다. \n 관리자에게 문의하세요."
        }
        DispatchQueue.main.async {
            self.displayPopup(title: "에러", message: errorMessage)
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
    
    //웹소켓 연결 매칭 된 후에 되게 하려고
    func establishWebSocketConnectionIfNeeded() {
        if let matchedUserId = matchedUserId, let userId = userData.userId {
            let socketURL = "https://real.najoa.net/ws"
            let socket = WebSocket(request: URLRequest(url: URL(string: socketURL)!))
            socket.connect()
        }
    }

    // 하트 데이터를 백엔드로 전송하는 함수
    func sendHeartData(heartData: HeartData) {
        let url = "https://real.najoa.net/joa/hearts"
        AF.request(url, method: .post, parameters: heartData, encoder: JSONParameterEncoder.default)
            .response { response in
                print("\(heartData)")
                if let data = response.data,
                   let jsonString = String(data: data, encoding: .utf8) {
                    
                    print("하트 Response: \(response.response)")
                    print("하트 Data: \(response.data)")
                    print("하트 Error: \(response.error)")
                    print("하트 Sent Heart Data:")
                    print(jsonString)
                    do {
                        let decoder = JSONDecoder()
                        let heartResponseModel = try decoder.decode(HeartResponseModel.self, from: data)
                        print("서버 응답:")
                        print(heartResponseModel)
                        print("하트 isMatched: \(heartResponseModel.data?.isMatched ?? false)")
                        
                        if let errorCode = heartResponseModel.code {
                            switch errorCode {
                            case "B001":
                                DispatchQueue.main.async {
                                    displayPopup(title: "이용불가!", message: "해당 사용자를 차단한 경우 하트를 보낼 수 없습니다.")
                                }
                            case "H001":
                                DispatchQueue.main.async {
                                    displayPopup(title: "이용불가!", message: "이미 하트를 보냈습니다. 다른 사용자에게 하트를 보내주세요.")
                                }
                            case "R001":
                                DispatchQueue.main.async {
                                    displayPopup(title: "이용불가!", message: "이미 채팅방이 존재합니다.")
                                }
                            case "M002":
                                DispatchQueue.main.async {
                                    displayPopup(title: "이용불가!", message: "위치를 찾을 수 없습니다.")
                                }
                            case "M004":
                                DispatchQueue.main.async {
                                    displayPopup(title: "이용불가!", message: "회원님은 일시정지 대상으로 JoA 이용이 일시적으로 불가능합니다.")
                                }
                            case "M014":
                                DispatchQueue.main.async {
                                    displayPopup(title: "이용불가!", message: "회원님은 영구정지 대상으로 JoA 이용이 불가능합니다.")
                                }
                            default:
                                DispatchQueue.main.async {
                                    displayPopup(title: "에러!", message: "서버에서 유효한 응답을 받지 못했습니다. \n 관리자에게 문의하세요.")
                                }
                            }
                        } else {
                            if heartResponseModel.data?.isMatched == true {
                                self.matchedUserId = profile.id
                                print("\(profile.id)")
                                print("matchedUserID: \(matchedUserId)")
                                //messageReport(memberId1: heartData.giveId, memberId2: heartData.takeId)
                                sendRoomData(memberId1: heartData.giveId , memberId2: heartData.takeId)
                                establishWebSocketConnectionIfNeeded()
                                DispatchQueue.main.async {
                                    displayPopup(title: "채팅방 생성 완료 🎉", message: "친구와 서로 하트를 눌렀어요! \n얼른 채팅하러 고고💨")
                                    self.roomCreated = true
                                }
                                
                            } else {
                                if isAnonymous {
                                    DispatchQueue.main.async {
                                        displayPopup(title: "하트 전송 완료 🩵", message: "친구에게 하트를 보냈습니다.")
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        displayPopup(title: "채팅방 생성 완료 🎉", message: "친구에게 하트를 눌렀어요! \n얼른 채팅하러 고고💨")
                                        self.roomCreated = true
                                        sendRoomData(memberId1: heartData.giveId , memberId2: heartData.takeId)
                                        establishWebSocketConnectionIfNeeded()
                                    }
                                }
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            displayPopup(title: "에러!", message: "서버에서 유효한 응답을 받지 못했습니다. \n 관리자에게 문의하세요.")
                        }
                    }
                }
            }
    }
    
    // 채팅방 생성 전 신고된 메시지 확인
    func messageReport(memberId1: Int64, memberId2: Int64) {
        let checkReportURL = "https://real.najoa.net/joa/rooms/report-message"
        let parameters: [String: Any] = [
            "memberId1": memberId1,
            "memberId2": memberId2
        ]
        
        print("sendRoomData 할 때 내가 보낸 값: ", parameters)
        
        AF.request(checkReportURL, method: .get, parameters: parameters)
            .response { response in
                print("신고된 메시지 확인 Response: \(response.response)")
                print("신고된 메시지 확인 Data: \(response.data)")
                print("신고된 메시지 확인 Error: \(response.error)")
                if let statusCode = response.response?.statusCode {
                    print("HTTP Status Code:", statusCode)
                    
                    switch statusCode {
                    case 204:
                        // 서버 응답이 204일 때, 기존 로직 그대로 실행
                        if let userId = userData.userId {
                            let heartData = HeartData(giveId: userId, takeId: profile.id, named: isAnonymous)
                            // messageReport(memberId1: userId, memberId2: profile.id)
                            sendHeartData(heartData: heartData)
                        }
                        //                        self.matchedUserId = profile.id
                        //                        sendRoomData(memberId1: memberId1, memberId2: memberId2)
                        //                        establishWebSocketConnectionIfNeeded() // WebSocket 연결 수립
                        //                        print("matchedUserID: \(matchedUserId)")
                        
                    default:
                        // Handle other status codes if needed
                        if let responseData = response.data {
                            print(responseData)
                            do {
                                if let json = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: Any],
                                   let status = json["status"] as? Bool,
                                   let code = json["code"] as? String {
                                    switch (status, code) {
                                    case (false, "M001"):
                                        DispatchQueue.main.async {
                                            self.displayPopup(title: "채팅방 생성 불가", message: "사용자가 존재하지 않습니다! 회원가입 혹은 로그인 해주세요.")
                                            print("M001")
                                        }
                                    case (false, "MR003"):
                                        DispatchQueue.main.async {
                                            self.displayPopup(title: "채팅방 생성 불가", message: "상대방과의 채팅을 신고한 이력으로 인해 채팅방 생성이 불가능합니다!")
                                            print("M003")
                                        }
                                    case (false, "MR004"):
                                        DispatchQueue.main.async {
                                            self.displayPopup(title: "채팅방 생성 불가", message: "상대방에게 신고된 이력으로 인해 채팅방 생성이 불가능합니다!")
                                            print("MR004")
                                        }
                                    default:
                                        break
                                    }
                                }
                            } catch {
                                print("Error parsing JSON:", error.localizedDescription)
                            }
                        }
                    }
                }
            }
    }
    
    //방 유무 확인
    func sendRoomData(memberId1: Int64, memberId2: Int64) {
        let checkRoomURL = "https://real.najoa.net/joa/rooms/existence"
        let parameters: [String: Any] = [
            "memberId1": memberId1,
            "memberId2": memberId2
        ]
        
        print("sendRoomData 할 때 내가 보낸 값: ", parameters)
        
        AF.request(checkRoomURL, method: .get, parameters: parameters)
            .response { response in
                print("방 유무 확인 Response: \(response.response)")
                print("방 유무 확인 Data: \(response.data)")
                print("방 유무 확인 Error: \(response.error)")
                if let statusCode = response.response?.statusCode {
                    print("HTTP Status Code:", statusCode)
                    switch statusCode {
                    case 204:
                        print("방정보 없음")
                        self.matchedUserId = profile.id
                        //                        sendRoomData(memberId1: memberId1, memberId2: memberId2)
                        establishWebSocketConnectionIfNeeded() // WebSocket 연결 수립
                        print("matchedUserID: \(matchedUserId)")
                        createRoom(memberId1: memberId1, memberId2: memberId2)
                    default:
                        // 기타 예외상황 처리
                        do {
                            if let data = response.data {
                                let decoder = JSONDecoder()
                                let errorResponse = try decoder.decode(ResponseModel.self, from: data)
                                switch errorResponse.code {
                                case "M001":
                                    print("사용자를 찾을 수 없음")
                                    DispatchQueue.main.async {
                                        self.displayPopup(title: "사용자를 찾을 수 없습니다!", message: "해당 사용자를 찾을 수 없습니다.")
                                    }
                                case "R001":
                                    print("채팅방을 찾을 수 없음")
                                    DispatchQueue.main.async {
                                        self.displayPopup(title: "채팅방을 찾을 수 없습니다!", message: "채팅방을 찾을 수 없습니다.")
                                    }
                                default:
                                    print("알 수 없는 오류")
                                }
                            }
                        } catch {
                            print("Error decoding error response:", error)
                        }
                    }
                }
            }
    }
    
    struct ErrorResponse: Codable {
        let status: Bool
        let code: String
    }
    
    // 방 생성 후 roomId를 받아와서 웹소켓으로 넘기는 함수
    func createRoom(memberId1: Int64, memberId2: Int64) {
        let createRoomURL = "https://real.najoa.net/joa/rooms"
        var createRoomData = CreateRoom(action: "R", roomId: nil, memberId1: memberId1, memberId2: memberId2)
        
        AF.request(createRoomURL, method: .post, parameters: createRoomData, encoder: JSONParameterEncoder.default)
            .response { response in
                print("방 생성 시작 Response: \(response.response)")
                print("방 생성 시작 Data: \(response.data)")
                print("방 생성 시작 Error: \(response.error)")
                
                switch response.result {
                case .success(let data):
                    if let data = data {
                        do {
                            let decoder = JSONDecoder()
                            let responseModel = try decoder.decode(ResponseModel.self, from: data)
                            if let roomId = responseModel.data?.roomId {
                                createRoomData.roomId = roomId
                                self.sendWebSocketData(createRoomData: createRoomData, memberId2: memberId2)
                                print("방 생성 및 웹 소켓으로 데이터 전송 완료")
                            } else {
                                print("roomId를 찾을 수 없습니다.")
                            }
                        } catch {
                            print("응답 데이터 디코딩 오류:", error)
                        }
                    }
                case .failure(let error):
                    print("에러:", error)
                }
            }
    }
    
    // 웹 소켓을 통해 매칭된 사용자 정보를 백엔드로 보내는 함수
    func sendWebSocketData(createRoomData: CreateRoom, memberId2: Int64) {
        guard let roomId = createRoomData.roomId else {
            print("roomId가 nil입니다.")
            displayPopup(title: "에러", message: "서버에서 유효한 응답을 받지 못했습니다. \n 관리자에게 문의하세요.")
            return
        }
        
        let data = "R \(roomId) \(createRoomData.memberId1) \(memberId2)"
        
        // 연결된 웹 소켓이 존재하면 데이터 전송
        if let socket = socketEnv.socket {
            socket.write(string: data)
            print("Sent WebSocket Data: \(data)")
        } else {
            print("WebSocket 연결 안 됐음.")
        }
        self.roomCreated = true // 이 부분을 추가
        print("roomCread", roomCreated)
    }
}

struct HomebarView2: View {
    @State private var isViewActive = false // 내 위치 백엔드로 전송하기 위해서
    @ObservedObject var locationManager: LocationManager

      // Initialize locationManager with the userData object
      init(userData: UserData) {
          self.locationManager = LocationManager(userData: userData)
      }

    //내 위치 보낼 때
    struct ResponseModel: Decodable {
        let status: Bool
        let data: ResponseData?
        let code: String?

        struct ResponseData: Decodable {
            let isContained: Bool?
        }
    }
    
    @State private var showCongratulatoryPopup = false // 초기값으로 false 설정
    @State private var roomCreated = false // 채팅방이 생성되었는지 여부를 나타내는 변수
    @State private var roomID: Int? // 생성된 채팅방의 ID를 저장할 변수
    //@State private var isLoading: Bool = false
    @State private var showAlert = false // 추가: 알림을 보여줄지 여부
    
    @State private var nearByList: [NearByInfo] = []
    @State private var alertTitle = "" // 추가: 알림 타이틀
    @State private var alertMessage = "" // 추가: 알림 메시지
    @EnvironmentObject var userData: UserData
    @State private var isAnonymous = false // 전체 익명 토글 상태
    @EnvironmentObject var socketEnv: SocketEnvironment
    // 내 정보 불러올 때 변수 지정
    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var imageURL: UIImage? // 이미지의 URL을 저장할 변수
    
    @State private var showTermsAndConditionsPopup = false // 이용약관 팝업창
    @State private var showTooltip = false

    @State private var refreshPage = false
    
//    let dummyData: [NearByInfo] = [
//        NearByInfo(id: 37, name: "다니엘", urlCode: "me.png", bio: "", isLiked: false), //loginId44
//        NearByInfo(id: 38, name: "케인", urlCode: "me.png", bio: "",  isLiked: false), //55
//        NearByInfo(id: 8, name: "원태인" , urlCode: "me.png", bio: "최강삼성", isLiked: false), //1010
//        NearByInfo(id: 10, name: "김승민" , urlCode: "me.png", bio: "", isLiked: false) ,//1010
//        NearByInfo(id: 42, name: "쇼타로", urlCode: "me.png", bio: "", isLiked: false), // 99
//        NearByInfo(id: 8, name: "황런쥔" , urlCode: "me.png", bio: "", isLiked: false), //1010
//    ]
    
    var body: some View {
        NavigationView {
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
                    Spacer()
                    Spacer()
                    Spacer()
                    
                    HStack {
                        Image("main")
                            .resizable()
                            .frame(width: 60, height: 60)
                        VStack {
                            Text("주변 친구 찾아보기")
                                .font(.custom("NeoDunggeunmoPro-Regular", size: 31))
                                .foregroundColor(.black)
                            
                            Text("마음에 드는 친구를 찾았다면 하트를 날려보세요!")
                                .font(.custom("Galmuri14", size: 10))
                                .foregroundColor(.black)
                            Text("아이폰 설정에서 JoA를 찾아 위치를\n'항상'으로 해두면 실시간으로 위치가 반영돼요!")
                                .font(.custom("Galmuri14", size: 10))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                        }
                    }
                    ZStack {
                        Rectangle() // 직사각형 배경
                            .foregroundColor(Color(hex: "ffa7a7"))
                            .cornerRadius(10) // 직사각형 모서리를 둥글게 처리
                            .frame(width: 356, height: 95)
                        
                        NavigationLink(destination: Mypage2()) {
                            HStack {
                                if let image = imageURL {
                                    Image(uiImage: image)
                                        .resizable()
                                        .frame(width: 60, height: 60)
                                        .aspectRatio(contentMode: .fit)
                                        .clipShape(Circle())
                                } else {
                                    Image("my.png")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                }
                                VStack(alignment: .leading) {
                                    Text(name)
                                        .font(.custom("NeoDunggeunmoPro-Regular", size: 35))
                                        .foregroundColor(.black)
                                        .multilineTextAlignment(.center)
                                    
                                    Text(bio)
                                        .font(.custom("Galmuri14", size: 10))
                                        .foregroundColor(.black)
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                    }
                    .padding(.top, 10) //상단 높이 조절
                    .padding(.bottom, 10)
                    
                    HStack{ Button(action: {
                        fetchNearbyPeople()
                       //self.nearByList = dummyData
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            getMyprofile()
                        }
                    }) {
                        Text("주변 친구 찾아보기")
                            .font(.custom("Galmuri14", size: 12))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                        
                    }
                        Button(action: {
                            // 사용자 위치 업데이트 요청
                            if let userLocation = locationManager.userLocation {
                                if let userId = userData.userId {
                                    updateLocation(id: userId, latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude, altitude: userLocation.altitude)
                                }}
                        }) {
                            Text("내 위치 업데이트")
                                .font(.custom("Galmuri14", size: 12))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        
                        Button(action: {
                            // 약관 팝업 표시
                            showTermsAndConditionsPopup.toggle()
                        }) {
                        }
                        .sheet(isPresented: $showTermsAndConditionsPopup) {
                            // 약관 팝업 내용 (별도의 뷰로 만들 수 있습니다)
                            TermsAndConditionsPopup()
                        }
                    }
                    Toggle(isOn: $isAnonymous) {
                        HStack {
                            Text("익명으로 보내기")
                                .font(.custom("Galmuri14", size: 12))
                                .padding(.leading, 50)
                                .foregroundColor(.black)
                            
                            Image(systemName: "questionmark.circle")
                                .imageScale(.medium)
                                .padding(.leading, 5)
                                .onTapGesture {
                                    // 버튼을 누를 때 툴팁을 표시
                                    showTooltip.toggle()
                                    // 5초 후에 툴팁을 자동으로 닫기
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        showTooltip = false
                                    }
                                }
                        }
                    }
                    .padding(.trailing, 30)
                    .overlay(
                        TooltipOverlay(message: "실명으로 하트를 보내면 바로 채팅방이 생성되고, 익명으로 하트를 보내면 서로 하트를 눌러야먄 채팅방이 생성돼요!'")
                            .opacity(showTooltip ? 1 : 0)
                            .animation(.easeInOut(duration: 0.3))
                            .offset(y: -40) // 버튼 아래로 이동
                            //.opacity(1)
                    )
                    .onTapGesture {
                        // 다른 부분을 탭했을 때 툴팁 닫기
                        showTooltip = false
                    }
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach($nearByList) { profile in
                                ProfileItemView(showCongratulatoryPopup: $showCongratulatoryPopup, profile: profile, isAnonymous: $isAnonymous)
                                .id(refreshPage)
                            }
                        }
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        fetchNearbyPeople()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            getMyprofile()
                        }
                    }
                    if !UserDefaults.standard.bool(forKey: "hasShownTermsAndConditions") {
                        showTermsAndConditionsPopup.toggle()
                        UserDefaults.standard.set(true, forKey: "hasShownTermsAndConditions")
                    }
                    
                }
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
    
    //MARK: 내 정보 불러오기 API
    func getMyprofile() {
        if let userId = userData.userId {
            let apiUrl = "http://real.najoa.net/joa/member-profiles/\(userId)/location-page"
            
            AF.request(apiUrl, method: .get).responseJSON { response in
                switch response.result {
                case .success(let data):
                    if let userData = data as? [String: Any] {
                        if let status = userData["status"] as? Bool {
                            if status {
                                // Success response
                                if let profileData = userData["data"] as? [String: Any] {
                                    if let userName = profileData["name"] as? String {
                                        self.name = userName
                                    }
                                    if let userBio = profileData["bio"] as? String {
                                        self.bio = userBio
                                    }
                                    if let urlCode = profileData["urlCode"] as? String {
                                        let imageUrl = "https://j-project-2023.s3.ap-northeast-2.amazonaws.com/\(urlCode)"
                                        if let imageURL = URL(string: imageUrl) {
                                            let request = URLRequest(url: imageURL)
                                            URLSession.shared.dataTask(with: request) { data, response, error in
                                                if let data = data, let image = UIImage(data: data) {
                                                    DispatchQueue.main.async {
                                                        self.imageURL = image
                                                    }
                                                } else {
                                                    print("Image loading error: \(error?.localizedDescription ?? "Unknown error")")
                                                    self.imageURL = UIImage(named: "my.png")
                                                }
                                            }.resume()
                                        } else {
                                            self.imageURL = UIImage(named: "my.png")
                                        }
                                    } else {
                                        self.imageURL = UIImage(named: "my.png")
                                    }
                                }
                            } else {
                                if let code = userData["code"] as? String {
                                    if code == "M001" {
                                        displayPopup(title: "사용자 정보 없음", message: "사용자가 존재하지 않습니다! 회원가입 혹은 로그인 해주세요.")
                                    } else if code == "M014" {
                                        displayPopup(title: "이용불가!", message: "회원님은 영구정지 대상으로 JoA 이용이 불가능합니다.")
                                    }else if code == "M004" {
                                        displayPopup(title: "이용불가!", message: "회원님은 일시정지 대상으로 JoA 이용이 일시적으로 불가능합니다.")
                                    }
                                }
                            }
                        }
                    }
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
        }
    }

    //MARK: 내 위치 업데이트 API
    struct UpdateLocationRequest: Encodable {
        let id: Int64
        let latitude: Double
        let longitude: Double
        let altitude: Double
    }

    func updateLocation(id: Int64, latitude: Double, longitude: Double, altitude: Double) {
        let url = "https://real.najoa.net/joa/locations"

        let request = UpdateLocationRequest(id: id, latitude: latitude, longitude: longitude, altitude: altitude)

        AF.request(url, method: .patch, parameters: request, encoder: JSONParameterEncoder.default)
            .response { response in
                print(" Received Data: \(response)")
                if let statusCode = response.response?.statusCode {
                    if statusCode == 200 {
                        print("버튼 눌렀을 때 위치 업데이트 성공")

                        if let data = response.data {
                            do {
                                let decoder = JSONDecoder()
                                let responseModel = try decoder.decode(ResponseModel.self, from: data)
                                if let isContained = responseModel.data?.isContained {
                                    if isContained {
                                        // 학교 내에 있을 때의 처리
                                        print("사용자가 학교 내에 있습니다!")
                                    } else {
                                        print("사용자가 학교 내에 없습니다!")
                                        self.displayPopup(title: "Where are U?", message: "현재 위치가 학교 안이 아니에요! JoA는 학교 내에서만 이용가능합니다.")
                                    }
                                }
                            } catch {
                                print("에러 발생:", error)
                            }
                        }
                    } else {
                        if let data = response.data {
                            do {
                                let decoder = JSONDecoder()
                                let responseModel = try decoder.decode(ResponseModel.self, from: data)
                                if let errorCode = responseModel.code {
                                    switch errorCode {
                                    case "M001":
                                        print("사용자를 찾을 수 없습니다!")
                                        self.displayPopup(title: "사용자가 존재하지 않습니다!", message: "사용자가 존재하지 않습니다! 회원가입 혹은 로그인 해주세요")
                                    case "M014":
                                        print("영구정지된 계정입니다!")
                                        self.displayPopup(title: "계정이 영구정지 상태입니다!", message: "회원님은 영구정지 대상으로 JoA 이용이 불가능합니다.")
                                    case "L001":
                                        print("위치 찾을 수 없음!")
                                        self.displayPopup(title: "이용불가!", message: "위치가 확인되지 않아요! 위치 서비스 허용 후 이용해주세요.")
                                    case "M004":
                                        print("일시정지된 계정입니다!")
                                        self.displayPopup(title: "계정이 일시정지 상태입니다!", message: "회원님은 일시정지 대상으로 JoA 이용이 일시적으로 불가능합니다.")
                                    case "P001":
                                        print("학교 정보 찾을 수 없음!")
                                        self.displayPopup(title: "학교 정보 찾을 수 없음", message: "추후 다시 이용해주세요!")

                                    default:
                                        print("알 수 없는 오류 발생")
                                    }
                                }
                            } catch {
                                print("에러 발생:", error)
                            }
                        }
                    }
                }
            }
    }

    //MARK: - 주변 친구 찾기 API
    func fetchNearbyPeople() {
        guard let userLocation = locationManager.userLocation,
              let userId = userData.userId else {
            displayPopup(title: "주변 친구 없음", message: "주변에 JoA를 사용하고 있는 친구가 없습니다.")
            return
        }

        let latitude: Double = userLocation.coordinate.latitude
        let longitude: Double = userLocation.coordinate.longitude
        let altitude: Double = userLocation.altitude

        let parameters: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "altitude": altitude
        ]

        AF.request("https://real.najoa.net/joa/locations/\(userId)", method: .get, parameters: parameters)
            .validate()
            .responseDecodable(of: ApiResponse.self) { response in
                switch response.result {
                case .success(let apiResponse):
                    print("Request: \(response.request)")
                    print("Response: \(response.response)")
                    print("Data: \(response.data)")
                    print("Error: \(response.error)")
                    print("주변 사람 목록 Received Data: \(apiResponse)")

                    if let nearByList = apiResponse.data?.nearByList, !nearByList.isEmpty {
                        self.nearByList = nearByList
                        for (index, nearbyInfo) in nearByList.enumerated() {
                            if let urlCode = nearbyInfo.urlCode {
                                let imageUrlString = "https://j-project-2023.s3.ap-northeast-2.amazonaws.com/\(urlCode)"
                                self.nearByList[index].urlCode = imageUrlString
                            } else {
                                // 이미지가 없는 경우 기본 이미지 설정
                                self.nearByList[index].urlCode = "my.png"
                            }
                        }
                    } else {
                        displayPopup(title: "주변 친구 없음", message: "주변에 JoA를 사용하고 있는 친구가 없습니다.")
                        print("주변 사람이 없습니다.")
                    }
                    if !apiResponse.status {
                        // 서버 응답이 성공이 아닌 경우
                        if let errorCode = apiResponse.code {
                            switch errorCode {
                            case "M001":
                                showAlert(title: "사용자 정보 없음", message: "사용자가 존재하지 않습니다! 회원가입 혹은 로그인 해주세요.")
                            case "M014":
                                showAlert(title: "영구정지된 계정입니다!", message: "회원님은 영구정지 대상으로 JoA 이용이 불가능합니다.")
                            case "M004":
                                showAlert(title: "일시정지된 계정입니다!", message: "회원님은 일시정지 대상으로 JoA 이용이 일시적으로 불가능합니다.")
                            default:
                                break
                            }
                        }
                    }
                case .failure(let error):
                    print("API request failed with error: \(error)")
                }
            }

        func showAlert(title: String, message: String) {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
            if let viewController = UIApplication.shared.windows.first?.rootViewController {
                viewController.present(alertController, animated: true, completion: nil)
            }
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
                    .frame(width: 320, height: 80)
                    Spacer()
                }
                Spacer()
            }
        }
    }
}

struct HomebarView2_Previews: PreviewProvider {
    static var previews: some View {
        let userData = UserData()
        return HomebarView2(userData: userData)
            .environmentObject(userData)
            .onAppear {
                userData.userId = 5957685757
            }
    }
}
