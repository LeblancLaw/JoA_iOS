import Foundation
import Alamofire

class ChangePasswordViewModel: ObservableObject {
    let baseURL = "https://real.najoa.net"
    
    @Published var loginId: String = ""
    @Published var currentPassword: String = ""
    @Published var newPassword: String = ""
    @Published var newPasswordConfirmation: String = ""
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var showConfirmationAlert = false
    
    struct MemberResponse: Codable {
        let status: Bool
        let data: MemberData?
        let code: String?
        let statusCode: Int?

        struct MemberData: Codable {
            let id: Int64
        }
    }

    func changePassword(userData: UserData) {
        let endpoint = "/joa/members/password"
        let url = baseURL + endpoint
        
        let parameters: [String: Any] = [
            "id": userData.userId,
            "currentPassword": currentPassword,
            "newPassword": newPassword
        ]
        
        print("보낸 파라미터: \(parameters)")
        
        AF.request(url, method: .patch, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                print("Response: \(response.response)")
                switch response.result {
                case .success:
                    guard let statusCode = response.response?.statusCode else {
                        // 상태 코드가 없을 때 처리
                        self.showAlert = true
                        self.alertMessage = "서버 응답이 올바르지 않습니다."
                        return
                    }

                    switch statusCode {
                    case 204:
                        // 성공 상태 코드 처리
                        self.showAlert = true
                        self.alertMessage = "비밀번호 변경이 완료되었습니다!"
                    default:
                        // 다른 상태 코드에 대한 처리
                        if let data = response.data {
                            do {
                                let decoder = JSONDecoder()
                                let memberResponse = try decoder.decode(MemberResponse.self, from: data)

                                if memberResponse.status{
                                    // 성공적인 응답에 대한 처리
                                    if let memberId = memberResponse.data?.id {
                                        self.showAlert = true
                                        self.alertMessage = "비밀번호 변경이 완료되었습니다!"
                                        
                                    }
                                } else {
                                    // 실패한 응답에 대한 처리
                                    if let errorCode = memberResponse.code {
                                        self.handleErrorResponse(errorCode: errorCode)
                                    }
                                }
                            } catch {
                                print("Error decoding response: \(error)")
                                self.showAlert = true
                                self.alertMessage = "서버 응답을 처리하는 도중 오류가 발생했습니다."
                            }
                        }
                    }
                case .failure(let error):
                    print("Error: \(error)")
                    if let statusCode = response.response?.statusCode, statusCode == 404 {
                        self.showAlert = true
                        self.alertMessage = "관리자에게 문의하세요."
                    } else {
                        self.showAlert = true
                        self.alertMessage = "서버 응답을 처리하는 도중 오류가 발생했습니다."
                    }
                }
            }
    }

    private func handleErrorResponse(errorCode: String) {
        switch errorCode {
        case "M012":
            self.showAlert = true
            self.alertMessage = "비밀번호는 대/소문자 포함 8~16자 사이로 입력해주세요!"
        case "M001":
            self.showAlert = true
            self.alertMessage = "사용자를 찾을 수 없습니다!"
        case "M015":
            self.showAlert = true
            self.alertMessage = "비밀번호가 올바르지 않습니다!"
        default:
            self.showAlert = true
            self.alertMessage = "서버에서 유효한 응답을 받지 못했습니다."
        }
    }
}
