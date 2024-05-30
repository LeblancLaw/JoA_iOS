import SwiftUI
import Alamofire
import SDWebImageSwiftUI

import Foundation

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
       @Environment(\.presentationMode) private var presentationMode

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = context.coordinator
        imagePicker.sourceType = .photoLibrary // 갤러리에서 사진 선택
        return imagePicker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let selectedImage = info[.originalImage] as? UIImage {
                parent.selectedImage = selectedImage
                // 이미지 선택이 완료되면 NotificationCenter로 선택된 이미지를 알립니다.
                NotificationCenter.default.post(name: .selectedImageChanged, object: nil)
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
extension Notification.Name {
    static let selectedImageChanged = Notification.Name("SelectedImageChanged")
}

struct Mypage2: View {
    @StateObject private var viewModel = MyPageviewModel()
    @State private var showActionSheet = false
    @State private var showBioActionSheet = false
    @State private var showBioEditor: Bool = false
    
    //세션 id 저장
    @EnvironmentObject var userData: UserData
    
    let colors: [Color] = [Color(hex: "FFFFFF"), Color(hex: "77EFFF"), Color(hex: "FFFFFF")] // 순위별 색상 배열
    
    var body: some View {
        let gradientColors: [Color] = [
            Color(hex: "FFFFFF"),
            Color(hex: "77EFFF"),
            Color(hex: "CBF9FF"),
            Color(hex: "FFFFFF")
        ]
        
        return ZStack {
            LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            VStack() {
                HStack {
                    Spacer()
                    Image("main")
                        .resizable()
                        .frame(width: 60, height: 60)
                    
                    Text("나는 명지대 대장이다 ! !")
                        .font(.custom("NeoDunggeunmoPro-Regular", size: 30))
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding(.bottom, 5)
                HStack {
                    Image("heart2.png")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 45, height: 45)
                    
                    Text("TODAY \(viewModel.todayHeart)")
                        .font(.custom("Galmuri11", size: 22))
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.gray)
                    
                    Image("heart2.png")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 45, height: 45)
                    
                    Text("TOTAL \(viewModel.totalHeart)")
                        .font(.custom("Galmuri11", size: 22))
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.gray)
                }
                Button(action: {
                    // 이미지 피커를 표시
                    viewModel.showActionSheet = true
                }) {
                    // 이미지 표시
                    if let urlCode = viewModel.urlCode {
                        AsyncImage(url: URL(string: "https://j-project-2023.s3.ap-northeast-2.amazonaws.com/\(urlCode)")) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 200, height: 200)
                                    .clipShape(Circle())
                            case .failure:
                                Image("my.png")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 200, height: 200)
                                    .clipShape(Circle())
                            default:
                                ProgressView()
                            }
                        }
                    } else {
                        Image("my.png")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 200, height: 200)
                            .clipShape(Circle())
                    }
                }.padding(.bottom, 10)
                    .actionSheet(isPresented: $viewModel.showActionSheet) {
                    ActionSheet(title: Text("프로필 사진 변경"), buttons: [
                        .default(Text("프로필 사진 변경"), action: {
                            // 프로필 사진 변경 함수 호출
                            viewModel.isImagePickerPresented = true
                        }),
                        .destructive(Text("프로필 사진 삭제"), action: {
                            // 프로필 사진 삭제 함수 호출
                            viewModel.deleteProfilePicture(userData: userData)
                        }),
                        .cancel()
                    ])
                }.sheet(isPresented: $viewModel.isImagePickerPresented) {
                    ImagePicker(selectedImage: $viewModel.selectedImage) // 갤러리에서 이미지 선택할 수 있는 화면 표시
                }
                .onReceive(NotificationCenter.default.publisher(for: .selectedImageChanged)) { _ in
                    if let image = viewModel.selectedImage {
                        // 이미지가 선택되었을 때 API 호출
                        viewModel.uploadProfilePicture(image: image, userData: userData)
                    }
                }
                Text(viewModel.name)
                    .font(.custom("Galmuri11", size: 22))
                    .bold()
                    .padding(.bottom, 8)
                
                Button(action: {
                    if let existingBio = viewModel.bio, !existingBio.isEmpty {
                        // If bio exists, show it as a button
                        viewModel.showBioActionSheet = true
                    } else {
                        // If bio doesn't exist, show the action sheet
                        viewModel.showBioActionSheet = true
                    }
                }) {
                    if let existingBio = viewModel.bio, !existingBio.isEmpty {
                        // If bio exists, show it as a button
                        Text(existingBio)
                            .font(.custom("GalmuriMono11", size: 19))
                            .foregroundColor(Color.black)
                    } else {
                        // If bio doesn't exist, show the default text
                        Text("한 줄 소개 변경하기")
                            .font(.custom("GalmuriMono11", size: 19))
                            .foregroundColor(Color.black)
                    }
                }.padding(.bottom, 10)
                .onTapGesture {
                    if let existingBio = viewModel.bio, !existingBio.isEmpty {
                        // If bio exists, show it as a button
                        viewModel.showBioActionSheet = true
                    }
                }
                .actionSheet(isPresented: $viewModel.showBioActionSheet) {
                    ActionSheet(title: Text("한 줄 소개 관리"), buttons: [
                        .default(Text("한 줄 소개 변경")) {
                            showBioEditor = true
                        },
                        .destructive(Text("한 줄 소개 삭제")) {
                            viewModel.deleteIntroductionFromBackend(userData: userData)
                        },
                        .cancel()
                    ])
                }
                .sheet(isPresented: $showBioEditor) {
                    // Bio editor view
                    BioEditorView(
                        newBio: $viewModel.newBio,
                        onSave: {
                            viewModel.saveIntroductionToBackend(introduction: viewModel.newBio, userData: userData)
                            showBioEditor = false
                        },
                        onDisappearAction: {
                            viewModel.getUserMypage(userData: userData)
                        }
                    )
                }
                
                Text("💡\(viewModel.name ?? "")님의 명지대 티어 탑쓰리")
                    .font(.custom("Galmuri11", size: 19))
                    .multilineTextAlignment(.center)
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(0..<(viewModel.voteTop3.count / 3 + (viewModel.voteTop3.count % 3 == 0 ? 0 : 1)), id: \.self) { rowIndex in
                        VStack(spacing: 10) {
                            ForEach(0..<3, id: \.self) { columnIndex in
                                let index = rowIndex * 3 + columnIndex
                                if index < viewModel.voteTop3.count {
                                    Capsule()
                                        .frame(width: 350, height: 40)
                                        .foregroundColor(Color.clear)
                                        .overlay(
                                            Text(viewModel.voteTop3[index])
                                                .font(.custom("GalmuriMono11", size: 15))
                                                .foregroundColor(Color.black)
                                                .multilineTextAlignment(.center)
                                        )
                                        .background(
                                            LinearGradient(gradient: Gradient(colors: [Color.white, Color.purple]), startPoint: .top, endPoint: .bottom)
                                        )
                                        .clipShape(Capsule())
                                } else {
                                    Capsule()
                                        .frame(width: 350, height: 40)
                                        .foregroundColor(Color.clear)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 10)
            }
            .padding(.bottom, 20)
            .onAppear {
                viewModel.getUserMypage(userData: userData)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Text(""))
        }
    }
    
    struct BioEditorView: View {
        @Binding var newBio: String
        var onSave: () -> Void
        var onDisappearAction: () -> Void
        @State private var showBioErrorPopup: Bool = false // 15자 초과시 팝업 띄우기
        @State private var showInappropriateContentPopup: Bool = false

        
        let colors: [Color] = [Color(hex: "FFFFFF"), Color(hex: "77EFFF"), Color(hex: "FFFFFF")] // 순위별 색상 배열
        
        var body: some View {
            let gradientColors: [Color] = [
                Color(hex: "FFFFFF"),
                Color(hex: "77EFFF"),
                Color(hex: "CBF9FF"),
                Color(hex: "FFFFFF")
            ]
            return ZStack {
                LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text("한 줄 소개 작성하기 (15자 이내)")
                        .font(.custom("Galmuri14", size: 15))
                        .foregroundColor(.black)
                    
                    TextField("", text: $newBio)
                        .padding(10)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white))
                        .padding(.horizontal, 20)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 5)
                        .onChange(of: newBio) { newValue in
                            // Check if the length of the newBio is greater than 15
                            if newValue.count > 15 {
                                // Show the error popup
                                showBioErrorPopup = true
                            } else {
                                let inappropriateWords = ["ㅅㅂ", "씨발", "씨바", "개세끼", "18년", "18놈", "18새끼", "ㄱㅐㅅㅐㄲl", "ㄱㅐㅈㅏ", "가슴만져", "가슴빨아", "가슴빨어", "가슴조물락", "가슴주물럭", "가슴쪼물딱","가슴쪼물락", "가슴핧아", "가슴핧어", "강간", "개가튼년", "개가튼뇬", "개같은년", "개걸레", "개고치", "개너미", "개넘", "개년", "개놈", "개늠", "개똥", "개떵", "개떡","개라슥", "개보지", "개부달", "개부랄", "개불랄", "개붕알", "개새", "개세", "개쓰래기", "개쓰레기", "개씁년", "개씁블", "개씁자지", "개씨발", "개씨블", "개자식", "개자지","개잡년", "개젓가튼넘", "개좆", "개지랄", "개후라년", "개후라들놈", "개후라새끼", "걔잡년", "거시기", "걸래년", "걸레같은년", "걸레년", "걸레핀년", "게부럴", "게세끼", "게이","게새끼", "게늠", "게자식", "게지랄놈", "고환", "공지", "공지사항", "귀두", "깨쌔끼", "난자마셔", "난자먹어", "난자핧아", "내꺼빨아", "내꺼핧아", "내버지", "내자지", "내잠지", "내조지", "너거애비", "노옴", "누나강간", "니기미", "니뿡", "니뽕", "니씨브랄", "니아범", "니아비", "니애미", "니애뷔", "니애비", "니할애비", "닝기미", "닌기미", "니미","닳은년", "덜은새끼", "돈새끼", "돌으년", "돌은넘", "돌은새끼", "동생강간", "동성애자", "딸딸이", "똥구녁", "똥꾸뇽", "똥구뇽", "똥", "띠발뇬", "띠팔", "띠펄", "띠풀", "띠벌","띠벨", "띠빌","막간년", "막대쑤셔줘", "막대핧아줘", "맛간년", "맛없는년", "맛이간년", "멜리스", "미친구녕", "미친구멍", "미친넘", "미친년", "미친놈", "미친눔","미친새끼", "미친쇄리", "미친쇠리", "미친쉐이", "미친씨부랄", "미튄", "미티넘", "미틴", "미틴넘", "미틴년", "미틴놈", "미틴것", "백보지", "버따리자지", "버지구녕", "버지구멍","버지냄새", "버지따먹기", "버지뚫어", "버지뜨더", "버지물마셔", "버지벌려", "버지벌료", "버지빨아", "버지빨어", "버지썰어", "버지쑤셔", "버지털", "버지핧아", "버짓물", "버짓물마셔","벌창같은년", "벵신", "병닥", "병딱", "병신", "보쥐", "보지", "보지핧어", "보짓물", "보짓물마셔", "봉알", "부랄", "불알", "붕알", "붜지", "뷩딱", "븅쉰", "븅신", "빙띤","빙신", "빠가십새", "빠가씹새", "빠구리", "빠굴이", "뻑큐", "뽕알", "뽀지", "뼝신", "사까시", "상년", "새꺄", "새뀌", "새끼", "색갸", "색끼", "색스", "색키", "샤발","써글", "써글년", "성교", "성폭행", "세꺄", "세끼", "섹스", "섹스하자", "섹스해", "섹쓰", "섹히", "수셔", "쑤셔", "쉐끼", "쉑갸", "쉑쓰", "쉬발", "쉬방", "쉬밸년", "쉬벌","쉬불", "쉬붕", "쉬빨", "쉬이발", "쉬이방", "쉬이벌", "쉬이불", "쉬이붕", "쉬이빨", "쉬이팔", "쉬이펄", "쉬이풀", "쉬팔", "쉬펄", "쉬풀", "쉽쌔", "시댕이", "시발", "시발년","시발놈", "시발새끼", "시방새", "시밸", "시벌", "시불", "시붕", "시이발", "시이벌", "시이불", "시이붕", "시이팔", "시이펄", "시이풀", "시팍새끼", "시팔", "시팔넘", "시팔년","시팔놈", "시팔새끼", "시펄", "실프", "십8", "십때끼", "십떼끼", "십버지", "십부랄", "십부럴", "십새", "십세이", "십셰리", "십쉐", "십자석", "십자슥", "십지랄", "십창녀", "십창", "십탱", "십탱구리", "십탱굴이", "십팔새끼", "ㅆㅂ", "ㅆㅂㄹㅁ", "ㅆㅂㄻ", "ㅆㅣ", "쌍넘", "쌍년", "쌍놈", "쌍눔", "쌍보지", "쌔끼", "쌔리", "쌕스", "쌕쓰", "썅년", "썅놈", "썅뇬", "썅늠", "쓉새", "쓰바새끼", "쓰브랄쉽세", "씌발", "씌팔", "씨가랭넘", "씨가랭년", "씨가랭놈", "씨발", "씨발년", "씨발롬", "씨발병신", "씨방새", "씨방세", "씨밸", "씨뱅가리", "씨벌", "씨벌년", "씨벌쉐이", "씨부랄", "씨부럴", "씨불", "씨불알", "씨붕", "씨브럴", "씨블", "씨블년", "씨븡새끼", "씨빨", "씨이발", "씨이벌", "씨이불", "씨이붕", "씨이팔", "씨파넘", "씨팍새끼", "씨팍세끼", "씨팔", "씨펄", "씨퐁넘", "씨퐁뇬", "씨퐁보지", "씨퐁자지", "씹년", "씹물", "씹미랄", "씹버지", "씹보지", "씹부랄", "씹브랄", "씹빵구", "씹뽀지", "씹새", "씹새끼", "씹세", "씹쌔끼", "씹자석", "씹자슥", "씹자지", "씹지랄", "씹창", "씹창녀", "씹탱", "씹탱굴이", "씹탱이", "씹팔", "아가리", "애무", "애미", "애미랄", "애미보지", "애미씨뱅", "애미자지", "애미잡년", "애미좃물","애비", "애자", "양아치", "어미강간", "어미따먹자", "어미쑤시자", "영자", "엄창", "에미", "에비", "엔플레버", "엠플레버", "염병", "염병할", "염뵹", "엿먹어라", "오랄","오르가즘", "왕버지", "왕자지", "왕잠지", "왕털버지", "왕털보지", "왕털자지", "왕털잠지", "우미쑤셔", "운디네", "운영자", "유두", "유두빨어", "유두핧어", "유방", "유방만져","유방빨아", "유방주물럭", "유방쪼물딱", "유방쪼물럭", "유방핧아", "유방핧어", "육갑", "이그니스", "이년", "이프리트", "자기핧아", "자지", "자지구녕", "자지구멍", "자지꽂아","자지넣자", "자지뜨더", "자지뜯어", "자지박어", "자지빨아", "자지빨아줘", "자지빨어", "자지쑤셔", "자지쓰레기", "자지정개", "자지짤라", "자지털", "자지핧아", "자지핧아줘","자지핧어", "작은보지", "잠지", "잠지뚫어", "잠지물마셔", "잠지털", "잠짓물마셔", "잡년", "잡놈", "저년", "점물", "젓가튼", "젓가튼쉐이", "젓같내", "젓같은", "젓까", "젓나","젓냄새", "젓대가리", "젓떠", "젓마무리", "젓만이", "젓물", "젓물냄새", "젓밥", "정액마셔", "정액먹어", "정액발사", "정액짜", "정액핧아", "정자마셔", "정자먹어", "정자핧아","젖같은", "젖까", "젖밥", "젖탱이", "조개넓은년", "조개따조", "조개마셔줘", "조개벌려조", "조개속물", "조개쑤셔줘", "조개핧아줘", "조까", "조또", "족같내", "족까", "족까내","존나", "존나게", "존니", "졸라", "좀마니", "좀물", "좀쓰레기", "좁빠라라", "좃가튼뇬", "좃간년", "좃까", "좃까리", "좃깟네", "좃냄새", "좃넘", "좃대가리", "좃도", "좃또","좃만아", "좃만이", "좃만한것", "좃만한쉐이", "좃물", "좃물냄새", "좃보지", "좃부랄", "좃빠구리", "좃빠네", "좃빠라라", "좃털", "좆같은놈", "좆같은새끼", "좆까", "좆까라","좆나", "좆년", "좆도", "좆만아", "좆만한년", "좆만한놈", "좆만한새끼", "좆먹어", "좆물", "좆밥", "좆빨아", "좆새끼", "좆털", "좋만한것", "주글년", "주길년", "쥐랄", "지랄","지랼", "지럴", "지뢀", "쪼까튼", "쪼다", "쪼다새끼", "찌랄", "찌질이", "창남", "창녀", "창녀버지", "창년", "처먹고", "처먹을", "쳐먹고", "쳐쑤셔박어", "촌씨브라리","촌씨브랑이", "촌씨브랭이", "크리토리스", "큰보지", "클리토리스", "트랜스젠더", "페니스", "항문수셔", "항문쑤셔", "허덥", "허버리년", "허벌년", "허벌보지", "허벌자식", "허벌자지","허접", "허젚", "허졉", "허좁", "헐렁보지", "혀로보지핧기", "호냥년", "호로", "호로새끼", "호로자슥", "호로자식", "호로짜식", "호루자슥", "호모", "호졉", "호좁", "후라덜넘","후장", "후장꽂아", "후장뚫어", "흐접", "흐젚", "흐졉", "bitch", "fuck", "fuckyou", "nflavor", "penis", "pennis", "pussy", "sex", "sibal"]
                                
                                for word in inappropriateWords {
                                    if newValue.lowercased().contains(word.lowercased()) {
                                        // Show the inappropriate content popup
                                        showInappropriateContentPopup = true
                                        return // Exit the loop if any inappropriate word is found
                                    }
                                }
                            }
                        }
                    
                    Button("확인") {
                        onSave()
                    }
                    .padding()
                    .foregroundColor(.black)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: "77EFFF")))
                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 5)
                }
                .alert(isPresented: $showBioErrorPopup) {
                    Alert(
                        title: Text("한 줄 소개는 15자 이내여야 합니다."),
                        dismissButton: .default(Text("확인"))
                    )
                }
                .alert(isPresented: $showInappropriateContentPopup) {
                    Alert(
                        title: Text("한 줄 소개 변경불가"),
                        message: Text("해당 내용은 상대방에게 불쾌감을 조성할 수 있습니다. 다른 문구를 입력해주세요!"),
                        dismissButton: .default(Text("확인")) {
                            newBio = ""
                        }
                    )
                }
               // .padding()
                .onDisappear {
                    onDisappearAction()
                }
            }
        }
    }
}
