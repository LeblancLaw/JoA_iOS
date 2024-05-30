//
//  Join_EmailViewModel.swift
//  Real_J
//
//  Created by 최가의 on 1/31/24.
//

import Foundation
import Alamofire
import UIKit
import SwiftUI

class JoinEmailViewModel: ObservableObject {
    @EnvironmentObject var userData: UserData
    @Published var userId: Int64? // 받아온 사용자의 고유 id
    @Published var emailText: String = ""
    @Published var verificationCodes: String = ""
    @Published var collegeId: Int64 = 1
    @Published var isVerificationCompleted = false
    @Published var isButtonDisabled = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var timerSeconds = 420
    @Published private var responseData: MemberResponse?
    @Published var isJoinedIn = false
    
    
    struct MemberResponse: Codable {
        let status: Bool
        let data: MemberData?
        let code: String?
        let statusCode: Int?
        
        struct MemberData: Codable {
            let id: Int64?
        }
    }
    
    let baseURL = "https://real.najoa.net"
    
    func fetchDataFromServer() {
        let endpoint = "/joa/members/certify-num/send"
        let url = baseURL + endpoint
        
        let parameters: [String: Any] = [
            "collegeEmail": emailText,
            "collegeId": collegeId
        ]
        
        print("전송된 데이터: \(parameters)")
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseDecodable(of: MemberResponse.self) { [self] response in
                let statusCode = response.response?.statusCode
                
                print("Request: \(response.request)")
                print("Response: \(response.response)")
                print("Data: \(response.data)")
                print("Error: \(response.error)")
                switch response.result {
                case .success(let data):
                    self.responseData = data
                    print("인증번호 전송 시 받은 데이터: \(data)")
                    // 사용자 ID를 UserDefaults에 저장
                    if let userID = data.data?.id {
                        UserDefaults.standard.set(userID, forKey: "userID")
                        self.userId = userID // 수신된 사용자 ID 저장
                    }
                    // 응답 코드에 따른 팝업 메시지 표시 로직 추가
                    if data.status {
                        // 인증 성공
                        self.showAlert = true
                        self.alertMessage = "웹 메일로 인증번호가 전송되었습니다!"
                    } else {
                        // 인증 실패
                        if let errorCode = data.code {
                            switch errorCode {
                            case "M005":
                                self.showAlert = true
                                self.alertMessage = "이미 존재하는 사용자입니다!"
                            case "M014":
                                self.showAlert = true
                                self.alertMessage = "회원님은 영구정지 대상으로 JoA 이용이 불가합니다."
                            case "P001":
                                self.showAlert = true
                                self.alertMessage = "학교 정보를 찾을 수 없습니다."
                            case "M006":
                                self.showAlert = true
                                self.alertMessage = "가입 중인 이메일입니다! 메일함을 확인해주세요"
                            default:
                                self.showAlert = true
                                self.alertMessage = "알 수 없는 오류가 발생하였습니다."
                            }
                        }
                    }
                case .failure(let error):
                    print("Error: \(error)")
                    showAlert = true
                    alertMessage = "네트워크 오류가 발생했습니다."
                }
            }
    }
    
    
    // MARK: - 인증번호 확인
    func verifyCode() {
        let endpoint = "/joa/members/certify-num/verify"
        let url = baseURL + endpoint
        
        let parameters: [String: Any] = [
            "id": userId ?? 0, // 회원 고유 id 불러오도록
            "certifyNum": verificationCodes
        ]
        
        print("인증번호 확인 시 전송된 데이터: \(parameters)")
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .response { [self] response in
                print("Response: \(response)")
                print("Request: \(response.request)")
                print("Response: \(response.response)")
                print("Data: \(response.data)")
                print("Error: \(response.error)")
                switch response.result {
                case .success(let data):
                    if let statusCode = response.response?.statusCode {
                        if statusCode == 204 {
                            // 인증 성공
                            self.isVerificationCompleted = true
                            showAlert = true
                            alertMessage = "인증번호가 확인되었습니다!"
                            
                        } else if let data = data {
                            do {
                                let decodedData = try JSONDecoder().decode(MemberResponse.self, from: data)
                                // 인증 실패
                                if let errorCode = decodedData.code {
                                    switch errorCode {
                                    case "M009":
                                        showAlert = true
                                        alertMessage = "인증번호가 잘못되었어요! 올바르게 다시 입력해주세요!"
                                    case "M007":
                                        showAlert = true
                                        alertMessage = "회원정보가 올바르지 않습니다. 지속적인 문제 발생 시 고객센터에 문의해주세요!"
                                    default:
                                        showAlert = true
                                        alertMessage = "알 수 없는 오류가 발생하였습니다."
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
                    alertMessage = "서버에서 오류가 발생하였습니다!"
                    isVerificationCompleted = false
                }
            }
    }
}
