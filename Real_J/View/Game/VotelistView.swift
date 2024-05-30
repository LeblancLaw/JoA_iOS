import SwiftUI
import Alamofire


struct VoteCategory: Identifiable {
    let id: Int64
    let title: String
    var color: Color // 색상 속성 추가
}

struct VotelistView: View {
    @Binding var voteItems: [String] // 투표 받은 항목 gameView에서 전달 받으려고
    
    let columns: [GridItem] = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
    @State private var voteList: [(voteId: Int, categoryId: Int, hint: String)] = []
    
    @State private var selectedVoteItem: String?
    @State private var selectedVoteItemHint: String? // 힌트를 저장할 새로운 상태 변수
    @State private var isShowingHint = false
    @State private var reportContent: String = ""
    @EnvironmentObject var userData: UserData
    @State private var selectedVoteId: Int?
    @State private var isReportingCategoriesVisible = false // 신고 카테고리 표시 여부
    @State private var selectedReportCategory: Int? // 신고한 카테고리 선택
    @State private var selectedVoteItemPosition: CGPoint = .zero
    @State private var showErrorAlert = false
    @State private var alertTitle = "" // 추가: 알림 타이틀
    @State private var showConfirmationAlert = false
    @State private var alertMessage = "" // 추가: 알림 메시지
    @Environment(\.presentationMode) var presentationMode
    
    let gradientColors:[Color] = [
        Color(hex: "FFFFFF"),
        Color(hex: "77EFFF"),
        Color(hex: "CBF9FF"),
        Color(hex: "FFFFFF")
    ]
    
    // VoteCategory 목록을 가져오는 함수
    func getVoteCategories(categoryId: Int) -> VoteCategory? {
        let fullList = [
            VoteCategory(id: 1, title: "🍚\n선배님 밥 사주세요!", color: Color(hex: "FFDADA")),
            VoteCategory(id: 2, title: "💪🏻\n혹시 3대 500?", color: Color(hex: "FF0099")),
            VoteCategory(id: 3, title: "🛍️\n이 강의실의 패피는 바로 너", color: Color(hex: "FAFFDA")),
            VoteCategory(id: 4, title: "🎮\n페이커 뺨 칠 거 같음", color: Color(hex: "2F42E5")),
            VoteCategory(id: 5, title: "🍻\n친해지고 싶어요", color: Color(hex: "A853FC")),
            VoteCategory(id: 6, title: "💯\n과탑일 거 같아요", color: Color(hex: "F19CFF")),
            VoteCategory(id: 7, title: "📚\n팀플 같이 하고 싶어요", color: Color(hex: "F8E893")),
            VoteCategory(id: 8, title: "🏫\n끝나고 뭐 하는지 궁금해요", color: Color(hex: "BDBDBD")),
            VoteCategory(id: 9, title: "🫶🏻\n존잘/존예이십미다", color: Color(hex: "DD999D")),
        ]
        
        return fullList.first { item in
            item.id == categoryId
        }
    }
    
