//
//  SplashView.swift
//  Real_J
//
//  Created by 최가의 on 2023/07/18.
//

import SwiftUI

struct SplashView: View {
    
    @State private var isMailViewPresented = false //학교 인증 화면 전환
    @State private var isLoginViewpresented = false
    @State private var isLoggedIn = false // 이 부분 추가
    @State private var isJoinedIn = false
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        let gradientColors: [Color] = [
            Color(hex: "FFFFFF"),
            Color(hex: "77EFFF"),
            Color(hex: "CBF9FF"),
            Color(hex: "FFFFFF")
        ]
        return ZStack{
            LinearGradient(gradient: Gradient(colors:gradientColors), startPoint: .topLeading, endPoint:.bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            //let userId = userData.userId
            
            if isLoggedIn || isJoinedIn {
                HomeView(userId: userData.userId ?? 0)
            }
            else{
                VStack {
                    Image("main")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(width: 420, height: 450)
                    
                    Text("JoA")
                        .font(.custom("Galmuri11", size:30))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)
                        .padding(.top, -45)
                        .fixedSize(horizontal: false, vertical: true) // 세로 크기 고정
                    
                    Text("학교에서 친해지고 싶은 사람을 발견했다?")
                        .font(.custom("NeoDunggeunmoPro-Regular", size:17))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)

                    Text("고백에 필요한 것은 술도 용기도 아니라 ‘JoA’다!")
                        .font(.custom("NeoDunggeunmoPro-Regular", size:17))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)
                    //                        .fixedSize(horizontal: false, vertical: true) // 세로 크기 고정
                    Text("나만의 캠퍼스 라이프를 즐기고 싶다면?")
                        .font(.custom("NeoDunggeunmoPro-Regular", size:17))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)
                    //                        .fixedSize(horizontal: false, vertical: true) // 세로 크기 고정
                    Button(action: {
                        isLoginViewpresented = true
                    }){
                        Text("로그인")
                            .font(.custom("GalmuriMono11", size: 23))
                            .frame(width: 150, height: 15)
                            .foregroundColor(.white)
                            .padding(.horizontal, 70)
                            .padding(.vertical, 15)
                            .background(LinearGradient(gradient: Gradient(colors: [Color(hex: "EBE1FD"), Color(hex: "7C33FB")]), startPoint: .top, endPoint: .bottom))
                            .cornerRadius(15) //모서리 둥글게
                    }
                    .sheet(isPresented: $isLoginViewpresented) {
                        LoginView(isLoggedIn: $isLoggedIn) // isLoggedIn을 바인딩으로 전달
                    }
                    
                    Button(action: {
                        isMailViewPresented = true
                        
                    }){
                        Text("회원가입")
                            .font(.custom("GalmuriMono11", size: 23))
                            .frame(width: 150, height: 15)
                            .foregroundColor(.white)
                            .padding(.horizontal, 70)
                            .padding(.vertical, 15)
                            .background(LinearGradient(gradient: Gradient(colors: [Color(hex: "A907C4"), Color(hex: "F3A7FF")]), startPoint: .top, endPoint: .bottom))
                            .cornerRadius(15) //모서리 둥글게
                    }
                    .sheet(isPresented: $isMailViewPresented) {
                        // JoinView(isJoinedIn: $isJoinedIn)
                        Join_EmailView(isJoinedIn: $isJoinedIn)
                        
                    }
                    Text("앱 2.1 ver")
                        .font(.custom("Galmuri11", size: 10))
                        .hTrailing()
                        .padding(.top, 10)
                        .padding(.trailing, 25) // 레이블의 오른쪽 간격을 조절
                }.onAppear {
                    // 앱이 시작될 때 사용자의 로그인 상태를 확인
                    if let loggedInUserId = UserDefaults.standard.value(forKey: "loggedInUserId") as? Int64 {
                        // 저장된 사용자 ID가 있다면 자동으로 로그인
                        userData.setUserId(loggedInUserId)
                        isLoggedIn = true
                    } //1017 수정됨
                    print("\(isLoggedIn)")
                    print("\(isJoinedIn)")
                }
            }
        }
    }
    
}

    struct SplashView_Previews: PreviewProvider {
        static var previews: some View {
            SplashView()
        }
    }

