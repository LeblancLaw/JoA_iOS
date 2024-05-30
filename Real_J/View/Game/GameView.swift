import SwiftUI
import Alamofire
import SDWebImageSwiftUI  // SDWebImageSwiftUI 라이브러리를 사용하여 이미지를 비동기로 로드합니다.
import Foundation


struct VotingItem: Identifiable {
    let id: Int64
    let title: String
    var selectedFriend: Friend?
    var color: Color
}

struct Friend: Identifiable, Equatable {
    let id: Int64
    let name: String
    let profileImage: String?
    let bio: String
}

//MARK: - 하트 누를 수 있는 화면
struct FriendSelectionSheet: View {
    let gradientColors2:[Color] = [
        Color(hex: "6D8BFF"),
        Color(hex: "FFFFFF"),
        Color(hex: "B5C4FE"),
        Color(hex: "5274FF")
    ]
    @Binding var isPresented: Bool
    let friends: [Friend]
    @Binding var selectedFriend: Friend?
    @State private var hint: String = ""
    let categoryId: Int
    
    @EnvironmentObject var userData: UserData
    
    @State private var isShowingAlert = false
    @State private var alertMessage = ""
    @State private var errorMessage = ""
    @State private var sowhat = false
    
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: gradientColors2), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            VStack{
                Spacer()
                Text("하트를 눌러 명지대 대장을 임명해주세요!")
                    .font(.custom("NeoDunggeunmoPro-Regular", size: 25))
                    .foregroundColor(Color.black)
                
                Text("내가 누군지 상대에게 힌트를 줄까요? \n힌트가 필수 요소는 아니에요")
                    .font(.custom("GalmuriMono11", size: 15))
                    .foregroundColor(Color(hex: "626262"))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.black)
                
                ScrollView {
                    VStack(spacing: 9) {
                        ForEach(friends.prefix(30)) { friend in
                            // Rectangle을 VStack 내부로 옮기고, 프로필 이미지와 텍스트를 함께 표시
                            VStack {
                                Rectangle()
                                    .frame(width: 380, height: 95)
                                    .cornerRadius(12)
                                    .overlay(
                                        Rectangle()
                                            .stroke(Color.black, lineWidth: 7)
                                            .frame(width: 380, height: 95)
                                            .background(Color.white)
                                            .cornerRadius(20)
                                    )
                                    .overlay(
                                        HStack {
                                            // 프로필 이미지 표시
                                            if let urlCode = friend.profileImage, let imageURL = URL(string: "https://j-project-2023.s3.ap-northeast-2.amazonaws.com/\(urlCode)") {
                                                AsyncImage(url: imageURL) { phase in
                                                    switch phase {
                                                    case .success(let image):
                                                        image
                                                            .resizable()
                                                            .frame(width: 60, height: 60)
                                                            .aspectRatio(contentMode: .fit)
                                                            .clipShape(Circle())
                                                            .padding(.trailing, 5)
                                                    case .failure(_):
                                                        Image("me.png") // 이미지 로딩 에러 시 기본 이미지 표시
                                                            .resizable()
                                                            .frame(width: 60, height: 60)
                                                            .clipShape(Circle())
                                                            .padding(.trailing, 5)
                                                    case .empty:
                                                        ProgressView()
                                                            .frame(width: 60, height: 60)
                                                            .clipShape(Circle())
                                                            .padding(.trailing, 5)
                                                    }
                                                }
                                            } else {
                                                Image("me.png") // 이미지 URL이 nil일 때 기본 이미지 표시
                                                    .resizable()
                                                    .frame(width: 60, height: 60)
                                                    .clipShape(Circle())
                                                    .padding(.trailing, 5)
                                            }

                                            
                                            Text(friend.name)
                                                .font(.custom("GalmuriMono11", size: 28))
                                                .foregroundColor(Color.black)
                                            
                                            Spacer()
                                            Button(action: {
                                                selectedFriend = friend
                                            }) {
                                                if selectedFriend == friend {
                                                    Image("heart1.png") // 선택되었을 때 이미지
                                                        .resizable()
                                                        .frame(width: 70, height: 70)
                                                        .foregroundColor(.red)
                                                } else {
                                                    Image("Eheart.png") // 선택되지 않았을 때 이미지
                                                        .resizable()
                                                        .frame(width: 75, height: 75)
                                                        .foregroundColor(.gray)
                                                        .padding(.trailing, -3) // heart1 이랑 간격 맞춰야 해서
                                                }
                                            }
                                        }.padding() // HStack 내부 간격 줄어듬
                                    )
                            }
                            .padding(.horizontal, -20) // 좌우 간격을 20 포인트로 설정
                        }
                        
                        HStack {
                            TextField("힌트 작성하기", text: $hint)
                                .font(.custom("NeoDunggeunmoPro-Regular", size: 17))
                            
                            Button(action: {
                                if !containsProfanity(hint) && hint.count <= 15 {
                                    sendHeartToBackend()
                                    isPresented = false
                                } else {
                                    if containsProfanity(hint) {
                                        errorMessage = "해당 내용은 상대에게 불쾌감을 줄 수 있어요!"
                                        hint = ""
                                    } else {
                                        errorMessage = "힌트는 15자 이하여야 합니다."
                                    }
                                    sowhat = true
                                }
                            }) {
                                Text("전송")
                                    .font(.custom("NeoDunggeunmoPro-Regular", size: 25))
                            }
                            .frame(width: 80, height: 38)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding()
                    }
                    .alert(isPresented: $sowhat) {
                        Alert(title: Text("오류"), message: Text(errorMessage), dismissButton: .default(Text("확인")))
                    }
                }
            }
        }
    }
    
    func containsProfanity(_ text: String) -> Bool {
        let profanityList = ["ㅅㅂ", "씨발", "씨바", "개세끼", "18년", "18놈", "18새끼", "ㄱㅐㅅㅐㄲl", "ㄱㅐㅈㅏ", "가슴만져", "가슴빨아", "가슴빨어", "가슴조물락", "가슴주물럭", "가슴쪼물딱","가슴쪼물락", "가슴핧아", "가슴핧어", "강간", "개가튼년", "개가튼뇬", "개같은년", "개걸레", "개고치", "개너미", "개넘", "개년", "개놈", "개늠", "개똥", "개떵", "개떡","개라슥", "개보지", "개부달", "개부랄", "개불랄", "개붕알", "개새", "개세", "개쓰래기", "개쓰레기", "개씁년", "개씁블", "개씁자지", "개씨발", "개씨블", "개자식", "개자지","개잡년", "개젓가튼넘", "개좆", "개지랄", "개후라년", "개후라들놈", "개후라새끼", "걔잡년", "거시기", "걸래년", "걸레같은년", "걸레년", "걸레핀년", "게부럴", "게세끼", "게이","게새끼", "게늠", "게자식", "게지랄놈", "고환", "공지", "공지사항", "귀두", "깨쌔끼", "난자마셔", "난자먹어", "난자핧아", "내꺼빨아", "내꺼핧아", "내버지", "내자지", "내잠지", "내조지", "너거애비", "노옴", "누나강간", "니기미", "니뿡", "니뽕", "니씨브랄", "니아범", "니아비", "니애미", "니애뷔", "니애비", "니할애비", "닝기미", "닌기미", "니미","닳은년", "덜은새끼", "돈새끼", "돌으년", "돌은넘", "돌은새끼", "동생강간", "동성애자", "딸딸이", "똥구녁", "똥꾸뇽", "똥구뇽", "똥", "띠발뇬", "띠팔", "띠펄", "띠풀", "띠벌","띠벨", "띠빌","막간년", "막대쑤셔줘", "막대핧아줘", "맛간년", "맛없는년", "맛이간년", "멜리스", "미친구녕", "미친구멍", "미친넘", "미친년", "미친놈", "미친눔","미친새끼", "미친쇄리", "미친쇠리", "미친쉐이", "미친씨부랄", "미튄", "미티넘", "미틴", "미틴넘", "미틴년", "미틴놈", "미틴것", "백보지", "버따리자지", "버지구녕", "버지구멍","버지냄새", "버지따먹기", "버지뚫어", "버지뜨더", "버지물마셔", "버지벌려", "버지벌료", "버지빨아", "버지빨어", "버지썰어", "버지쑤셔", "버지털", "버지핧아", "버짓물", "버짓물마셔","벌창같은년", "벵신", "병닥", "병딱", "병신", "보쥐", "보지", "보지핧어", "보짓물", "보짓물마셔", "봉알", "부랄", "불알", "붕알", "붜지", "뷩딱", "븅쉰", "븅신", "빙띤","빙신", "빠가십새", "빠가씹새", "빠구리", "빠굴이", "뻑큐", "뽕알", "뽀지", "뼝신", "사까시", "상년", "새꺄", "새뀌", "새끼", "색갸", "색끼", "색스", "색키", "샤발","써글", "써글년", "성교", "성폭행", "세꺄", "세끼", "섹스", "섹스하자", "섹스해", "섹쓰", "섹히", "수셔", "쑤셔", "쉐끼", "쉑갸", "쉑쓰", "쉬발", "쉬방", "쉬밸년", "쉬벌","쉬불", "쉬붕", "쉬빨", "쉬이발", "쉬이방", "쉬이벌", "쉬이불", "쉬이붕", "쉬이빨", "쉬이팔", "쉬이펄", "쉬이풀", "쉬팔", "쉬펄", "쉬풀", "쉽쌔", "시댕이", "시발", "시발년","시발놈", "시발새끼", "시방새", "시밸", "시벌", "시불", "시붕", "시이발", "시이벌", "시이불", "시이붕", "시이팔", "시이펄", "시이풀", "시팍새끼", "시팔", "시팔넘", "시팔년","시팔놈", "시팔새끼", "시펄", "실프", "십8", "십때끼", "십떼끼", "십버지", "십부랄", "십부럴", "십새", "십세이", "십셰리", "십쉐", "십자석", "십자슥", "십지랄", "십창녀", "십창", "십탱", "십탱구리", "십탱굴이", "십팔새끼", "ㅆㅂ", "ㅆㅂㄹㅁ", "ㅆㅂㄻ", "ㅆㅣ", "쌍넘", "쌍년", "쌍놈", "쌍눔", "쌍보지", "쌔끼", "쌔리", "쌕스", "쌕쓰", "썅년", "썅놈", "썅뇬", "썅늠", "쓉새", "쓰바새끼", "쓰브랄쉽세", "씌발", "씌팔", "씨가랭넘", "씨가랭년", "씨가랭놈", "씨발", "씨발년", "씨발롬", "씨발병신", "씨방새", "씨방세", "씨밸", "씨뱅가리", "씨벌", "씨벌년", "씨벌쉐이", "씨부랄", "씨부럴", "씨불", "씨불알", "씨붕", "씨브럴", "씨블", "씨블년", "씨븡새끼", "씨빨", "씨이발", "씨이벌", "씨이불", "씨이붕", "씨이팔", "씨파넘", "씨팍새끼", "씨팍세끼", "씨팔", "씨펄", "씨퐁넘", "씨퐁뇬", "씨퐁보지", "씨퐁자지", "씹년", "씹물", "씹미랄", "씹버지", "씹보지", "씹부랄", "씹브랄", "씹빵구", "씹뽀지", "씹새", "씹새끼", "씹세", "씹쌔끼", "씹자석", "씹자슥", "씹자지", "씹지랄", "씹창", "씹창녀", "씹탱", "씹탱굴이", "씹탱이", "씹팔", "아가리", "애무", "애미", "애미랄", "애미보지", "애미씨뱅", "애미자지", "애미잡년", "애미좃물","애비", "애자", "양아치", "어미강간", "어미따먹자", "어미쑤시자", "영자", "엄창", "에미", "에비", "엔플레버", "엠플레버", "염병", "염병할", "염뵹", "엿먹어라", "오랄","오르가즘", "왕버지", "왕자지", "왕잠지", "왕털버지", "왕털보지", "왕털자지", "왕털잠지", "우미쑤셔", "운디네", "운영자", "유두", "유두빨어", "유두핧어", "유방", "유방만져","유방빨아", "유방주물럭", "유방쪼물딱", "유방쪼물럭", "유방핧아", "유방핧어", "육갑", "이그니스", "이년", "이프리트", "자기핧아", "자지", "자지구녕", "자지구멍", "자지꽂아","자지넣자", "자지뜨더", "자지뜯어", "자지박어", "자지빨아", "자지빨아줘", "자지빨어", "자지쑤셔", "자지쓰레기", "자지정개", "자지짤라", "자지털", "자지핧아", "자지핧아줘","자지핧어", "작은보지", "잠지", "잠지뚫어", "잠지물마셔", "잠지털", "잠짓물마셔", "잡년", "잡놈", "저년", "점물", "젓가튼", "젓가튼쉐이", "젓같내", "젓같은", "젓까", "젓나","젓냄새", "젓대가리", "젓떠", "젓마무리", "젓만이", "젓물", "젓물냄새", "젓밥", "정액마셔", "정액먹어", "정액발사", "정액짜", "정액핧아", "정자마셔", "정자먹어", "정자핧아","젖같은", "젖까", "젖밥", "젖탱이", "조개넓은년", "조개따조", "조개마셔줘", "조개벌려조", "조개속물", "조개쑤셔줘", "조개핧아줘", "조까", "조또", "족같내", "족까", "족까내","존나", "존나게", "존니", "졸라", "좀마니", "좀물", "좀쓰레기", "좁빠라라", "좃가튼뇬", "좃간년", "좃까", "좃까리", "좃깟네", "좃냄새", "좃넘", "좃대가리", "좃도", "좃또","좃만아", "좃만이", "좃만한것", "좃만한쉐이", "좃물", "좃물냄새", "좃보지", "좃부랄", "좃빠구리", "좃빠네", "좃빠라라", "좃털", "좆같은놈", "좆같은새끼", "좆까", "좆까라","좆나", "좆년", "좆도", "좆만아", "좆만한년", "좆만한놈", "좆만한새끼", "좆먹어", "좆물", "좆밥", "좆빨아", "좆새끼", "좆털", "좋만한것", "주글년", "주길년", "쥐랄", "지랄","지랼", "지럴", "지뢀", "쪼까튼", "쪼다", "쪼다새끼", "찌랄", "찌질이", "창남", "창녀", "창녀버지", "창년", "처먹고", "처먹을", "쳐먹고", "쳐쑤셔박어", "촌씨브라리","촌씨브랑이", "촌씨브랭이", "크리토리스", "큰보지", "클리토리스", "트랜스젠더", "페니스", "항문수셔", "항문쑤셔", "허덥", "허버리년", "허벌년", "허벌보지", "허벌자식", "허벌자지","허접", "허젚", "허졉", "허좁", "헐렁보지", "혀로보지핧기", "호냥년", "호로", "호로새끼", "호로자슥", "호로자식", "호로짜식", "호루자슥", "호모", "호졉", "호좁", "후라덜넘","후장", "후장꽂아", "후장뚫어", "흐접", "흐젚", "흐졉", "bitch", "fuck", "fuckyou", "nflavor", "penis", "pennis", "pussy", "sex", "sibal"]
        
        for profanity in profanityList {
            if text.localizedCaseInsensitiveContains(profanity) {
                return true
            }
        }
        
        return false
    }
    
    //MARK: - 팝업 띄우는 함수
    func displayPopup(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        
        if let viewController = UIApplication.shared.windows.first?.rootViewController {
            viewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    
    //MARK: - 투표 보내기 API
    func sendHeartToBackend() {
        guard let selectedFriend = selectedFriend else {
            return
        }
        
        guard let giveId = userData.userId else {
            return
        }
        let takeId: Int64 = Int64(selectedFriend.id) // 선택한 친구의 ID를 가져옴
        let parameters: [String: Any] = [
            "giveId": giveId,
            "takeId": takeId, // 선택한 친구의 ID를 보냅니다.
            "categoryId": categoryId,
            "hint": hint,
        ]
        
        let url = "https://real.najoa.net/joa/votes"
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default)
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
                            displayPopup(title: "투표완료!", message: "친구에게 명지대 대장을 임명해줬어요!")
                        } else {
                            // 서버에서 에러 코드 확인
                            if let data = response.data,
                               let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                               let code = json["code"] as? String {
                                switch code {
                                    case "M001":
                                        displayPopup(title: "회원정보가 존재하지 않습니다!", message: "지속적인 문제 발생 시 고객센터로 문의해주세요.")
                                    case "V003":
                                        displayPopup(title: "이미 투표를 완료했습니다!", message: "다른 친구에게도 명지대 대장을 임명해주세요!")
                                    case "V002":
                                        displayPopup(title: "이용불가!", message: "투표 카테고리 선택 후 다시 시도해주세요!")
                                    case "M014":
                                        displayPopup(title: "계정이 영구정지 상태입니다!", message: "회원님은 영구정지 대상으로 JoA 이용이 불가능합니다.")
                                    case "M004":
                                        displayPopup(title: "계정이 일시정지 상태입니다!", message: "회원님은 영구정지 대상으로 JoA 이용이 일시적으로 불가능합니다.")
                                    case "V004":
                                        displayPopup(title: "투표 불가!", message: "사용자에게 하트를 전송할 수 없습니다! \n 지속적인 문제 발생 시 관리자에게 문의해주세요.")
                                    case "B001":
                                        self.displayPopup(title: "투표 불가!", message: "현재 해당 사용자에게 하트를 전송할 수 없습니다! 다른 친구에게 투표를 전송해주세요!")
                                    default:
                                        displayPopup(title: "에러", message: "서버에서 유효한 응답을 받지 못했습니다. \n 관리자에게 문의하세요.")
                                }
                            } else {
                                displayPopup(title: "에러", message: "서버에서 유효한 응답을 받지 못했습니다. \n 관리자에게 문의하세요.")
                            }
                        }
                    }
                case .failure(let error):
                    print("요청 실패: \(error)")
                    // 요청 실패시 에러 처리를 이곳에 추가합니다.
                    displayPopup(title: "알림", message: "서버에서 유효한 응답을 받지 못했습니다. \n 관리자에게 문의하세요.")
                }
            }
    }
}

