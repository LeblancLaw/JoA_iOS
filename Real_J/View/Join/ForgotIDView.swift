import SwiftUI
import Alamofire

struct FindIDResponse: Decodable {
    let status: Bool
    let code: String?
}


struct ForgotIDView: View {
    @State private var uEmail: String = ""
    @State private var collegeId: Int64 = 1
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isEmailEntered = false // 이메일 입력 여부를 추적
    
    @EnvironmentObject var userData: UserData
    
    let schools = ["명지대학교"]
    
    var body: some View {
        
        let gradientColors: [Color] = [
            Color(hex: "FFFFFF"),
            Color(hex: "77EFFF"),
            Color(hex: "CBF9FF"),
            Color(hex: "FFFFFF")
        ]
        ZStack{
            LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            VStack {
                HStack {
                    Image("main")
                        .resizable()
                        .frame(width: 60, height: 60)
                    VStack {
                        Text("아이디 찾기")
                            .font(.custom("NeoDunggeunmoPro-Regular", size: 35))
                            .foregroundColor(.black)
                    }
                }
                
                HStack{
                    Text("학교")
                        .font(.custom("GalmuriMono11", size: 22))
                        .foregroundColor(.black)
                    
                    Picker("학교 선택", selection: $collegeId) {
                        ForEach(schools, id: \.self) { school in
                            Text(school).tag(Int64(1))
                        }
                    }
                    .foregroundColor(.black)
                    .pickerStyle(MenuPickerStyle())
                    .font(.custom("Galmuri14", size: 18))
                    .padding(.horizontal)
                    .frame(width: 250, height: 40)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                } .padding()
                
                HStack{
                    Text("메일")
                        .font(.custom("GalmuriMono11", size: 20))
                    //.padding(.leading, 1) //왼쪽으로 띄우기
                        .foregroundColor(.black)
                    
                    // 이메일 입력 칸
                    TextField("학교 이메일 아이디 입력", text: $uEmail, onEditingChanged: { editing in
                        self.isEmailEntered = editing // 이메일 입력 여부 갱신
                    })
                    .font(.custom("Galmuri14", size: 18))
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .frame(width: 290, height: 10)
                } .padding()
                
                // '@' 입력 시에만 메시지 표시
                if isEmailEntered && uEmail.contains("@") {
                    Text("메일은 @mju.ac.kr 전까지만 입력해주세요.")
                        .font(.custom("Galmuri14", size: 12))
                        .padding(.bottom,10)
                }
                
                Button(action: {
                    findID()
                }) {
                    Text("아이디 찾기")
                        .frame(width: 350, height: 40)
                        .background(Color(hex: "F3A7FF"))
                        .font(.custom("NeoDunggeunmoPro-Regular", size: 20))
                        .foregroundColor(.white)
                        .cornerRadius(13)
                        .padding()
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("알림"), message: Text(alertMessage), dismissButton: .default(Text("확인")))
        }
    }
    
    func findID() {
        let parameters: [String: Any] = [
            "collegeEmail": uEmail,
            "collegeId": collegeId
        ]
        
        AF.request("http://real.najoa.net/joa/members/id/find", method: .get, parameters: parameters)
            .response { response in
                switch response.result {
                case .success(let findPasswordResponse):
                    // 프린트문 추가
                    print("Request Parameters: \(parameters)")
                    print("Server Response: \(findPasswordResponse)")
                    
                    // 원하는 상태 코드에 대한 처리
                    switch response.response?.statusCode {
                    case 204:
                        // 성공 상태 코드 처리
                        self.showAlert = true
                        self.alertMessage = "임시 비밀번호가 이메일로 전송되었습니다!"
                    default:
                        // 다른 상태 코드에 대한 처리
                        if let data = response.data {
                            do {
                                let decoder = JSONDecoder()
                                let findIDResponse = try decoder.decode(FindIDResponse.self, from: data)
                                if findIDResponse.status == false {
                                    // 에러 상태 코드에 따른 팝업 처리
                                    if let errorCode = findIDResponse.code {
                                        switch errorCode {
                                        case "P001":
                                            self.showAlert = true
                                            self.alertMessage = "학교 정보를 찾을 수 없습니다."
                                        case "M001":
                                            self.showAlert = true
                                            self.alertMessage = "사용자를 찾을 수 없습니다."
                                        default:
                                            self.showAlert = true
                                            self.alertMessage = "서버에서 유효한 응답을 받지 못했습니다. \n 관리자에게 문의하세요."
                                        }
                                    }
                                }
                            } catch {
                                print("Error decoding response: \(error)")
                            }
                        }
                    }
                case .failure(let error):
                    print("Error: \(error)")
                    if let statusCode = response.response?.statusCode, statusCode == 404 {
                        self.showAlert = true
                        self.alertMessage = "서버에서 유효한 응답을 받지 못했습니다. \n 관리자에게 문의하세요."
                    }
                }
            }
    }
}

struct ForgotIDView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotIDView()
    }
}
