import SwiftUI
import Alamofire
import Foundation

struct ChangePasswordView: View {
    @StateObject private var viewModel = ChangePasswordViewModel()
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    //세션 id 저장
    @EnvironmentObject var userData: UserData
    
    
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
                HStack {
                    Image("main")
                        .resizable()
                        .frame(width: 60, height: 60)
                    VStack {
                        Text("비밀번호 변경하기")
                            .font(.custom("NeoDunggeunmoPro-Regular", size: 35))
                    }
                }
                
                Spacer().frame(height: 20)
                
                VStack {
                    HStack {
                        Text("현재\n비밀번호")
                            .font(.custom("Galmuri14", size: 15))
                            .multilineTextAlignment(.center)
                        
                        SecureField("현재 비밀번호", text: $viewModel.currentPassword)
                            .font(.custom("Galmuri14", size: 16))
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .padding(.bottom, 0.5)
                            .padding(.bottom, 5)
                    }
                    
                    HStack {
                        Text("새\n비밀번호")
                            .font(.custom("Galmuri14", size: 15))
                            .multilineTextAlignment(.center)
                        
                        TextField("새 비밀번호", text: $viewModel.newPassword)
                            .font(.custom("Galmuri14", size: 16))
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .padding(.bottom, 5)
                    }
                    
                    HStack {
                        Text("비밀번호\n확인")
                            .font(.custom("Galmuri14", size: 15))
                            .multilineTextAlignment(.center)
                        TextField("새 비밀번호 확인", text: $viewModel.newPasswordConfirmation)
                            .font(.custom("Galmuri14", size: 16))
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }
                .frame(maxWidth: .infinity) // 수평 가운데 정렬을 위한 Frame 설정
                .padding() // 전체적인 패딩 추가
                
                Button(action: {
                    if areAllFieldsFilled() {
                        if viewModel.newPassword == viewModel.newPasswordConfirmation {
                            if isPasswordValid(viewModel.newPassword) {
                                print("All conditions met. Proceed with API call.")
                                viewModel.changePassword(userData: userData)
                            } else {
                                self.displayPopup(title: "오류", message: "비밀번호는 대소문자, 특수기호를 포함한 8~16자리여야 합니다.")
                            }
                        } else {
                            self.displayPopup(title: "오류", message: "입력하신 새 비밀번호가 일치하지 않습니다.")
                        }
                    } else {
                        self.displayPopup(title: "오류", message: "모든 칸을 입력해주세요")
                    }
                }) {
                    Text("비밀번호 변경하기")
                        .font(.custom("Galmuri14", size: 16))
                        .frame(width: 350, height: 40)
                        .background(Color(hex: "F3A7FF"))
                        .font(.custom("NeoDunggeunmoPro-Regular", size: 20))
                        .foregroundColor(.white)
                        .cornerRadius(13)
                }
            }
            .padding(.vertical)
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text("알림"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("확인")))
        }
    }
    
    func displayPopup(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        
        if let viewController = UIApplication.shared.windows.first?.rootViewController {
            viewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    //MARK: - 빈 필드 있는 경우 팓단 함수
    func areAllFieldsFilled() -> Bool {
        let allFieldsFilled =
        !viewModel.currentPassword.isEmpty &&
        !viewModel.newPassword.isEmpty &&
        !viewModel.newPasswordConfirmation.isEmpty
        
        print("areAllFieldsFilled: \(allFieldsFilled)")
        return allFieldsFilled
    }
    
    func isPasswordValid(_ password: String) -> Bool {
        let passwordRegex = "^(?=.*[a-z])(?=.*[A-Z])(?=.*[!@#$%^&*()_+\\-=\\[\\]{};':\",./<>?])(?=.*\\d).{8,16}$"
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        
        let isValid = passwordPredicate.evaluate(with: password)
        print("isPasswordValid: \(isValid)")
        
        return isValid
    }
}

struct ChangePasswordView_Previews: PreviewProvider {
    static var previews: some View {
        let userData = UserData()
        return ChangePasswordView()
            .environmentObject(userData)
            .onAppear {
                userData.userId = 131313
            }
    }
}

