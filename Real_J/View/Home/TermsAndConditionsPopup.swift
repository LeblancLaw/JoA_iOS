//
//  TermsAndConditionsPopup.swift
//  Real_J
//
//  Created by 최가의 on 11/21/23.
//

import SwiftUI

struct TermsAndConditionsPopup: View {
    @State private var agreed: Bool = false
    @Environment(\.presentationMode) var presentationMode
    @State private var showAlert: Bool = false
    @EnvironmentObject var userData: UserData

    var body: some View {
        ScrollView{
            HStack{
                Button("확인했으며 해당 내용에 동의합니다.") {
                    self.agreed = true
                    self.presentationMode.wrappedValue.dismiss() // 팝업을 닫습니다.
                }
                .font(.custom("GalmuriMono11", size: 20))
                .foregroundColor(.red)
                
                //                Button("해당 내용에 동의하지 않습니다.") {
                //                    showAlert = true
                //
                //                    UserDefaults.standard.removeObject(forKey: "loggedInUserId")
                //                    DispatchQueue.main.async {
                //                        if let window = UIApplication.shared.windows.first {
                //                            window.rootViewController = UIHostingController(rootView: SplashView() .environmentObject(userData))
                //
                //                        }
                //                    }
                //                }
                //                .font(.custom("GalmuriMono11", size: 20))
                //                .foregroundColor(.red)
                //                .alert(isPresented: $showAlert) {
                //                    Alert(title: Text("경고"), message: Text("EULA에 동의하지 않으면, JoA 사용이 제한됩니다!"), dismissButton: .default(Text("확인")))
            }
            VStack {
                Text("JoA 최종 사용자 라이선스 계약 (EULA)📌")
                    .font(.custom("NeoDunggeunmoPro-Regular", size: 30))
                    .padding(.top, 5)
                
                Text("본 EULA는 귀하와 JoA(당사) 간의 법적 계약입니다. 귀하는 전체 내용을 읽어야 하지만, 여기에 귀하를 안내할 일부 중요한 부분을 간단히 요약한 내용이 있습니다.")
                    .font(.custom("GalmuriMono11", size: 15))
                
                Text("- 귀하의 콘텐츠는 귀하의 소유이지만 책임감 있고 안전하게 이를 공유해 주십시오.")
                    .font(.custom("GalmuriMono11", size: 15))
                
                Text("- 커뮤니티 표준은 모두에게 개방적이고 안전한 커뮤니티를 구축하는 데 많은 도움이 됩니다.")
                    .font(.custom("GalmuriMono11", size: 15))
                
                Text("- 귀하는 JoA의 로고를 사용하는 것과 같이, 도구, 기능이 공식적이거나 JoA가 승인한 경우가 아닌 한 이를 개발할 수 없습니다.")
                    .font(.custom("GalmuriMono11", size: 15))
                
                Text("- JoA의 승인 없이 JoA가 만든 어떤 것도 배포하거나 상업용으로 사용하지 마십시오.")
                    .font(.custom("GalmuriMono11", size: 15))
                
                Text("- JoA는 귀하가 동일한 관심으로 JoA와 함께 한다는 기대와 함께 언제나 열려 있으며, 정직하고 신뢰하고 있습니다.")
                    .font(.custom("GalmuriMono11", size: 15))
                
                
                Text("서론")
                    .font(.custom("NeoDunggeunmoPro-Regular", size: 20))
                
                Text("JoA 서비스를 다운로드 또는 사용하거나, 본 EULA에 동의하기 위해 클릭을 하는 경우, 본 JoA 라이선스 계약에 동의하는 것으로 간주되므로 이를 주의 깊게 읽어보시기 바랍니다. JoA는 다음 번에 귀하가 JoA 서비스를 사용할 때 효력이 발생하는 이러한 계약 조건을 업데이트할 수 있으므로 잊지 말고 여기에서 수시로 JoA 내용을 확인하십시오.")
                    .font(.custom("GalmuriMono11", size: 15))
                
                Text("JoA 소프트웨어 및 콘텐츠로 할 수 있는 것과 할 수 없는 것")
                    .font(.custom("NeoDunggeunmoPro-Regular", size: 20))
                
                Text("귀하는 JoA 서비스를 다운로드, 설치 및 플레이할 수 있습니다. \n 하지만 JoA가 특별히 동의하지 않는 한 JoA가 만든 사항을 배포해서는 안 됩니다. “JoA가 만든 사항 배포”의 의미는 다음과 같습니다.")
                    .font(.custom("GalmuriMono11", size: 15))
                
                Text("- JoA의 소프트웨어 또는 콘텐츠의 복사본을 다른 사용자에게 제공 또는 무단 배포")
                    .font(.custom("GalmuriMono11", size: 15))
                
                Text("- JoA가 만든 사항을 상업용으로 사용")
                    .font(.custom("GalmuriMono11", size: 15))
                
                Text("- JoA가 만든 사항으로부터 돈을 벌려고 시도 또는 다른 사용자가 볼공정 또는 불합리한 방식으로 JoA가 만든 것에 엑세스 할 수 있도록 하는 것")
                    .font(.custom("GalmuriMono11", size: 15))
                
                Text("명확하게 설명하면, 서비스 또는 JoA가 만든 것에는 서비스, 그리고 향후 공개할 수 있는 다른 모든 콘텐츠가 포함되지만 이에 국한되지 않습니다. \n 또한 여기에는 업데이트, 패치, 다운로드할 수 있는 콘텐츠나 수정된 버전, 이러한 사항의 일부 또는 콘텐츠 또는 그 밖에 JoA가 만든 모든 것이 포함됩니다. \n 귀하에게 금지된 사항에 대해서는 수행하지 마십시오.")
                    .font(.custom("GalmuriMono11", size: 15))
                
                Text("콘텐츠")
                    .font(.custom("NeoDunggeunmoPro-Regular", size: 20))
                
                Text("활기차고 우호적인 커뮤니티를 유지하는데 핵심은 우리의 가치에 깃들어 있습니다.")
                    .font(.custom("GalmuriMono11", size: 15))
                
                Text("① JoA는 우리 모두를 위한 것입니다. \n② 다양성은 JoA의 커뮤니티를 강화합니다. \n③ 타인과의 커뮤니케이션은 안전하고 포용적인 것이어야 합니다. \n④ 타인에 대한 무분별한 비방, 욕설은 허용되지 않습니다.")
                    .font(.custom("GalmuriMono11", size: 15))
                    .foregroundColor(.red)
                
                Text("타인과의 커뮤니케이션은 안전하고 포용적이어야 하며, 무분별한 비방과 욕설은 허용되지 않습니다.")
                    .font(.custom("NeoDunggeunmoPro-Regular", size: 20))
                    .foregroundColor(.red)
                
                Text("- 모든 사람들을 환영하고 포용할 수 있는 JoA 커뮤니티를 유지하기 위해, JoA는 증오심 표현, 욕설, 비방 또는 폭력적인 콘텐츠, 괴롭힘, 성적 권유, 사기 또는 다른 사람을 위협하는 행위에 대한 무관용 정책을 시행하고 있습니다. \n- JoA로 만드는 프로필 사진, 한줄소개, 이름, 힌트 및 기타 콘텐츠는 귀하에게 의미 있는 것을 자랑하고 자신을 표현할 수 있는 좋은 방법이 될 수 있습니다. 하지만 극단적인 편견을 묘사하거나 무분별한 욕설, 불법 활동을 조장하는 콘텐츠는 허용되지 않습니다. \n JoA는 여러분에 의해, 여러분을 위해 만들어졌습니다. 자신만의 프로필을 자랑하며 타인과의 원활한 커뮤니케이션을 위해 자신만의 방식으로 기여하면서 안전함을 느낄 수 있도록 귀하의 안전을 최우선으로 생각합니다. \n JoA는 이러한 커뮤니티 표준 또는 본 EULA를 위반하는 사람의 활동을 일시 중지하거나 영구적으로 금지할 수 있는 권리가 있습니다. JoA의 중재 정책, 플레이어를 보고하는 방법, 귀하의 계정에 대한 유효한 소송 행위에 대해 이의를 제기하는 방법에 대해 자세히 알아보고 싶다면 mjuappsw@gmail.com 로 문의 부탁드립니다.")
                    .font(.custom("GalmuriMono11", size: 15))
                
                
                Text("개인정보 보호")
                    .font(.custom("NeoDunggeunmoPro-Regular", size: 20))
                
                Text("JoA의 개인정보취급방침은 모든 JoA 서비스에 적용됩니다. 개인정보 처리방침에 대해 더욱 더 자세한 사항을 검토하고 싶다면 아래의 링크를 클릭하십시오. \n https://docs.google.com/document/d/14VJ3sb7M76uvjQni_BEyRzM5QaoghYojk86FYLHYMx0/edit")
                    .font(.custom("GalmuriMono11", size: 15))
                
                
                Text("일반 항목")
                    .font(.custom("NeoDunggeunmoPro-Regular", size: 20))
                
                Text("JoA에 대한 제안을 제공하는 경우 해당 제안은 무료로 수행되며, JoA는 제안을 수락하거나 고려할 의무가 없습니다. 즉, JoA가 원하는 방식으로 제안을 수락하거나 고려할 의무가 없습니다. 즉, JoA가 원하는 방식으로 제안을 사용하거나 사용하지 않을 수 있으며 제안에 대해 지급할 필요가 없습니다. JoA가 지급할 만한 제안이 있다고 판단하는 경우, 먼저 지급을 원한다고 JoA에 말하고 JoA가 제안을 제출하도록 요구하는 것을 서면으로 응답할 때까지 제안을 JoA에 알리지 마십시오.")
                    .font(.custom("GalmuriMono11", size: 15))
                
                
                Text("JoA 서비스에서 누군가가 귀하의 지적 재산권을 침해하고 있음을 JoA에 알리려고 하는 경우")
                    .font(.custom("NeoDunggeunmoPro-Regular", size: 20))
                
                
                Text("mjuappsw@gmail.com 로 통지를 제출하십시오. 적합한 경우 JoA는 반복적으로 위반하는 사용자의 계정을 해지할 수 있습니다. JoA는 자체 판단에 따라 모든 콘텐츠를 내릴 권리가 있습니다.")
                    .font(.custom("GalmuriMono11", size: 15))
                
                Text("회사 정보 \n")
                    .font(.custom("NeoDunggeunmoPro-Regular", size: 20))
                Text("JoA.ent \n 연락처 : mjuappsw@gmail.com \n 작성자 : 최가의")
                    .font(.custom("GalmuriMono11", size: 15))
            }
            .padding()
            .opacity(agreed ? 0 : 1) // 동의했을 경우 팝업을 숨김
        }
    }
}
