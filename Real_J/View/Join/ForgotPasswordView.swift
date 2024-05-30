import SwiftUI
import Alamofire

struct FindPasswordResponse: Decodable {
    let status: Bool
    let code: String?
}

struct ForgotPasswordView: View {
    @StateObject private var viewModel = ForgotPasswordViewModel()
    @State private var keyboardHeight: CGFloat = 0
      
    
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
                        Text("비밀번호 찾기")
                            .font(.custom("NeoDunggeunmoPro-Regular", size: 35))
                    }
                }
                
                // 사용자 ID 입력 칸
                TextField("사용 중인 아이디를 입력하세요", text: $viewModel.loginId)
                    .font(.custom("Galmuri14", size: 18))
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding()
                
                Button(action: {
                    viewModel.findPassword()
                }) {
                    Text("비밀번호 찾기")
                        .frame(width: 350, height: 40)
                        .background(Color(hex: "F3A7FF"))
                        .font(.custom("NeoDunggeunmoPro-Regular", size: 20))
                        .foregroundColor(.white)
                        .cornerRadius(13)
                }
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("알림"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("확인")))
            }
        }
        .environmentObject(viewModel)
    }
}

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}
