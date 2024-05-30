import SwiftUI
import FirebaseMessaging
import Alamofire
import Foundation
import Combine
import Firebase

struct JoinView: View {
    
    @EnvironmentObject var userData: UserData
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var fullName: String = ""
    @State private var schoolEmail: String = ""
    @State private var isUsernameAvailable: Bool = true
    @State private var isPasswordValid = true
    @State private var emailText: String = ""
    @State private var responseData: MemberResponse?
    @State private var verificationCodes = ""
    @State private var isVerificationCompleted = false
    @State private var isVerificationSuccess = false // 인증 성공 여부
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var timerSeconds = 420
    
    @State var userId: Int64? // 받아온 사용자의 고유 id
    
    @State private var isInvalidLengthAlertPresented = false
    
    //회원가입 성공 여부
    @State private var isSignUpCompleted = false
    
    //연장 버튼 비활성화
    @State private var isButtonDisabled = false
    
    @Binding var isJoinedIn: Bool // isLoggedIn을 바인딩으로 받음
    
    struct MemberResponse: Codable {
        let status: Bool
        let data: MemberData?
        let code: String?
        let statusCode: Int?
        
        struct MemberData: Codable {
            let id: Int64?
        }
    }
    
    @State private var collegeId: Int64 = 1
    
    @FocusState private var focusedField: Int?
    
    
    let schools = ["@mju.ac.kr"]
    
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
                    HStack{
                        Image("main")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .padding(.leading, 10) //우측으로 당기기
                        
                        VStack(alignment: .leading) {
                            Text("회원가입")
                                .font(.custom("NeoDunggeunmoPro-Regular", size: 30))
                            //.padding(.bottom, 0.01)
                        }
                    }

                    VStack {
                        HStack {
                            Text(" 이름  ")
                                .font(.custom("GalmuriMono11", size: 22))
                                .padding(.leading, 20)
                            
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .foregroundColor(.gray)
                                    .frame(width: 280, height: 45)
                                    .cornerRadius(19)
                                TextField("실명 사용 권장 (추후 수정 불가)", text: $fullName)
                                .foregroundColor(.white)
                                .font(.custom("Galmuri14", size: 18))
                                .padding(.horizontal, 15)
                            }
                        }
                        
