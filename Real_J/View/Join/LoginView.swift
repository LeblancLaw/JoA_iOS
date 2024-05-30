import SwiftUI
import FirebaseMessaging
import Alamofire
import Firebase

struct LoginResponse: Decodable {
    let status: Bool
    let data: UserDataResponse?
    let code: String?
}

struct UserDataResponse: Decodable {
    let id: Int64
}

struct LoginView: View {
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Binding var isLoggedIn: Bool // isLoggedIn을 바인딩으로 받음
    @EnvironmentObject var userData: UserData // userData를 환경 객체로 가져옴

    // 자동 로그인 확인
      init(isLoggedIn: Binding<Bool>) {
          self._isLoggedIn = isLoggedIn
          if let loggedInUserId = UserDefaults.standard.value(forKey: "loggedInUserId") as? Int64 {
              // 저장된 사용자 ID가 있다면 자동으로 로그인
              self._isLoggedIn.wrappedValue = true
              // userData에 userId 설정
              userData.setUserId(loggedInUserId)
          }
      }
    
    var body: some View {
        let gradientColors: [Color] = [
            Color(hex: "FFFFFF"),
            Color(hex: "77EFFF"),
            Color(hex: "CBF9FF"),
            Color(hex: "FFFFFF")
        ]
        NavigationView {
            
            ZStack {
                LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    HStack {
                        Image("main")
                            .resizable()
                            .frame(width: 60, height: 60)
                        VStack {
                            Text("로그인")
                                .font(.custom("NeoDunggeunmoPro-Regular", size: 35))
                        }
                    }
                    
                    HStack {
                        Text(" 아이디 ")
                            .font(.custom("GalmuriMono11", size: 22))
                            .padding(.leading, 10)
                            .foregroundColor(.black)
                        
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .foregroundColor(.gray)
                                .frame(width: 250, height: 45)
                                .cornerRadius(19)
                            
                            TextField("아이디를 입력하세요", text: $username)
                                .foregroundColor(.white)
                                .font(.custom("Galmuri14", size: 18))
                                .padding(.horizontal, 10)
                        }
                        .padding(.vertical)
                    }
                    HStack {
                        Text("비밀번호")
                            .font(.custom("GalmuriMono11", size: 22))
                            .padding(.leading, 10)
                        
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .foregroundColor(.gray)
                                .frame(width: 250, height: 45)
                                .cornerRadius(19)
                            
                            SecureField("비밀번호를 입력하세요 ", text: $password)
                                .foregroundColor(.white)
                                .font(.custom("Galmuri14", size: 18))
                                .padding(.horizontal, 10)
                        }
                        .padding(.vertical)
                    }
                    
                    Button("로그인") {
                        if username.isEmpty || password.isEmpty {
                            showAlert = true
                            alertMessage = "모든 필수 입력 칸을 채워주세요."
                        } else {
                            // FCM 토큰 발급
                            Messaging.messaging().token { token, error in
                                if let error = error {
                                    print("Error fetching FCM registration token: \(error)")
                                    showAlert = true
                                    alertMessage = "서버에서 유효한 응답을 받지 못했습니다. \n 관리자에게 문의하세요."
                                    return
                                } else if let token = token {
                                    print("FCM registration token: \(token)")
                                    
                                    // 로그인 요청 파라미터 설정
                                    let parameters: [String: Any] = [
                                        "loginId": username,
                                        "password": password,
                                        "fcmToken": token // FCM 토큰 추가
                                    ]
                                    print("보낸 파라미터: \(parameters)")
                                    AF.request("https://real.najoa.net/joa/members/login", method: .post, parameters: parameters, encoding: JSONEncoding.default)
                                        .responseDecodable(of: LoginResponse.self) { response in
                                            switch response.result {
                                            case .success(let loginResponse):
                                                print("Request: \(response.request)")
                                                print("Response: \(response.response)")
                                                print("Data: \(response.data)")
                                                print("Error: \(response.error)")
                                                
                                                if loginResponse.status { // 로그인 성공 시
                                                    if let userDataResponse = loginResponse.data {
                                                        let userId = userDataResponse.id
                                                        userData.setUserId(userId) // userData에 세션 아이디 설정
                                                        isLoggedIn = true // 로그인 성공 시 isLoggedIn을 변경
                                                        print("로그인 성공, userId: \(userId)") // 로그인 성공 시 사용자 아이디 출력
                                                        UserDefaults.standard.set(userId, forKey: "loggedInUserId") // 사용자 아이디를 저장
                                                    }
                                                } else { // 로그인 실패 시
                                                    if let errorCode = loginResponse.code {
                                                        switch errorCode {
                                                        case "M001":
                                                            showAlert = true
                                                            alertMessage = "존재하지 않는 ID입니다."
                                                        case "M015":
                                                            showAlert = true
                                                            alertMessage = "비밀번호가 올바르지 않습니다."
                                                        default:
                                                            showAlert = true
                                                            alertMessage = "서버에서 유효한 응답을 받지 못했습니다. \n 관리자에게 문의하세요."
                                                        }
                                                    } else {
                                                        showAlert = true
                                                        alertMessage = "서버에서 유효한 응답을 받지 못했습니다. \n 관리자에게 문의하세요."
                                                    }
                                                }
                                                
                                            case .failure(let error):
                                                print("Error: \(error)")
                                                showAlert = true
                                                alertMessage = "서버에서 유효한 응답을 받지 못했습니다. \n 관리자에게 문의하세요." // 네트워크 에러 메시지 추가
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .frame(width: 350, height: 40)
                    .background(Color(hex: "F3A7FF"))
                    .font(.custom("NeoDunggeunmoPro-Regular", size: 20))
                    .foregroundColor(.white)
                    .cornerRadius(13)
                    
                    
                    HStack(spacing: 20) {
                        NavigationLink(destination: ForgotIDView()) {
                            Text("아이디 찾기")
                                .font(.custom("Galmuri14", size: 16))
                                .underline()
                        }
                        
                        NavigationLink(destination: ForgotPasswordView()) {
                            Text("비밀번호 찾기")
                                .font(.custom("Galmuri14", size: 16))
                                .underline()
                        }
                    }
                    .padding(.top, 20)
                    
                }
                .padding(.bottom, 20)
                .alert(isPresented: $showAlert) {
                       Alert(title: Text("알림"), message: Text(alertMessage), dismissButton: .default(Text("확인")))
                   }
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    @State static var isLoggedIn: Bool = false
    
    static var previews: some View {
        LoginView(isLoggedIn: $isLoggedIn)
            .environmentObject(UserData()) // UserData 환경 객체도 함께 추가
    }
}