//MARK: - 투표 항목 표시 View
struct GameView: View {
    @State private var votingItems: [VotingItem] = []
    @State private var selectedCategoryId: Int?
    @State private var showFriendSelectionSheet: Bool = false
    @State private var selectedFriend: Friend? = nil
    @State private var voteItems: [String] = [] // 투표 목록을 @State로 선언
    
    @State private var name: String = ""
    @State private var imageURL: UIImage? // 이미지의 URL을 저장할 변수
    
    @State private var userImage: UIImage? = nil
    @EnvironmentObject var userData: UserData
    @ObservedObject var locationManager: LocationManager // Declare the locationManager property
    
    // Initialize locationManager with the userData object
    init(userData: UserData) {
        self.locationManager = LocationManager(userData: userData)
    }
    
    @State private var friends: [Friend] = [] // @State로 변경
    @State private var showToast = false
    
    struct ResponseModel: Decodable {
        let status: Bool
        let data: ResponseData?
        let code: String?
        
        struct ResponseData: Decodable {
            let isContained: Bool?
        }
    }
    
    let gradientColors:[Color] = [
        Color(hex: "FFFFFF"),
        Color(hex: "77EFFF"),
        Color(hex: "CBF9FF"),
        Color(hex: "FFFFFF")
    ]
    
