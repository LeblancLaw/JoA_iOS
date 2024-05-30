//
//  MyPageviewModel.swift
//  Real_J
//
//  Created by 최가의 on 2/5/24.
//

import Foundation
import Alamofire
import UIKit

class MyPageviewModel: ObservableObject {
    let baseURL = "https://real.najoa.net"
    
    private var decodedImageLoader = DecodedImageLoader()
    @Published var name: String = ""
    @Published var bio: String? = "" // 기본값 설정
    @Published var voteTop3: [String] = []
    @Published var newBio: String = "" // 새로운 한 줄 소개를 입력받을 변수
    
    @Published var todayHeart: Int = 0
    @Published var totalHeart: Int = 0
    @Published var urlCode: String? // urlCode를 String 타입의 Optional 변수로 선언
    @Published var profileImage: UIImage? = UIImage()
    @Published var showErrorPopup: Bool = false // 15자 초과시 팝업 띄우기
    @Published var selectedImage: UIImage? //갤러리에서 선택된 이미지 속성
    @Published var isImagePickerPresented = false //이미지 찍을 때
    @Published var imageURL: URL?  // 이미지의 URL을 저장할 변수
    @Published var shouldReloadView = false // 사진 변경 후 새로 고침 위해서
    @Published var showActionSheet = false
    @Published var showBioActionSheet = false
    @Published var showBioEditor: Bool = false
    
    //MARK: - 한 줄 소개 삭제 API 호출 함수
    func deleteIntroductionFromBackend(userData: UserData) {
        if let userId = userData.userId {
            let endpoint = "/joa/member-profiles/\(userId)/bio"
            let url = baseURL + endpoint
            
            AF.request(url, method: .patch)
                .responseData { [self] response in
                    print("Request: \(response.request)")
                    print("Response: \(response.response)")
                    print("Data: \(response.data)")
                    print("Error: \(response.error)")
                    switch response.result {
                    case .success(_):
                        // 성공적으로 삭제되었을 때
                        showAlertWithUserMypageUpdate(title: "알림", message: "한 줄 소개가 삭제되었습니다!", userData: userData)
                    case .failure(let error):
                        print("요청 실패: \(error)")
                        if let data = response.data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let code = json["code"] as? String {
                            switch code {
                            case "M001":
                                showAlert(title: "알림", message: "회원님의 정보를 찾을 수 없습니다!")
                            case "M004":
                                showAlert(title: "알림", message: "회원님은 일시정지된 상태입니다!")
                            case "M014":
                                showAlert(title: "알림", message: "회원님은 영구정지된 상태입니다!")
                            default:
                                showAlert(title: "알림", message: "서버 에러")
                            }
                        } else {
                            showAlert(title: "알림", message: "서버 에러")
                        }
                    }
                }
        }
    }
    