    var body: some View {
        ZStack{
            LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Text("투표함")
                    .font(.custom("NeoDunggeunmoPro-Regular", size: 30))
                    .padding(.bottom, 5)
                    .padding(.top, 1)
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(voteList, id: \.voteId) { voteItem in
                            if let voteCategory = getVoteCategories(categoryId: voteItem.categoryId) {
                                Button(action: {
                                    selectedVoteItem = voteCategory.title
                                    selectedVoteItemHint = voteItem.hint
                                    isShowingHint = true
                                    selectedVoteId = voteItem.voteId
                                }, label: {
                                    VStack {
                                        Text(voteCategory.title)
                                            .font(.custom("GalmuriMono11", size: 20))
                                            .frame(width: 150, height: 150)
                                            .background(voteCategory.color)
                                            .foregroundColor(.black)
                                            .cornerRadius(10)
                                        Text("클릭해서 힌트 보기")
                                            .font(.custom("NeoDunggeunmoPro-Regular", size: 14))
                                            .foregroundColor(.white)
                                            .padding(5)
                                            .background(Color(hex: "#feb0ff"))
                                            .cornerRadius(5)
                                    }
                                })
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .sheet(isPresented: $isShowingHint) {
                        VStack {
                            Text(selectedVoteItem ?? "")
                                .font(.custom("NeoDunggeunmoPro-Regular", size: 20))
                                .multilineTextAlignment(.center) //가운데 정렬
                            
                            Text("'\(selectedVoteItemHint ?? "")'")
                                .font(.custom("GalmuriMono11", size: 25))
                                .foregroundColor(.black)
                                .padding(.top, 5)
                                .multilineTextAlignment(.center)
                            
                            Text("상대가 보낸 힌트 내용이 부적절하다고 판단되면 \n 🔻를 통해 신고 카테고리와 신고 내용을 입력해 신고해주세요!")
                                .font(.custom("GalmuriMono11", size: 10))
                                .foregroundColor(.gray)
                                .padding()
                                .multilineTextAlignment(.center)
                            
                            HStack {
                                Menu {
                                    ForEach(0..<3) { index in
                                        Button(action: {
                                            selectedReportCategory = index + 1
                                            isReportingCategoriesVisible.toggle()
                                        }) {
                                            Text(getReportCategoryTitle(index))
                                        }
                                    }
                                } label: {
                                    Text("🔻")
                                }
                                .padding(.horizontal)
                                TextField("신고 내용을 입력하세요.", text: $reportContent)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Button(action: {
                                    if selectedReportCategory == nil {
                                        // 신고 카테고리를 선택하지 않았을 때
                                        showErrorAlert = true
                                    } else if reportContent.isEmpty {
                                        // 신고 내용이 비어 있을 때
                                        showErrorAlert = true
                                    } else {
                                        // "허위 신고" 확인 팝업 띄우기
                                        showConfirmationAlert = true
                                    }
                                }, label: {
                                    Image(systemName: "exclamationmark.triangle.fill") // 아이콘으로 변경
                                        .font(.system(size: 20)) // 원하는 아이콘 크기로 조정
                                        .foregroundColor(.yellow)
                                })
                                .alert(isPresented: $showConfirmationAlert) {
                                    Alert(
                                        title: Text("허위 신고 확인"),
                                        message: Text("허위 신고는 JoA의 운영 체제에 의해 불이익 대상이 됩니다. 해당 내용을 신고하시겠습니까?"),
                                        primaryButton: .destructive(Text("확인")) {
                                            if let voteId = selectedVoteId, let reportCategory = selectedReportCategory {
                                                sendReportToServer(voteId: voteId, reportId: reportCategory, content: reportContent, voteItem: selectedVoteItem ?? "")
                                                reportContent = ""
                                                isShowingHint = false
                                            }
                                        },
                                        secondaryButton: .cancel()
                                    )
                                
                                }
                            }
                            Text("✔️ 신고 사유와 신고 카테고리를 모두 선택하여야 신고가 완료됩니다! 선택하지 않는 경우 신고가 완료되지 않아요!!")
                                .font(.custom("GalmuriMono11", size: 12))
                                .foregroundColor(.gray)
                                .padding()
                                .multilineTextAlignment(.center)
                            
                            .onAppear{
                                getVoteListForUser()
                                //selectedVoteItemPosition = .zero
                            }
                        }
                        .padding()
                        .background(.white)
                        .cornerRadius(10)
                        .frame(width: 350, height: 400)
                        // .position(x: geometry.size.width * 0.5, y: geometry.size.height * -20.0) // x축 0.5 기준 이상은 오른쪽, y축 위아래
                        //.position(x: selectedVoteItemPosition.x - geometry.frame(in: .global).minX + geometry.size.width / 4, y: selectedVoteItemPosition.y - geometry.frame(in: .global).minY - geometry.size.height / 2)
                    }
                }.onAppear{
                    getVoteListForUser()
                    //selectedVoteItemPosition = .zero
                }
            }
        }
    }
    func showErrorAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showErrorAlert = true
    }
    
    func getReportCategoryTitle(_ index: Int) -> String {
        switch index {
        case 0:
            return "욕설/비방/혐오/차별적 표현"
        case 1:
            return "성희롱"
        case 2:
            return "기타"
        default:
            return ""
        }
    }
    
    //MARK: - 투표 신고하기
    func sendReportToServer(voteId: Int, reportId: Int, content: String, voteItem: String) {
        let parameters: [String: Any] = [
            "voteId": voteId,
            "reportId": reportId,
            "content": content, // 신고 내용 추가
        ]
        print("신고할 때 백엔드로 보낸 값 = \(parameters)")
        AF.request("http://real.najoa.net/joa/reports/vote", method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    if let status = response.response?.statusCode {
                        print("신고 API 호출 성공 - Status: \(status), Response: \(value)")
                        if let responseDict = value as? [String: Any], let statusValue = responseDict["status"] as? Bool {
                            if statusValue {
                                // 성공적으로 신고된 경우
                                self.alertTitle = "신고 완료!"
                                self.alertMessage = "신고 완료 되었습니다."
                                self.showConfirmationAlert = true
                                selectedReportCategory = nil
                                reportContent = ""
                                isShowingHint = false
                                getVoteListForUser()
                            } else {
                                // 백엔드에서 오류 코드가 전달된 경우
                                if let code = responseDict["code"] as? String {
                                    switch code {
                                    case "M001":
                                        // 사용자를 찾을 수 없는 경우
                                        self.alertTitle = "회원님의 정보를 찾을 수 없습니다"
                                        self.alertMessage = "지속적인 문제 발생 시 고객센터로 문의 부탁드립니다!"
                                    case "RC001":
                                        // 신고 카테고리를 선택하지 않은 경우
                                        self.alertTitle = "신고 불가"
                                        self.alertMessage = "신고 카테고리 선택 후 재시도 해주세요!"
                                    case "V001":
                                        // 투표가 존재하지 않는 경우
                                        self.alertTitle = "투표 항목 오류"
                                        self.alertMessage = "투표 목록 확인 화면을 다시 접속해주세요!"
                                    case "VR001":
                                        // 투표가 존재하지 않는 경우
                                        self.alertTitle = "중복 신고 불가"
                                        self.alertMessage = "이미 신고한 항목입니다!"
                                    default:
                                        // 기타 오류인 경우
                                        self.alertTitle = "이용불가"
                                        self.alertMessage = "서버에서 유효한 응답을 받지 못했습니다. \n 관리자에게 문의하세요."
                                    }
                                    self.showErrorAlert = true
                                }
                            }
                        }
                    }
                    
                case .failure(let error):
                    // API 호출 실패한 경우
                    print("API 호출 실패: \(error)")
                    self.alertTitle = "네트워크 오류"
                    self.alertMessage = "네트워크 연결을 확인하고 다시 시도해주세요"
                    self.showErrorAlert = true
                }
            }
    }

    //MARK: - 투표 목록 받아오는 함수
    func getVoteListForUser() {
        
        if let takeId = userData.userId {
            let parameters: [String: Any] = ["takeId": takeId]
            AF.request("https://real.najoa.net/joa/votes/\(takeId)", method: .get)
               // .validate()
                .responseJSON { response in
                    switch response.result {
                    case .success(let value):
                        // API 호출 성공
                        if let status = response.response?.statusCode {
                            print("API 호출 성공 - Status: \(status), Response: \(value)")
                            
                            if let jsonDict = value as? [String: Any], let status = jsonDict["status"] as? Bool {
                                if status, let data = jsonDict["data"] as? [String: Any], let voteList = data["voteList"] as? [[String: Any]] {
                                    // 투표 목록 데이터 업데이트
                                    DispatchQueue.main.async {
                                        self.voteList = voteList.compactMap { dict in
                                            if let voteId = dict["voteId"] as? Int,
                                               let categoryId = dict["categoryId"] as? Int,
                                               let hint = dict["hint"] as? String {
                                                return (voteId: voteId, categoryId: categoryId, hint: hint)
                                            }
                                            return nil
                                        }
                                    }
                                } else if let code = jsonDict["code"] as? String {
                                    handleAPIError(code: code)
                                }
                            }
                        }
                    case .failure(let error):
                        // API 호출 실패
                        print("API 호출 실패: \(error)")
                    }
                }
        }
        // 예외상황에 대한 처리 함수
        func handleAPIError(code: String) {
            var errorMessage = ""
            switch code {
            case "M001":
                errorMessage = "회원정보가 존재하지 않습니다! 지속적인 문제 발생 시 고객센터로 문의해주세요!"
            case "M014":
                errorMessage = "회원님은 영구정지된 계정으로 JoA 이용이 불가합니다!"
            case "M004":
                errorMessage = "회원님은 일시정지된 계정으로 JoA 이용이 일시적으로 불가합니다!"
            default:
                errorMessage = "서버에서 유효한 응답을 받지 못했습니다. \n 관리자에게 문의하세요."
            }
            self.alertTitle = "서버 에러"
            self.alertMessage = "투표 목록 확인 화면을 다시 접속해주세요!"
        }
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        let userData = UserData()
        return GameView(userData: userData)
            .environmentObject(userData)
            .onAppear {
                userData.userId = 7309167258
            }
    }
}