    func getRandomVotingItems() -> [VotingItem] {
        let fullList = [
            VotingItem(id: 1, title: "🍚\n선배님 밥 사주세요!", color: Color(hex: "FFDADA")),
            VotingItem(id: 2, title: "💪🏻\n혹시 3대 500?" ,color: Color(hex: "FF0099")),
            VotingItem(id: 3, title: "🛍️\n패피는 바로 너", color: Color(hex: "FAFFDA")),
            VotingItem(id: 4, title: "🎮\n페이커 뺨 칠 거 같음", color: Color(hex: "2F42E5")),
            VotingItem(id: 5, title: "🍻\n친해지고 싶어요", color: Color(hex: "A853FC")),
            VotingItem(id: 6, title: "💯\n과탑일 거 같아요", color: Color(hex: "F19CFF")),
            VotingItem(id: 7, title: "📚\n팀플 같이 하고 싶어요", color: Color(hex: "F8E893")),
            VotingItem(id: 8, title: "🏫\n끝나고 뭐하는지 궁금해요", color: Color(hex: "BDBDBD")),
            VotingItem(id: 9, title: "🫶🏻\n존잘/존예이십미다", color: Color(hex: "DD999D")),
        ]
        return Array(fullList.shuffled().prefix(4)) //랜덤 돌리기
    }
    
