import Foundation
import Alamofire

class ForgotPasswordViewModel: ObservableObject {
    
    let baseURL = "https://real.najoa.net"
    
    @Published var loginId: String = ""
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    func findPassword() {
        let endpoint = "/joa/members/password/find"
        let url = baseURL + endpoint
        
        let parameters: [String: Any] = [
            "loginId": loginId
        ]
        
        print("보낸 파라미터: \(parameters)")
        
        AF.request(url, method: .get, parameters: parameters)
            .responseJSON { response in
                print("Request: \(response.request)")
                print("Response: \(response.response)")
                print("Data: \(response.data)")
                print("Error: \(response.error)")
                
                switch response.result {
                case .success:
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
                                        case "M001":
                                            self.showAlert = true
                                            self.alertMessage = "사용자를 찾을 수 없습니다."
                                        default:
                                            self.showAlert = true
                                            self.alertMessage = "서버에서 유효한 응답을 받지 못했습니다."
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
                        self.alertMessage = "관리자에게 문의하세요."
                    }
                }
            }
    }
}
