//
//  SwiftUIView.swift
//  Real_J
//
//  Created by 최가의 on 1/4/24.
//

import SwiftUI

struct SwiftUIView: View {
    
    @State private var isActive: Bool = false
    @State private var size: Double = 1.0
    @State private var opacity: Double = 1.0
    
    var body: some View {
        let gradientColors: [Color] = [
            Color(hex: "77EFFF"),
            Color(hex: "CBF9FF"),
            //Color(hex: "FFFFFF")
            //Color(hex: "FFFFFF")
        ]
        return ZStack{
            LinearGradient(gradient: Gradient(colors:gradientColors), startPoint: .topLeading, endPoint:.bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            if isActive {
                SplashView()
            } else {
                VStack (spacing: 20){
                    Image("main")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                    
                    Text("JoA")
                        .font(.custom("Galmuri11", size:20))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)
                        .padding(.top, 180)
                    
                        Text("2.1 ver")
                            .font(.custom("GalmuriMono11", size: 10))
                            
                    } //: VStack 끝
                .scaleEffect(size)
                .opacity(opacity)
                .onAppear{
                    withAnimation(.easeInOut(duration: 1.5)){
                        size = 0.5
                        opacity = 0.5
                        //3초 후 이동
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4){
                            isActive = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    SwiftUIView()
}
