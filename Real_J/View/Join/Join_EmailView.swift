//
//  Join_EmailView.swift
//  Real_J
//
//  Created by 최가의 on 1/31/24.
//

import SwiftUI
import Alamofire

struct Join_EmailView: View {
    @StateObject private var viewModel = JoinEmailViewModel()
    
    @EnvironmentObject var userData: UserData
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var fullName: String = ""
    @State private var schoolEmail: String = ""
    @State private var isUsernameAvailable: Bool = true
    @State private var isPasswordValid = true
    @State private var emailText: String = ""
    @State private var responseData: MemberResponse?
    @State private var verificationCodes = ""
    @State private var isVerificationCompleted = false
    @State private var isVerificationSuccess = false // 인증 성공 여부
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var timerSeconds = 420
    
    @State var userId: Int64? // 받아온 사용자의 고유 id
    
    @State private var isInvalidLengthAlertPresented = false
    
    
    //연장 버튼 비활성화
    @State private var isButtonDisabled = false
    
    @Binding var isJoinedIn: Bool // isLoggedIn을 바인딩으로 받음
    
    struct MemberResponse: Codable {
        let status: Int
        let id: Int64?
    }
    
    @State private var collegeId: Int64 = 1
    
    @FocusState private var focusedField: Int?
    
    
    let schools = ["@mju.ac.kr"]
    
    var body: some View {
        let gradientColors: [Color] = [
            Color(hex: "FFFFFF"),
            Color(hex: "77EFFF"),
            Color(hex: "CBF9FF"),
            Color(hex: "FFFFFF")
        ]
        NavigationView {
            if viewModel.isVerificationCompleted {
                JoinView(userId: viewModel.userId ?? 0, isJoinedIn: $viewModel.isJoinedIn)
            } else {
                ZStack {
                    
                    LinearGradient(gradient: Gradient(colors: gradientColors), startPoint: .topLeading, endPoint: .bottomTrailing)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            // 터치되었을 때 키보드를 닫음
                            hideKeyboard()
                        }
                    
                    VStack {
                        HStack{
                            Image("main")
                                .resizable()
                                .frame(width: 70, height: 70)
                                .padding(.leading, 10) //우측으로 당기기
                            
                            VStack(alignment: .leading) {
                                Text("회원가입")
                                    .font(.custom("NeoDunggeunmoPro-Regular", size: 30))
                                //.padding(.bottom, 0.01)
                            }
                        }
                        
                        HStack {
                            Text("메일")
                                .font(.custom("GalmuriMono11", size: 22))
                                .padding(.leading, 10)

                            ZStack {
                                Rectangle()
                                    .foregroundColor(.gray)
                                    .frame(width: 180, height: 50)
                                    .cornerRadius(19)
                                
                                TextField("학교 웹메일 입력하세요", text: $viewModel.emailText)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .font(.custom("Galmuri14", size: 17))
                                    //.padding(.horizontal, 15)
                                    .disabled(isButtonDisabled) // 버튼이 눌렸을 때 비활성화
                            }
                            
                            Picker("학교 선택", selection: $collegeId) {
                                ForEach(schools, id: \.self) { school in
                                    Text(school).tag(Int64(1))
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .font(.custom("Galmuri14", size: 10))
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            
                        } //.padding(.horizontal)
                         .padding(.trailing, 10)
                        
                        Button("인증번호 받기") {
                            viewModel.fetchDataFromServer()
                            
                        }
                        .frame(width: 180, height: 40)
                        .font(.custom("NeoDunggeunmoPro-Regular", size: 20))
                        .background(Color(hex: "F3A7FF"))
                        .foregroundColor(.white)
                        .cornerRadius(13)
                        .disabled(isVerificationCompleted) // 둘 중 하나라도 true이면 버튼 비활성화
                        .disabled(isButtonDisabled)
                        
                        HStack {
                            Text("인증번호")
                                .font(.custom("GalmuriMono11", size: 22))
                                .padding(.leading, 10)
                            
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray)
                                    .frame(width: 230, height: 45)
                                    .cornerRadius(19)
                                
                                TextField("", text: $viewModel.verificationCodes)
                                    .textFieldStyle(.plain)
                                    .frame(width: 280, height: 45)
                                    .multilineTextAlignment(.center)
                                    .keyboardType(.numberPad)
                                    .font(.custom("GalmuriMono11", size: 18))
                                    .onChange(of: verificationCodes) { newValue in
                                        // Check if the length is more than 6
                                        if newValue.count > 6 {
                                            verificationCodes = ""
                                            isInvalidLengthAlertPresented.toggle()
                                        }
                                    }
                            }
                        }.alert(isPresented: $isInvalidLengthAlertPresented) {
                            Alert(
                                title: Text("인증번호는 6자리입니다!"),
                                dismissButton: .default(Text("확인"))
                            )
                        }
                        
                        // "회원가입 완료하기" 버튼
                        Button("인증번호 확인") {
                            viewModel.verifyCode()
                        }
                        .frame(width: 180, height: 40) // 버튼 크기 조절
                        .background(Color(hex: "F3A7FF"))
                        .font(.custom("NeoDunggeunmoPro-Regular", size: 20))
                        .foregroundColor(.white)
                        .cornerRadius(13) // 버튼 모서리를 둥글게 설정
                        .padding(.bottom, 10)
                    }
                }}
            }
                .alert(isPresented: $viewModel.showAlert) {
                    Alert(title: Text("알림"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("확인")))
                }
                .disabled(isVerificationCompleted) // 둘 중 하나라도 true이면 버튼 비활성화
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }


#Preview {
    Join_EmailView(isJoinedIn: .constant(false)) // You need to provide a boolean variable here
            .environmentObject(UserData()) // You may need to provide other dependencies as well
    }
