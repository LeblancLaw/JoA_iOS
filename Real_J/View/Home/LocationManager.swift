import Foundation
import UIKit
import Alamofire
import CoreLocation

struct LocationData: Encodable {
    let id: Int64
    let latitude: Double
    let longitude: Double
    let altitude: Double
}

class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocation?
    private var lastLocationUpdateTime: Date?
    @Published var isLocationCheckEnabled: Bool = true
    var userData: UserData?
    let allowedTimeRange = (startHour: 00, startMinute: 00, endHour: 24, endMinute: 00)
    let updateInterval: TimeInterval = 1800
    let minDistanceFilter: CLLocationDistance = 5
    
    private var updateTimer: Timer?
    
    private let locationManager = CLLocationManager()
    
    let popupShownKey = "popupShown"
    
    func displayPopupIfNeeded() {
        // UserDefaults에서 팝업을 이미 확인했는지 여부를 가져옴
        let popupShown = UserDefaults.standard.bool(forKey: popupShownKey)
        
        // 팝업을 이미 확인한 경우에는 더 이상 보여주지 않음
        guard !popupShown else { return }
        
        // 팝업을 보여주고 상태를 저장
        displayPopup(title: "Where are U?", message: "현재 위치가 학교 안이 아니에요! JoA는 학교 내에서만 이용가능합니다.")
        UserDefaults.standard.set(true, forKey: popupShownKey)
    }

    init(userData: UserData) {
        super.init()
        self.userData = userData
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        
        requestLocation()
    }
    func resetLocation() {
        userLocation = nil
        lastLocationUpdateTime = nil
    }
    
    func requestLocation() {
        print("요청 전에 메시지 출력 : 위치 권한 요청")
        
        let currentAuthorizationStatus = CLLocationManager.authorizationStatus()
        
        switch currentAuthorizationStatus {
        case .notDetermined:
            // 위치 권한을 아직 요청하지 않은 경우, 요청
            manager.delegate = self
            manager.desiredAccuracy = kCLLocationAccuracyBest
            
            // 위치 권한 요청 시 사용자에게 표시할 메시지 설정
            manager.requestWhenInUseAuthorization()
            
            startUpdatingLocation()
        case .authorizedWhenInUse, .authorizedAlways:
            // 이미 위치 권한이 허용된 경우, 위치 업데이트 시작
            startUpdatingLocation()
        case .denied, .restricted:
            // 사용자가 위치 권한을 거부한 경우 또는 제한된 경우
            // 필요한 처리를 추가할 수 있습니다.
            break
        @unknown default:
            break
        }
    }
    
    func startUpdatingLocation() {
        if CLLocationManager.locationServicesEnabled() {
            let currentTime = Calendar.current.dateComponents([.hour, .minute], from: Date())
            if let currentHour = currentTime.hour, let currentMinute = currentTime.minute {
                if currentHour >= allowedTimeRange.startHour && currentHour <= allowedTimeRange.endHour {
                    if currentHour == allowedTimeRange.startHour && currentMinute >= allowedTimeRange.startMinute {
                        // 시작 시간 내
                        isLocationCheckEnabled = true
                        manager.startUpdatingLocation()
                        if userLocation != nil {
                            sendLocationToBackend()
                        }
                    } else if currentHour == allowedTimeRange.endHour && currentMinute < allowedTimeRange.endMinute {
                        // 종료 시간 내
                        isLocationCheckEnabled = true
                        manager.startUpdatingLocation()
                        if userLocation != nil {
                            sendLocationToBackend()
                        }
                    } else {
                        // 시간 범위 내에 있지만 학교 범위 밖
                        isLocationCheckEnabled = true
                        //  displayPopup(title: "학교 내부가 아닙니다!", message: "학교로 이동해주세요!")
                        manager.startUpdatingLocation()
                        if userLocation != nil {
                            sendLocationToBackend()
                        }
                    }
                } else {
                    // 시간 범위 밖
                    isLocationCheckEnabled = false
                    displayPopup(title: "지금은 주변 친구를 확인할 수 있는 시간이 아닙니다!", message: "")
                }
            }
        }
    }
    
    func displayPopup(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        
        if let viewController = UIApplication.shared.windows.first?.rootViewController {
            viewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    struct ResponseModel: Decodable {
        let isContained: Bool?
        let code: String?
        
        enum CodingKeys: String, CodingKey {
            case isContained = "isContained"
            case code
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.isContained = try container.decodeIfPresent(Bool.self, forKey: .isContained)
            self.code = try container.decodeIfPresent(String.self, forKey: .code)
        }
    }
    
    
    func sendLocationToBackend() {
       // print("sendLocationToBackend 함수 호출됨")
        
        // 사용자의 위치가 유효하고 위치 체크가 활성화되어 있는 경우에만 업데이트
        guard let userLocation = userLocation, let userId = userData?.userId else {
            print("사용자 위치를 가져올 수 없거나 위치 체크가 비활성화되어 있음 또는 userId가 설정되지 않음")
            print("\(userLocation), \(userData?.userId)")
            resetLocation()
            userData = nil
            
            return
        }
        print("\(userData?.userId)")
        
        if let userId = userData?.userId {
            let locationData = LocationData(
                id: userId,
                latitude: userLocation.coordinate.latitude,
                longitude: userLocation.coordinate.longitude,
                altitude: userLocation.altitude
            )
            
            let url = "https://real.najoa.net/joa/locations"
            
            if isLocationCheckEnabled {
                print("보낸 데이터:")
                print("User ID: \(userId)")
                print("Latitude: \(locationData.latitude)")
                print("Longitude: \(locationData.longitude)")
                print("Altitude: \(locationData.altitude)")
                
                AF.request(url, method: .patch, parameters: locationData, encoder: JSONParameterEncoder.default)
                    .response { response in
                        if let statusCode = response.response?.statusCode {
                          //  print("서버 응답 코드: \(statusCode)") // 백엔드의 응답 코드 출력
                            if statusCode == 200 {
                                if let data = response.data {
                                    do {
                                        let decoder = JSONDecoder()
                                        let responseModel = try decoder.decode(ResponseModel.self, from: data)
                                        
                                        if let isContained = responseModel.isContained {
                                            if isContained {
                                                print("사용자의 위치 업데이트 및 제약 조건 처리 완료")
                                            } else {
                                                print("사용자가 위치 범위 내에 없습니다!")
                                                print("dd" , isContained)
                                                self.displayPopupIfNeeded() //where are U 팝업
                                                
                                                self.isLocationCheckEnabled = false
                                                self.manager.stopUpdatingLocation() // 위치 업데이트 중지
                                                
                                                DispatchQueue.global().async { //이렇게 해야 백그라운드에서 30분 카운트 가능
                                                    Thread.sleep(forTimeInterval: 1800)
                                                    DispatchQueue.main.async {
                                                        self.isLocationCheckEnabled = true
                                                        self.startUpdatingLocation()
                                                        print("사용자 위치 범위 밖 30분 후에 다시 시작")
                                                    }
                                                }
                                            }
                                        }

                                        if let errorCode = responseModel.code {
                                            switch errorCode {
                                            case "M001":
                                                print("사용자를 찾을 수 없습니다!")
                                                self.displayPopup(title: "사용자가 존재하지 않습니다!", message: "사용자가 존재하지 않습니다! 회원가입 혹은 로그인 해주세요")
                                            case "M014":
                                                print("영구정지된 계정입니다!")
                                                self.displayPopup(title: "이용불가", message: "회원님은 영구정지된 계정으로 JoA 이용이 불가합니다.")
                                            case "M004":
                                                print("일시정지된 계정입니다!")
                                                self.displayPopup(title: "이용불가", message: "회원님은 일시정지된 계정으로 JoA 이용이 일시적으로 불가합니다.")
                                            case "L001":
                                                print("사용자를 찾을 수 없습니다!")
                                                self.displayPopup(title: "위치 확인 불가", message: "현재 회원님의 위치 확인이 불가합니다. 확인 후 다시 시도해주세요!")
                                            case "M003":
                                                print("사용자를 찾을 수 없습니다!")
                                                self.displayPopup(title: "사용자가 존재하지 않습니다!", message: "사용자가 존재하지 않습니다! 회원가입 혹은 로그인 해주세요")
                                            case "P001":
                                                print("사용자를 찾을 수 없습니다!")
                                                self.displayPopup(title: "사용자가 존재하지 않습니다!", message: "사용자가 존재하지 않습니다! 회원가입 혹은 로그인 해주세요")
                                                
                                            default:
                                                print("알 수 없는 오류 발생")
                                            }
                                        }
                                        
                                    } catch {
                                        print("에러 발생:", error)
                                    }
                                }
                            } else {
                                print("위치 업데이트 실패 - HTTP Status Code: \(statusCode)")
                            }
                        }
                    }
                }
            }
        }
    }

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            print("위치 권한 요청이 아직 결정되지 않음")
            manager.requestWhenInUseAuthorization()
        case .restricted:
            print("위치 권한이 제한됨")
            manager.requestWhenInUseAuthorization()
        case .denied:
            print("사용자가 위치 권한을 거부함")
        case .authorizedAlways:
            print("항상 위치 권한 허용")
            startUpdatingLocation()
        case .authorizedWhenInUse:
            print("사용 중일 때 위치 권한 허용")
            startUpdatingLocation()
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        print("현재 위치 - 위도: \(location.coordinate.latitude), 경도: \(location.coordinate.longitude), 고도: \(location.altitude)")
        
        if let lastLocation = userLocation {
            let distance = location.distance(from: lastLocation)
            print("Distance: \(distance) meters")
            
            if distance >= minDistanceFilter {
               // print("Sending location update to backend")
                
                self.userLocation = location
                sendLocationToBackend()
            }
        } else {
            self.userLocation = location
            sendLocationToBackend()
        }
    }
}
