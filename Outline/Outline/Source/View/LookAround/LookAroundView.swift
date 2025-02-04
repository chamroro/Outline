//
//  LookAroundView.swift
//  Outline
//
//  Created by Seungui Moon on 11/2/23.
//

import SwiftUI

struct LookAroundView: View {
    @AppStorage("authState") var authState: AuthState = .logout
    
    var body: some View {
        VStack {
            Spacer()
            Image("lookAroundImage")
                .offset(x: 22, y: 16)
            Text("앗! 회원가입이 필요해요.")
                .font(.customTitle2)
                .padding(.bottom, 8)
            Text("OUTLINE에 가입하면 내가 그린\n러닝 기록을 확인할 수 있어요!")
                .font(.customSubbody)
                .padding(.bottom, 32)
                .multilineTextAlignment(.center)
                .foregroundStyle(.gray300)
            CompleteButton(text: "가입하러 가기", isActive: true) {
                authState = .logout
            }
            .frame(width: 262, height: 55) // CompleteButton안의 horizental padding만큼 더했습니다.
            
            Spacer()
        }
        .padding(.bottom, 100)
    }
}

struct LookAroundModalView: View {
    @AppStorage("authState") var authState: AuthState = .logout
    var completion: () -> Void = {}
    
    var body: some View {
        VStack(spacing: 0) {
            Text("앗! 회원가입이 필요해요.")
                .font(.customTitle2)
                .padding(.top, 48)
                .padding(.bottom, 8)
            Text("OUTLINE에 가입하면 내가 그린\n러닝 기록을 확인할 수 있어요!")
                .font(.customSubbody)
                .multilineTextAlignment(.center)
                .foregroundStyle(.gray300)
                .padding(.bottom, 8)
            Image("lookAroundImage")
                .resizable()
                .scaledToFit()
                .frame(width: 170, height: 170)
                .offset(x: 26)
                .padding(-20)
            CompleteButton(text: "가입하러 가기", isActive: true) {
                authState = .logout
            }
            Button {
                completion()
            } label: {
                Text("계속 둘러보기")
                    .frame(height: 55)
                    .foregroundStyle(.customWhite)
                    .font(.customButton)
            }
            .padding(.top, 8)
            Spacer()
        }
        .presentationDetents([.height(448)])
        .presentationCornerRadius(35)
        .interactiveDismissDisabled()
    }
}

struct LookAroundPopupView: View {
    @AppStorage("authState") var authState: AuthState = .logout
    
    var body: some View {
        RoundedRectangle(cornerRadius: 50)
            .fill(Color.black70)
            .strokeBorder(Color.customPrimary)
            .frame(height: 54)
            .padding(.horizontal, 24)
            .overlay {
                HStack {
                    Text("OUTLINE 둘러보는 중")
                        .foregroundStyle(Color.white)
                        .font(.customSubbody)
                    Spacer()
                    Group {
                        Text("회원가입")
                            .foregroundStyle(Color.white)
                            .font(.customSubbody)
                        Image(systemName: "arrow.right.circle")
                            .foregroundStyle(Color.customPrimary)
                    }
                    .onTapGesture {
                        authState = .logout
                    }
                }
                .frame(height: 54)
                .padding(.horizontal, 44)
            }
    }
}

#Preview {
    LookAroundView()
}
