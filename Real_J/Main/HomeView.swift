import SwiftUI
import Alamofire

// Lazy View를 나타내는 ViewModifier 정의
struct Lazy<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
    }
}

struct HomeView: View {
    @State private var selectedTab = 0
    let userId: Int64
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 홈화면
            Lazy {
                HomebarView2(userData: userData)
            }
            .tabItem {
                Image("home.png")
                    .renderingMode(.original)
            }
            .tag(0)
            
            // 게임
            Lazy {
                GameView(userData: userData)
            }
            .tabItem {
                Image("game.png")
                    .renderingMode(.original)
            }
            .tag(1)
            
            // 문자
            Lazy {
                MessageView(messageWebSocketManager: WebSocketManager(memberId: userId))
            }
            .tabItem {
                Image("hmessage.png")
                    .renderingMode(.original)
            }
            .tag(2)
            
            // 마이페이지
            Lazy {
                MyInfoView()
            }
            .tabItem {
                Image("info.png")
                    .renderingMode(.original)
            }
            .tag(3)
        }
    }
}