    var body: some View {
        NavigationView {
            ZStack{
                LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                VStack {
                    HStack { //헤더 시작
                        Image("main")
                            .resizable()
                            .frame(width: 60, height: 60)
                        VStack {
                            Text("명지대 ~ 대장을 찾아라")
                                .font(.custom("NeoDunggeunmoPro-Regular", size: 31))
                            
                            Text("아래 목록에 가장 적합한 친구를 뽑아 투표해주세요!")
                                .font(.custom("Galmuri14", size: 10))
                            
                            Text("투표는 익명으로 진행되니 안심하고 ㄱㄱ")
                                .font(.custom("Galmuri14", size: 10))
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                        }
                    }
                    HStack {
                        if let image = userImage {
                            // 사용자의 프로필 이미지가 있을 경우 표시
                            Image(uiImage: image)
                                .resizable()
                                .frame(width: 55, height: 55)
                                .aspectRatio(contentMode: .fit)
                                .clipShape(Circle())
                        } else {
                            // 사용자의 프로필 이미지가 없을 경우 기본 이미지 표시
                            Image("my.png")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 55, height: 55)
                                .clipShape(Circle())
                        }
                        Text(name)
                            .font(.custom("GalmuriMono11", size: 27))
                        
                        // VotelistView에 @Binding으로 투표 목록 전달 (내가 받은 투표 목록 확인)
                        NavigationLink(destination: VotelistView(voteItems: $voteItems)) {
                            Text("📥")
                                .font(.largeTitle)
                        }
                        Button(action: {
                            // 사용자 위치 업데이트 요청
                            if let userLocation = locationManager.userLocation {
                                if let userId = userData.userId {
                                    updateLocation(id: userId, latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude, altitude: userLocation.altitude)
                                }}
                        }) {
                            Text("내 위치 업데이트")
                                .font(.custom("Galmuri14", size: 12))
                                .foregroundColor(.black)
                                .padding()
                                .background(Color(hex: "D9D9D9"))
                                .cornerRadius(10)
                        }
                    }
                    
                    Button(action: {
                        showToast = true
                        
                    }) {
                        Image(systemName: "star.bubble")
                            .foregroundColor(Color.black)
                        Text("투표하기 전 확인하기")
                            .font(.custom("Galmuri14", size: 15))
                            .foregroundColor(.black)
                    }
                    .alert(isPresented: $showToast) {
                        Alert(
                            title: Text("⚠️ 주 의 사 항 ⚠️"),
                            message: Text("친구에게 부적절한 힌트를 보내면 \n JoA 운영체제에 의해 계정정지 혹은 영구정지 조치가 취해져요!\n 도넘은 힌트를 작성해서 친구에게 보내는 행동은 지양해주세요. \n 과제에 지친 일상이 JoA 덕분에 행복해졌으면 좋겠어요! 클린한 JoA를 같이 만들어가요🫶🏻!"),
                            dismissButton: .default(Text("넹 면!"))
                        )
                    }
                    .padding(.bottom, 10)
                    
                    VStack {
                        ForEach(0..<2) { rowIndex in
                            HStack {
                                ForEach(0..<2) { colIndex in
                                    let index = rowIndex * 2 + colIndex
                                    if index < votingItems.count {
                                        let item = votingItems[index]
                                        Button(action: {
                                            selectedCategoryId = Int(item.id)
                                            selectedFriend = item.selectedFriend // Set the selected friend for the voting item
                                        }) {
                                            ZStack(alignment: .center) {
                                                Rectangle()
                                                    .frame(width: 180, height: 180)
                                                    .cornerRadius(20) // 모서리 둥글기 설정
                                                    .foregroundColor(selectedCategoryId == Int(item.id) ? item.color : Color.gray.opacity(0.5))
                                                
                                                Text(item.title)
                                                    .font(.custom("NeoDunggeunmoPro-Regular", size: 25))
                                                    .foregroundColor(.black)
                                                    .multilineTextAlignment(.center)
                                                    .frame(width: 100, height: 100, alignment: .center)
                                            }
                                        }
                                        .padding(.horizontal, 2) // 좌우 간격 추가
                                    } else {
                                        Rectangle()
                                            .frame(width: 180, height: 180)
                                            .cornerRadius(20) // 모서리 둥글기 설정
                                            .hidden()
                                    }
                                }
                            }
                            Spacer()
                                .frame(height: 20) // 수직 간격 조절
                        }
                        if let selectedCategoryId = selectedCategoryId {
                            Button(action: {
                                // Show friend selection sheet
                                showFriendSelectionSheet = true
                            }) {
                                Text("친구 선택하기")
                                    .font(.custom("NeoDunggeunmoPro-Regular", size: 20))
                            }
                            .padding()
                            .background(Color(hex: "D9D9D9"))
                            .foregroundColor(.black)
                            .cornerRadius(25)
                            .sheet(isPresented: $showFriendSelectionSheet) {
                                FriendSelectionSheet(
                                    isPresented: $showFriendSelectionSheet,
                                    friends: friends,
                                    selectedFriend: $selectedFriend,
                                    categoryId: selectedCategoryId // 선택한 voting item의 categoryId를 FriendSelectionSheet로 전달합니다.
                                ).onAppear {
                                    nearbyfriend() // FriendSelectionSheet 화면이 나타날 때 nearbyfriend 함수 호출
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    votingItems = getRandomVotingItems()
                    //    locationManager
                }
                // .onAppear(perform: getMeprofile)
                .onAppear{
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        nearbyfriend()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            getMeprofile()
                        }
                    }
                    
                }
            }}
        .navigationBarHidden(true)
        //        .onAppear {
        //            // VotelistView에 전달하기 위해 백엔드에서 투표 목록 받아오기
        //            getVoteListForGameView()
        //        }
        .onDisappear {
            selectedFriend = nil
            selectedCategoryId = nil
            showFriendSelectionSheet = false // 화면이 사라질 때 버튼을 숨김
        }
    }
    
    //MARK: 내 위치 업데이트 API
    struct UpdateLocationRequest: Encodable {
        let id: Int64
        let latitude: Double
        let longitude: Double
        let altitude: Double
    }
    
    func updateLocation(id: Int64, latitude: Double, longitude: Double, altitude: Double) {
        let url = "https://real.najoa.net/joa/locations"
        
        let request = UpdateLocationRequest(id: id, latitude: latitude, longitude: longitude, altitude: altitude)
        
        AF.request(url, method: .patch, parameters: request, encoder: JSONParameterEncoder.default)
            .response { response in
                print(" Received Data: \(response)")
                if let statusCode = response.response?.statusCode {
                    if statusCode == 200 {
                        print("버튼 눌렀을 때 위치 업데이트 성공")
                        
                        if let data = response.data {
                            do {
                                let decoder = JSONDecoder()
                                let responseModel = try decoder.decode(ResponseModel.self, from: data)
                                if let isContained = responseModel.data?.isContained {
                                    if isContained {
                                        // 학교 내에 있을 때의 처리
                                        print("사용자가 학교 내에 있습니다!")
                                    } else {
                                        print("사용자가 학교 내에 없습니다!")
                                        self.displayPopup(title: "Where are U?", message: "현재 위치가 학교 안이 아니에요! JoA는 학교 내에서만 이용가능합니다.")
                                    }
                                }
                            } catch {
                                print("에러 발생:", error)
                            }
                        }
                    } else {
                        if let data = response.data {
                            do {
                                let decoder = JSONDecoder()
                                let responseModel = try decoder.decode(ResponseModel.self, from: data)
                                if let errorCode = responseModel.code {
                                    switch errorCode {
                                    case "M001":
                                        print("사용자를 찾을 수 없습니다!")
                                        self.displayPopup(title: "이용불가!", message: "사용자가 존재하지 않습니다! 회원가입 혹은 로그인 해주세요")
                                    case "M014":
                                        print("영구정지된 계정입니다!")
                                        self.displayPopup(title: "이용불가!", message: "회원님은 영구정지 대상으로 JoA 이용이 불가능합니다.")
                                    case "L001":
                                        print("위치 찾을 수 없음!")
                                        self.displayPopup(title: "이용불가!", message: "위치가 확인되지 않아요! 위치 서비스 허용 후 이용해주세요.")
                                    case "M004":
                                        print("일시정지된 계정입니다!")
                                        self.displayPopup(title: "이용불가!", message: "회원님은 일시정지 대상으로 JoA 이용이 일시적으로 불가능합니다.")
                                    case "P001":
                                        print("학교 정보 찾을 수 없음!")
                                        self.displayPopup(title: "학교 정보 찾을 수 없음", message: "추후 다시 이용해주세요!")
                                        
                                    default:
                                        print("알 수 없는 오류 발생")
                                    }
                                }
                            } catch {
                                print("에러 발생:", error)
                            }
                        }
                    }
                }
            }
    }
    
    //MARK: - 팝업 띄우는 함수
    func displayPopup(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        
        if let viewController = UIApplication.shared.windows.first?.rootViewController {
            viewController.present(alertController, animated: true, completion: nil)
        }
    }
    
    
    //MARK: 주변 친구 찾기 API
    func nearbyfriend() {
        guard let userLocation = locationManager.userLocation,
              let userId = userData.userId else {
            displayPopup(title: "주변 친구 없음", message: "주변에 친구가 없어요!")
            return
        }
//        let dummyData = [
//            Friend(id: 39, name: "최종현", profileImage: "me.png", bio: "나 야 나"), //loginId66
//            Friend(id: 2, name: "한요한", profileImage: "me.png", bio: "나 4월에 앨범 나온다"), //77
//            Friend(id: 43, name: "홍향미" , profileImage: "me.png", bio: "과탑 나야나"), //1010
//            Friend(id: 5, name: "석매튜" , profileImage: "me.png", bio: "") ,//1010
//            Friend(id: 10, name: "서쟈니", profileImage: "me.png", bio: ""), // 99
//           ]
//        
//        // 더미 데이터를 friends 배열에 할당
//        self.friends = dummyData
        
        let latitude: Double = userLocation.coordinate.latitude
        let longitude: Double = userLocation.coordinate.longitude
        let altitude: Double = userLocation.altitude
        
        let parameters: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "altitude": altitude
        ]
        
        AF.request("https://real.najoa.net/joa/locations/\(userId)", method: .get, parameters: parameters)
            .validate()
            .responseDecodable(of: ApiResponse.self) { response in
                switch response.result {
                case .success(let apiResponse):
                    print("Request: \(response.request)")
                    print("Response: \(response.response)")
                    print("Data: \(response.data)")
                    print("Error: \(response.error)")
                    print("주변 사람 목록 Received Data: \(apiResponse)")
                    
                    if let nearByList = apiResponse.data?.nearByList, !nearByList.isEmpty {
                        var fetchedFriends: [Friend] = []
                        for nearbyInfo in nearByList {
                            var profileImage: String?
                            if let urlCode = nearbyInfo.urlCode {
                                profileImage = "https://j-project-2023.s3.ap-northeast-2.amazonaws.com/\(urlCode)"
                                print("profileImage \(profileImage)")
                            }
                            let friend = Friend(id: nearbyInfo.id, name: nearbyInfo.name, profileImage: nearbyInfo.urlCode, bio: nearbyInfo.bio)
                            fetchedFriends.append(friend)
                        }
                        // Assign the fetched friends to the friends array
                        self.friends = fetchedFriends
                    } else {
                        displayPopup(title: "주변 친구 없음", message: "주주변에 JoA를 사용하고 있는 친구가 없습니다.")
                        print("주변 사람이 없습니다.")
                    }
                    
                    if !apiResponse.status {
                        // Handle failure responses
                        if let errorCode = apiResponse.code {
                            switch errorCode {
                            case "M001":
                                showAlert(title: "사용자 정보 없음", message: "사용자가 존재하지 않습니다! 회원가입 혹은 로그인 해주세요.")
                            case "M014":
                                showAlert(title: "이용불가!", message: "회원님은 영구정지 대상으로 JoA 이용이 불가능합니다.")
                            case "M004":
                                showAlert(title: "이용불가!", message: "회원님은 일시정지 대상으로 JoA 이용이 일시적으로 불가능합니다.")
                            default:
                                break
                            }
                        }
                    }
                    
                case .failure(let error):
                    print("API request failed with error: \(error)")
                }
            }
    }