    //MARK: - 한 줄 소개 변경 API
    func saveIntroductionToBackend(introduction: String, userData: UserData) {
        // 백엔드 API URL
        let apiURL = "http://real.najoa.net/joa/member-profiles/bio"
        
        if let userId = userData.userId {
            // 전송할 파라미터 설정 (사용자 id와 변경된 한줄소개)
            let parameters: [String: Any] = [
                "id": userId, // 사용자 id
                "bio": introduction // 변경된 한줄소개
            ]
            
            print("전송된 데이터: \(parameters)")
            
            // Alamofire를 사용하여 POST 요청 보내기
            AF.request(apiURL, method: .patch, parameters: parameters, encoding: JSONEncoding.default)
                .responseJSON { [self] response in
                    print("Request: \(response.request)")
                    print("Response: \(response.response)")
                    print("Data: \(response.data)")
                    print("Error: \(response.error)")
                    switch response.result {
                    case .success(_):
                        if let statusCode = response.response?.statusCode {
                            if statusCode == 204 {
                                // 한 줄 소개 변경 성공
                                showAlert(title: "알림", message: "한 줄 소개 변경이 완료되었습니다!")
                            } else {
                                // 서버에서 에러 코드 확인
                                if let data = response.data,
                                   let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                                   let code = json["code"] as? String {
                                    switch code {
                                    case "M001":
                                        showAlert(title: "알림", message: "회원님의 정보가 없습니다!")
                                    case "M004":
                                        showAlert(title: "알림", message: "일시정지")
                                    case "M014":
                                        showAlert(title: "알림", message: "영정")
                                    default:
                                        showAlert(title: "알림", message: "서버 에러")
                                    }
                                } else {
                                    showAlert(title: "알림", message: "서버 에러")
                                }
                            }
                        }
                    case .failure(let error):
                        print("요청 실패: \(error)")
                        // 요청 실패시 에러 처리를 이곳에 추가합니다.
                        showAlert(title: "알림", message: "서버 에러")
                    }
                }
        }
    }

    
    func showAlertWithUserMypageUpdate(title: String, message: String, userData: UserData) {
        // 사용자에게 알림을 보여주고 확인 버튼을 누르면 getUserMypage를 호출
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            self.getUserMypage(userData: userData)
        })
        
        if let viewController = UIApplication.shared.windows.first?.rootViewController {
            viewController.present(alert, animated: true, completion: nil)
        }
    }
    
    //MARK: - 사용자 정보 불러오기
    func getUserMypage(userData: UserData) {
        if let userId = userData.userId {
            let endpoint = "/joa/member-profiles/\(userId)/my-page"
            let url = baseURL + endpoint
            
            if let userId = userData.userId {
                
                let parameters: [String: Any] = [
                    "id": userId
                ]
                
                print("Request Parameters: \(parameters)")
                
                AF.request(url, method: .get, parameters: parameters)
                    .responseJSON { response in
                        switch response.result {
                        case .success(let data):
                            // HTTP 상태 코드가 200인 경우
                            if let jsonData = data as? [String: Any], let status = jsonData["status"] as? Bool, status {
                                if let userData = jsonData["data"] as? [String: Any] {
                                    if let userName = userData["name"] as? String {
                                        self.name = userName
                                        print("사용자 이름: \(userName)")
                                    }
                                    if let urlCode = userData["urlCode"] as? String {
                                        self.urlCode = urlCode // 백엔드에서 반환한 urlCode를 사용하여 업데이트
                                        // self.loadProfileImage()
                                        print("URL 코드: \(urlCode)")
                                    } else {
                                        // urlCode가 없을 때, 기본 이미지로 설정
                                        self.urlCode = "my.png"
                                    }
                                    if let userBio = userData["bio"] as? String {
                                        self.bio = userBio
                                        print("사용자 소개: \(userBio)")
                                    }
                                    if let todayHeart = userData["todayHeart"] as? Int {
                                        self.todayHeart = todayHeart
                                        print("오늘의 하트 수: \(todayHeart)")
                                    }
                                    if let totalHeart = userData["totalHeart"] as? Int {
                                        self.totalHeart = totalHeart
                                        print("총 하트 수: \(totalHeart)")
                                    }
                                    if let voteTop3 = userData["voteTop3"] as? [String] {
                                        self.voteTop3 = voteTop3
                                        print("상위 3표: \(voteTop3)")
                                    }
                                }
                            } else {
                                // 백엔드에서의 응답이 실패하거나 status가 false인 경우
                                self.handleErrorResponse(data: data)
                            }
                        case .failure(let error):
                            // HTTP 요청 자체가 실패한 경우
                            print("오류: \(error)")
                            self.showAlert(title: "네트워크 오류", message: "다시 시도해주세요")
                        }
                    }
            }
        }
    }
    
    // 응답이 실패하거나 status가 false인 경우를 처리하는 함수
    func handleErrorResponse(data: Any?) {
        if let jsonData = data as? [String: Any], let errorCode = jsonData["code"] as? String {
            var errorMessage = ""
            switch errorCode {
            case "M001":
                errorMessage = "사용자를 찾을 수 없습니다!"
            case "M004":
                errorMessage = "일시 정지 된 계정입니다!"
            case "M014":
                errorMessage = "영구 정지된 계정입니다!"
            default:
                errorMessage = "알 수 없는 오류가 발생하였습니다."
            }
            self.showAlert(title: "오류", message: errorMessage)
        } else {
            self.showAlert(title: "오류", message: "알 수 없는 오류가 발생하였습니다.")
        }
    }
    
    // showAlert 함수 정의
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .default, handler: nil)
        alertController.addAction(okAction)
        UIApplication.shared.windows.first?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
    
    
    // 프로필 사진 업로드 함수
    func uploadProfilePicture(image: UIImage, userData: UserData) {
        // 이미지를 업로드하고 urlCode를 받아올 API 엔드포인트
        let uploadAPIURL = "https://real.najoa.net/joa/member-profiles/picture"
        
        if let userId = userData.userId {
            if let imageData = compressImage(image: image) {
                let base64String = imageData.base64EncodedString(options: [])
                // JSON 형식의 파라미터 생성
                let parameters: [String: Any] = [
                    "id": userId,
                    "base64Picture": base64String // 이미지를 Base64로 인코딩
                ]
                do {
                    // 파라미터를 JSON 데이터로 변환
                    let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
                    
                    // Alamofire를 사용하여 JSON 데이터를 업로드
                    AF.upload(jsonData, to: uploadAPIURL, method: .patch, headers: ["Content-Type": "application/json"])
                        .responseData { [self] response in
                            print("Request: \(response.request)")
                            print("Response: \(response.response)")
                            print("Data: \(response.data)")
                            print("Error: \(response.error)")
                            switch response.result {
                            case .success(_):
                                // 성공적으로 업로드 되었을 때
                                showAlertWithUserMypageUpdate(title: "알림", message: "프로필 사진 변경이 완료되었습니다!", userData: userData)
                            case .failure(let error):
                                print("업로드 실패: \(error)")
                                if let data = response.data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                                   let code = json["code"] as? String {
                                    switch code {
                                    case "M001":
                                        showAlert(title: "알림", message: "회원님의 계정을 찾을 수 없습니다!")
                                    case "M004":
                                        showAlert(title: "알림", message: "회원님은 일시 정지된 계정입니다!")
                                    case "M014":
                                        showAlert(title: "알림", message: "회원님은 영구정지된 계정입니다!")
                                    default:
                                        showAlert(title: "알림", message: "서버 에러")
                                    }
                                } else {
                                    showAlert(title: "알림", message: "서버 에러")
                                }
                            }
                        }
                } catch {
                    print("JSON 데이터 생성 실패: \(error)")
                    // JSON 데이터 생성 실패 시 에러 처리를 이곳에 추가
                    showAlert(title: "알림", message: "서버 에러")
                }
            }
        }
    }
    
    // 이미지를 압축하는 함수
    func compressImage(image: UIImage) -> Data? {
        // 이미지를 JPEG 데이터로 압축 | 0.0~1.0 값 활용 낮을 수록 화질 저하
        return image.jpegData(compressionQuality: 0.2)
    }
    
    
    // 프로필 사진 삭제 함수
    func deleteProfilePicture(userData: UserData) {
        if let userId = userData.userId {
            let apiURL = "https://real.najoa.net/joa/member-profiles/\(userId)/picture"
            
            AF.request(apiURL, method: .patch)
                .responseData { [self] response in
                    print("Request: \(response.request)")
                    print("Response: \(response.response)")
                    print("Data: \(response.data)")
                    print("Error: \(response.error)")
                    switch response.result {
                    case .success(_):
                        // 성공적으로 삭제되었을 때
                        showAlertWithUserMypageUpdate(title: "알림", message: "프로필 사진이 삭제되었습니다!", userData: userData)
                    case .failure(let error):
                        print("요청 실패: \(error)")
                        if let data = response.data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let code = json["code"] as? String {
                            switch code {
                            case "M001":
                                showAlert(title: "알림", message: "회원님의 정보를 찾을 수 없습니다!")
                            case "M004":
                                showAlert(title: "알림", message: "회원님은 일시정지된 상태입니다!")
                            case "M014":
                                showAlert(title: "알림", message: "회원님은 영구정지된 상태입니다!")
                            default:
                                showAlert(title: "알림", message: "서버 에러")
                            }
                        } else {
                            showAlert(title: "알림", message: "서버 에러")
                        }
                    }
                }
        }
    }
}
