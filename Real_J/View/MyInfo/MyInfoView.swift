import SwiftUI
import Alamofire
import SDWebImageSwiftUI
import Foundation
import SafariServices

let storedUserID = UserDefaults.standard.value(forKey: "userID") as? Int64

struct MyInfoView: View {
    // 사용자 정보를 저장할 @State 변수 정의
    @State private var name: String = ""
    @State private var urlCode: String? = nil // urlCode를 String 타입의 Optional 변수로 선언
    @State private var profileImage: UIImage? // 추가: 프로필 이미지 저장
    //세션 id 저장
    @EnvironmentObject var userData: UserData
    @StateObject private var decodedImageLoader = DecodedImageLoader()
    
    @State private var showingConfirmationAlert = false //탈퇴 시 팝업 호출 위해
    @State private var showingbyebyeAlert = false
    @State private var showToast = false
    
    
    var body: some View {
        NavigationView{
            let gradientColors: [Color] = [
                Color(hex: "FFFFFF"),
                Color(hex: "77EFFF"),
                Color(hex: "CBF9FF"),
                Color(hex: "FFFFFF")
            ]
            ZStack {
                LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                VStack(){
                    HStack(spacing: 10) {
                        Image("main")
                            .resizable()
                            .frame(width: 60, height: 60)
                        Text("설정")
                            .font(.custom("NeoDunggeunmoPro-Regular", size: 43))
                            .foregroundColor(Color.black)
                    }
                    ScrollView {
                        HStack{
                            ZStack {
                                Rectangle()
                                    .fill(Color(hex: "c5ffc2"))
                                    .frame(width: 210, height: 210)
                                    .cornerRadius(10) // 모서리 둥글기 설정
                                    .padding(.leading, 20)
                                NavigationLink(destination: Mypage2()) {
                                    VStack {
                                        if let decodedImage = profileImage {
                                            Image(uiImage: decodedImage)
                                                .resizable()
                                                .frame(width: 80, height: 80)
                                            //.padding(.all, 10)
                                                .clipShape(Circle())
                                                .aspectRatio(contentMode: .fit)
                                                .padding(.leading, 20)
                                            
                                        } else {
                                            Image("my.png")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 70, height: 70)
                                            //   .padding(.all, 10)
                                                .clipShape(Circle())
                                                .padding(.leading, 20)
                                        }
                                        VStack {
                                            Text(name)
                                                .font(.custom("NeoDunggeunmoPro-Regular", size: 25))
                                                .foregroundColor(.black)
                                                .multilineTextAlignment(.center)
                                                .padding(.leading, 20)
                                            Text("내가 받은 득표 수 보러가기")
                                                .font(.custom("Galmurimono11", size: 15))
                                                .foregroundColor(.black)
                                                .multilineTextAlignment(.center)
                                                .padding(.leading, 20)
                                        }
                                    }
                                }
                            }
                            HStack{
                                VStack{
                                    Button(action: {
                                        showingConfirmationAlert = true
                                    }) {
                                        CardView(imageName: "arrow.clockwise.heart", title: "로그아웃", backgroundColor: Color.white)
                                            .font(.custom("Galmurimono11", size: 15))
                                            .foregroundColor(.black)
                                    }
                                    .alert(isPresented: $showingConfirmationAlert) {
                                        Alert(
                                            title: Text("로그아웃 하시겠습니까?"),
                                            message: Text(""),
                                            primaryButton: .default(Text("확인"), action: {
                                                logout() // 확인을 누르면 함수 호출
                                            }),
                                            secondaryButton: .cancel(Text("취소"))
                                        )
                                    }
                                    
                                    Button(action: {
                                        showingbyebyeAlert = true
                                    }) {
                                        CardView(imageName: "rectangle.portrait.and.arrow.forward", title: "JoA\n탈퇴하기", backgroundColor: Color(hex: "ddff61"))
                                            .font(.custom("Galmurimono11", size: 13))
                                            .foregroundColor(.black)
                                            .padding(.bottom, 5)
                                    }
                                    .alert(isPresented: $showingbyebyeAlert) {
                                        Alert(
                                            title: Text("정말 JoA를 탈퇴하시겠습니까? 탈퇴하면 기존에 저장된 정보는 모두 사라져요😢"),
                                            message: Text(""),
                                            primaryButton: .default(Text("확인"), action: {
                                                byebyecustomer() // 확인을 누르면 함수 호출
                                            }),
                                            secondaryButton: .cancel(Text("취소"))
                                        )
                                    }
                                }
                            }
                        }
                        Button(action: {
                            openURL("https://false-challenge-ba9.notion.site/JoA-b2300ca6aac442278145ca4ba9a28bf1")
                        }) {
                            CardView(imageName: "doc.richtext", title: "사용방법 알아보기", backgroundColor: Color.white)
                        }
                        Button(action: {
                            openURL("https://docs.google.com/document/d/14VJ3sb7M76uvjQni_BEyRzM5QaoghYojk86FYLHYMx0/edit")
                        }){
                            CardView(imageName: "gearshape.2", title: "이용 약관 및 개인정보 보호", backgroundColor: Color(hex: "4fffbe"))
                        }
                        NavigationLink(destination: ChangePasswordView()) {
                            CardView(
                                imageName: "square.and.pencil",title: "비밀번호 변경하기", backgroundColor: Color.white
                            )
                        }
                        Button(action: {
                            showToast = true
                            
                        }) {
                            Image(systemName: "phone.connection")
                                .foregroundColor(Color.black)
                            Text("고객센터 연락처 : mjuappsw@gmail.com")
                                .font(.custom("Galmuri14", size: 15))
                                .foregroundColor(.black)
                        }
                        .alert(isPresented: $showToast) {
                            Alert(
                                title: Text("고객센터 연락처"),
                                message: Text("계정 신고에 의한 정책에 대한 자세한 문의나 사용하다 생긴 궁금한 점에 대해 더욱 더 자세히 알고 싶다면 [ mjuappsw@gmail.com ]로 문의해주세요🫶🏻!"),
                                dismissButton: .default(Text("확인"))
                            )
                        }
                    }.padding(.bottom, 10)
                }
                .navigationBarTitleDisplayMode(.inline) // 막대의 타이틀 표시 모드를 고정된 타이틀로 변경
                .font(.custom("Galmuri14", size: 20))
                .onAppear(perform: getUserInfo) // 페이지에 진입 시 getUserInfo() 함수 호출
            }
        }
    }
    
    // 홈페이지 이동
    func openURL(_ urlString: String) {
        if let url = URL(string: urlString) {
            let safariViewController = SFSafariViewController(url: url)
            UIApplication.shared.windows.first?.rootViewController?.present(safariViewController, animated: true, completion: nil)
        }
    }
    
    struct CardView: View {
        var imageName: String
        var title: String
        var description: String?
        var backgroundColor: Color
        
        var body: some View {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(backgroundColor)
                .frame(height: 100)
                .padding(.horizontal)
                .overlay(
                    HStack {
                        Image(systemName: imageName)
                            .font(.title)
                            .foregroundColor((Color(hex: "000000")))
                        VStack(alignment: .leading) {
                            Text(title)
                                .font(.custom("Galmuri14", size: 20))
                                .foregroundStyle((Color.black))
                        }
                    }
                )
                .padding(.vertical, 2)
        }
    }
    
    // showAlert 함수 정의
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .default) { _ in
            completion?()
        }
        alertController.addAction(okAction)
        UIApplication.shared.windows.first?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
    
    //MARK: - 로그아웃
    func logout() {
        if let userId = userData.userId {
            let apiUrl = "http://real.najoa.net/joa/members/\(userId)/logout"
            
            AF.request(apiUrl, method: .post)
                .responseJSON { response in
                    print("Request: \(response.request)")
                    print("Response: \(response.response)")
                    print("Data: \(response.data)")
                    print("Error: \(response.error)")
                    switch response.result {
                    case .success:
                        if let statusCode = response.response?.statusCode {
                            if statusCode == 204 {
                                // 로그아웃 성공
                                UserDefaults.standard.removeObject(forKey: "loggedInUserId")
                                userData.removeUserId()
                                
                                showAlert(title: "알림", message: "로그아웃이 완료되었습니다!") {
                                    DispatchQueue.main.async {
                                        if let window = UIApplication.shared.windows.first {
                                            window.rootViewController = UIHostingController(rootView: SplashView().environmentObject(userData))
                                        }
                                    }
                                }
                            } else {
                                // 기타 응답 상황에 대한 처리
                                if let data = response.data {
                                    do {
                                        let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                                        if let status = jsonData?["status"] as? Bool, let code = jsonData?["code"] as? String, !status {
                                            if code == "M001" {
                                                // 사용자를 찾을 수 없는 경우
                                                showAlert(title: "알림", message: "사용자를 찾을 수 없습니다!")
                                            } else {
                                                // 기타 예외 상황에 대한 처리
                                                showAlert(title: "알림", message: "예외 상황이 발생했습니다. 코드: \(code)")
                                            }
                                        }
                                    } catch {
                                        print("Error parsing JSON: \(error)")
                                        showAlert(title: "알림", message: "응답 데이터를 처리하는 중에 오류가 발생했습니다.")
                                    }
                                }
                            }
                        }
                    case .failure(let error):
                        // 기타 에러 처리
                        print("로그아웃 에러: \(error)")
                        showAlert(title: "알림", message: "로그아웃 중 에러 발생")
                    }
                }
        }
    }
    
    
    //MARK:- 회원탈퇴 API
    func byebyecustomer() {
        if let userId = userData.userId {
            let apiUrl = "http://real.najoa.net/joa/members/\(userId)"
            
            AF.request(apiUrl, method: .delete, encoding: JSONEncoding.default)
            // .validate()
                .responseJSON { response in
                    print("Request: \(response.request)")
                    print("Response: \(response.response)")
                    print("Data: \(response.data)")
                    print("Error: \(response.error)")
                    switch response.result {
                    case .success(let data):
                        if let statusCode = response.response?.statusCode {
                            if statusCode == 204 {
                                // 로그아웃 성공
                                UserDefaults.standard.removeObject(forKey: "loggedInUserId")
                                userData.removeUserId()
                                showAlert(title: "알림", message: "회원탈퇴가 완료되었습니다!") {
                                    DispatchQueue.main.async {
                                        if let window = UIApplication.shared.windows.first {
                                            window.rootViewController = UIHostingController(rootView: SplashView().environmentObject(userData))
                                        }
                                    }
                                }
                            } else {
                                // 회원 탈퇴 실패
                                if let data = response.data {
                                    do {
                                        let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                                        if let status = jsonData?["status"] as? Bool, let code = jsonData?["code"] as? String, !status {
                                            if code == "M001" {
                                                // 사용자를 찾을 수 없는 경우
                                                showAlert(title: "알림", message: "사용자를 찾을 수 없습니다!")
                                            } else {
                                                // 기타 실패 상황에 대한 처리
                                                showAlert(title: "알림", message: "알 수 없는 오류가 발생했습니다.")
                                            }
                                        }
                                    } catch {
                                        print("Error parsing JSON: \(error)")
                                        showAlert(title: "알림", message: "응답 데이터를 처리하는 중에 오류가 발생했습니다.")
                                    }
                                }
                            }
                        }
                    case .failure(let error):
                        // 기타 에러 처리
                        print("회원탈퇴 에러: \(error)")
                        showAlert(title: "알림", message: "회원탈퇴 중 에러 발생")
                    }
                }
        }
    }
                                    
    //MARK: - 사용자 정보 불러오기
    func getUserInfo() {
        if let userId = userData.userId {
            let apiUrl = "http://real.najoa.net/joa/member-profiles/\(userId)/setting-page"
            
            AF.request(apiUrl, method: .get).responseJSON { response in
                print("Request: \(response.request)")
                print("Response: \(response.response)")
                print("Data: \(response.data)")
                print("Error: \(response.error)")
                switch response.result {
                case .success(let data):
                    if let jsonData = data as? [String: Any] {
                        if let status = jsonData["status"] as? Bool {
                            if status {
                                // 사용자 정보 불러오기 성공
                                if let data = jsonData["data"] as? [String: Any] {
                                    if let userName = data["name"] as? String {
                                        self.name = userName
                                    }
                                    if let urlCode = data["urlCode"] as? String {
                                        let imageUrlString = "https://j-project-2023.s3.ap-northeast-2.amazonaws.com/\(urlCode)"
                                        AF.request(imageUrlString).responseData { response in
                                            switch response.result {
                                            case .success(let data):
                                                if let loadedImage = UIImage(data: data) {
                                                    self.profileImage = loadedImage
                                                } else {
                                                    self.profileImage = UIImage(named: "my.png")
                                                }
                                            case .failure(_):
                                                self.profileImage = UIImage(named: "my.png")
                                            }
                                        }
                                    } else {
                                        self.profileImage = UIImage(named: "my.png")
                                    }
                                }
                            } else {
                                // 사용자를 찾을 수 없는 경우
                                if let code = jsonData["code"] as? String {
                                    var errorMessage = ""
                                    switch code {
                                    case "M001":
                                        errorMessage = "사용자를 찾을 수 없습니다!"
                                        UserDefaults.standard.removeObject(forKey: "loggedInUserId")
                                        userData.removeUserId()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            if let window = UIApplication.shared.windows.first {
                                                window.rootViewController = UIHostingController(rootView: SplashView().environmentObject(userData))
                                            }
                                        }
                                    case "M004":
                                        errorMessage = "일시 정지된 계정입니다!"
                                    case "M014":
                                        errorMessage = "영구 정지된 계정입니다!"
                                    default:
                                        errorMessage = "알 수 없는 오류가 발생했습니다."
                                    }
                                    self.showAlert(title: "알림", message: errorMessage)
                                }
                            }
                        }
                    }
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
        } else {
            // 사용자 ID가 없는 경우
            print("사용자 ID가 없습니다.")
        }
    }
}
// DecodedImageLoader 클래스 정의
class DecodedImageLoader: ObservableObject {
    @Published var image: UIImage? // 디코딩된 이미``지를 저장할 @Published 속성

    func decodeBase64Image(_ base64String: String) {
        if let data = Data(base64Encoded: base64String) {
            image = UIImage(data: data)
        } else {
            image = nil
        }
    }
}

struct MyInfoView_Previews: PreviewProvider {
    static var previews: some View {
        let userData = UserData()
        return MyInfoView()
            .environmentObject(userData)
            .onAppear {
                userData.userId = 131313
            }
    }
}