    // Function to display alert
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
        if let viewController = UIApplication.shared.windows.first?.rootViewController {
            viewController.present(alertController, animated: true, completion: nil)
        }
    }

    
    func getMeprofile() {
         if let userId = userData.userId {
             let apiUrl = "http://real.najoa.net/joa/member-profiles/\(userId)/vote-page"
             
             AF.request(apiUrl, method: .get ).responseJSON { response in
                 print("Request: \(response.request)")
                 print("Response: \(response.response)")
                 print("Data: \(response.data)")
                 print("Error: \(response.error)")
                 
                 switch response.result {
                 case .success(let data):
                     if let userData = data as? [String: Any] {
                         if let status = userData["status"] as? Bool, status {
                             // Success response
                             if let userData = userData["data"] as? [String: Any] {
                                 if let userName = userData["name"] as? String {
                                     self.name = userName
                                 }
                                 if let urlCode = userData["urlCode"] as? String {
                                     let imageUrlString = "https://j-project-2023.s3.ap-northeast-2.amazonaws.com/\(urlCode)"
                                     if let imageURL = URL(string: imageUrlString) {
                                         let request = URLRequest(url: imageURL)
                                         URLSession.shared.dataTask(with: request) { data, response, error in
                                             if let data = data, let image = UIImage(data: data) {
                                                 DispatchQueue.main.async {
                                                     // 사용자의 프로필 이미지를 가져와서 저장
                                                     self.userImage = image
                                                 }
                                             } else {
                                                 // Handle image loading error
                                                 print("Image loading error: \(error?.localizedDescription ?? "Unknown error")")
                                                 // 오류가 발생하면 기본 이미지를 설정
                                                 self.userImage = UIImage(named: "my.png")
                                             }
                                         }.resume()
                                     } else {
                                         self.userImage = UIImage(named: "my.png")
                                     }
                                 } else {
                                     // Handle the case when no image URL is provided
                                     self.userImage = UIImage(named: "my.png")
                                 }
                             }
                         } else {
                             // Failure response
                             if let code = userData["code"] as? String {
                                 switch code {
                                 case "M001":
                                     self.displayPopup(title: "이용불가!", message: "사용자가 존재하지 않습니다! 회원가입 혹은 로그인 해주세요")
                                 case "M014":
                                     self.displayPopup(title: "이용불가!", message: "회원님은 영구정지 대상으로 JoA 이용이 불가능합니다.")
                                 case "M004":
                                     displayPopup(title: "이용불가!", message: "회원님은 일시정지 대상으로 JoA 이용이 일시적으로 불가능합니다.")
                                 default:
                                     print("Unhandled error code: \(code)")
                                 }
                             }
                         }
                     }
                 case .failure(let error):
                     print("Error: \(error)")
                 }
             }
         }
     }
    