                        HStack{
                            HStack{
                                Spacer()
                                Text("아이디 ")
                                    .font(.custom("GalmuriMono11", size: 22))
                                    .padding(.leading, 10)
                                
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .foregroundColor(.gray)
                                        .frame(width: 220, height: 45)
                                        .cornerRadius(19)
                                    
                                    TextField("아이디를 입력하세요", text: $username) // 아이디 입력 필드를 username 변수와 바인딩
                                        .foregroundColor(.white)
                                        .font(.custom("Galmuri14", size: 18))
                                        .padding(.horizontal, 15)
                                }
                            }
                            HStack{
                                Button(action: {
                                    if username.isEmpty {
                                        showAlert = true // 중복 확인 버튼을 눌렀을 때 팝업 창 띄우기
                                        alertMessage = "아이디를 입력하세요."
                                    } else {
                                        checkUsernameAvailability()
                                    }}) {
                                        Text("중복 확인")
                                            .frame(width: 50, height: 40)
                                            .font(.custom("GalmuriMono11", size: 10)) // 버튼 텍스트 스타일
                                            .foregroundColor(.white) // 버튼 텍스트 색상
                                            .background(Color(hex: "eba1ff")) // 버튼 배경색
                                            .cornerRadius(10) // 버튼 모서리 둥글게 처리
                                    }
                                    .disabled(username.isEmpty) // 아이디가 입력되지 않았을 때 버튼 비활성화
                                Spacer()
                            }
                        }
                        
                        HStack {
                            Text("비밀번호")
                                .font(.custom("GalmuriMono11", size: 22))
                                .padding(.leading, 10)
                            
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .foregroundColor(.gray)
                                    .frame(width: 280, height: 45)
                                    .cornerRadius(19)
                                
                                TextField("비밀번호를 입력하세요 ", text: Binding(
                                    get: { password },
                                    set: { newValue in
                                        password = newValue
                                        validatePassword(newValue)
                                    })
                                )
                                .foregroundColor(.white)
                                .font(.custom("Galmuri14", size: 18))
                                .padding(.horizontal, 15)
                                .disabled(!isUsernameAvailable) // 아이디 중복시 비밀번호 입력 비활성화
                            }
                        }
                        
                        if !isPasswordValid {
                            Text("8~16자, 영어 대소문자, 숫자 및 기호 포함")
                                .foregroundColor(.red)
                                .padding(.bottom)
                        }
                        Button("회원가입") {
                            completeRegistration()
                        }
                        .frame(width: 180, height: 40) // 버튼 크기 조절
                        .background(Color(hex: "F3A7FF"))
                        .font(.custom("NeoDunggeunmoPro-Regular", size: 20))
                        .foregroundColor(.white)
                        .cornerRadius(13) // 버튼 모서리를 둥글게 설정
                    }}
                
                
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("알림"), message: Text(alertMessage), dismissButton: .default(Text("확인"))
            )
        }
    }
        
    // 아이디 중복검증 API
    func checkUsernameAvailability() {
        let apiUrl = "https://real.najoa.net/joa/members/id/verify"
        
        let parameters: [String: Any] = [
            "sessionId": userId ?? 0,
            "loginId": username
        ]
        print("내가 보낸 값 : \(parameters)")
        
        AF.request(apiUrl, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .response { [self] response in
                print("Request: \(response.request)")
                print("Response: \(response.response)")
                print("Data: \(response.data)")
                print("Error: \(response.error)")
                print("Response: \(response)")
                switch response.result {
                case .success(let data):
                    if let statusCode = response.response?.statusCode {
                        if statusCode == 204 {
                            showAlert = true
                            alertMessage = "사용 가능한 아이디입니다."
                            
                        } else if let data = data {
                            do {
                                let decodedData = try JSONDecoder().decode(MemberResponse.self, from: data)
                                // 인증 실패
                                if let errorCode = decodedData.code {
                                    switch errorCode {
                                    case "M011":
                                        showAlert = true
                                        alertMessage = "이미 사용 중인 아이디입니다."
                                    case "M010":
                                        showAlert = true
                                        alertMessage = "아이디는 5~20자 영어 소문자, 숫자, '-','_'만 사용가능 합니다."
                                    case "M008":
                                        showAlert = true
                                        alertMessage = "웹메일 인증 완료 후 진행해주세요."
                                    default:
                                        showAlert = true
                                        alertMessage = "서버에서 유효한 응답을 받지 못했습니다. \n 관리자에게 문의하세요."
                                    }
                                }
                                isVerificationCompleted = false
                            } catch {
                                showAlert = true
                                alertMessage = "데이터 디코딩 오류: \(error.localizedDescription)"
                                isVerificationCompleted = false
                            }
                        }
                    }
                case .failure(let error):
                    print("오류: \(error)")
                    showAlert = true
                    alertMessage = "서버에서 유효한 응답을 받지 못했습니다. \n 관리자에게 문의하세요."
                    isVerificationCompleted = false
                }
            }
    }

    //MARK: - 회원가입 완료
    func completeRegistration() {
        let apiUrl = "https://real.najoa.net/joa/members" // 회원가입 API 주소

        // FCM 토큰 발급
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
                showAlert = true
                alertMessage = "서버에서 유효한 응답을 받지 못했습니다. \n 관리자에게 문의하세요."
                return
            } else if let token = token {
                print("FCM registration token: \(token)")
                
                let parameters: [String: Any] = [
                    "id": userId ?? 0, // Use the stored user ID
                    "name": fullName,
                    "password": password,
                    "loginId": username, // 사용자가 입력한 아이디
                    "fcmToken": token // FCM 토큰 추가
                ]
                
                AF.request(apiUrl, method: .post, parameters: parameters, encoding: JSONEncoding.default)
                    .response { [self] response in
                        print("Request: \(response.request)")
                        print("Response: \(response.response)")
                        print("Data: \(response.data)")
                        print("Error: \(response.error)")
                        print("Response: \(response)")
                        switch response.result {
                        case .success(let data):
                            if let statusCode = response.response?.statusCode {
                                if statusCode == 204 {
                                    if let userId {
                                        userData.setUserId(userId) // userData에 userId 설정
                                        isJoinedIn = true // 로그인 성공 시 isLoggedIn을 변경
                                        print("회원가입 성공, userId: \(userId)")
                                        UserDefaults.standard.set(userId, forKey: "loggedInUserId") // 사용자 ID를 저장 -1027 수정
                                    }
                                    isSignUpCompleted = true // Set isSignUpCompleted to true
                                    showAlert = true
                                    alertMessage = "회원가입이 완료되었습니다."
                                    isJoinedIn = true
                                } else if let data = data {
                                    do {
                                        let decodedData = try JSONDecoder().decode(MemberResponse.self, from: data)
                                        // 인증 실패
                                        if let errorCode = decodedData.code {
                                            switch errorCode {
                                            case "M007":
                                                showAlert = true
                                                alertMessage = "유효하지 않은 접근입니다! 회원가입 버튼을 다시 눌러주세요!"
                                            case "M013":
                                                showAlert = true
                                                alertMessage = "아이디 중복 확인 후 회원가입을 완료해주세요!"
                                            case "P001":
                                                showAlert = true
                                                alertMessage = "학교 정보를 한 번 더 확인해주세요!"
                                            default:
                                                showAlert = true
                                                alertMessage = "알 수 없는 오류가 발생하였습니다. \n 지속적인 문제 발생 시 관리자에게 문의하세요"
                                            }
                                        }
                                        isVerificationCompleted = false
                                    } catch {
                                        showAlert = true
                                        alertMessage = "데이터 디코딩 오류: \(error.localizedDescription)"
                                        isVerificationCompleted = false
                                    }
                                }
                            }
                        case .failure(let error):
                            print("오류: \(error)")
                            showAlert = true
                            alertMessage = "서버에서 유효한 응답을 받지 못했습니다. \n 관리자에게 문의하세요."
                            isVerificationCompleted = false
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

    //MARK: - 비밀번호 조건 여부 판단 함수 8~16자 사이 & 대.소문자, 숫자, 특수문자 반드시 포함
    private func validatePassword(_ password: String) {
        let passwordRegex = "^(?=.*[A-Z])(?=.*[a-z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]{8,16}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        isPasswordValid = passwordPredicate.evaluate(with: password)
    }
}

struct JoinView_Previews: PreviewProvider {
    static var previews: some View {
        let userData = UserData()
        userData.userId = 6201433303 // 가정한 userId 설정
        return JoinView(isJoinedIn: .constant(false))
            .environmentObject(userData)
    }
}