//    func getVoteListForGameView() {
//        if let takeId = userData.userId {
//            let parameters: [String: Any] = ["takeId": takeId]
//            AF.request("http://real.najoa.net/vote/get", method: .get, parameters: parameters)
//                .validate()
//                .responseJSON { response in
//                    switch response.result {
//                    case .success(let value):
//                        // API 성공적으로 호출된 경우
//                        if let status = response.response?.statusCode {
//                            print("API 호출 성공 - Status: \(status), Response: \(value)")
//                            
//                            if let json = value as? [String: Any], let status = json["status"] as? Bool {
//                                if status {
//                                    // 정상적인 응답 받은 경우
//                                    if let data = json["data"] as? [String: Any], let voteList = data["voteList"] as? [[String: Any]] {
//                                        // 투표 목록 업데이트
//                                        DispatchQueue.main.async {
//                                            self.voteItems = voteList.compactMap { $0["voteItems"] as? String }
//                                        }
//                                    }
//                                } else {
//                                    // 실패 응답인 경우
//                                    if let code = json["code"] as? String {
//                                        switch code {
//                                        case "M001":
//                                            // "회원 정보를 찾을 수 없습니다!" 팝업 표시
//                                            print("회원 정보를 찾을 수 없습니다!")
//                                            // Show popup for "회원 정보를 찾을 수 없습니다!"
//                                        case "M014":
//                                            // "회원님은 영구정지된 상태입니다" 팝업 표시
//                                            print("회원님은 영구정지된 상태입니다!")
//                                            // Show popup for "회원님은 영구정지된 상태입니다!"
//                                        case "M004":
//                                            // "회원님은 영구정지된 상태입니다" 팝업 표시
//                                            print("회원님은 일시정지된 상태입니다!")
//                                        default:
//                                            print("Unhandled error code: \(code)")
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                    case .failure(let error):
//                        print("API 호출 실패: \(error)")
//                    }
//                }
//        }
//    }
}

//struct GameView_Previews: PreviewProvider {
//    static var previews: some View {
//        let userData = UserData()
//        return GameView(userData: userData)
//            .environmentObject(userData)
//            .onAppear {
//                userData.userId = 8809673586
//            }
//    }
//}
