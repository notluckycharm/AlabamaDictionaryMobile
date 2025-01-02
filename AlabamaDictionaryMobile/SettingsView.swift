//
//  SettingsView.swift
//  AlabamaDictionaryMobile
//
//  Created by Jacob Fernandes on 12/31/24.
//

import SwiftUI

struct SettingsView: View {
    @Binding var isShowing: Bool
    @Binding var reMode: Bool
    @Binding var limitAudio: Bool
        var edgeTransition: AnyTransition = .move(edge: .leading)
        var body: some View {
            ZStack(alignment: .bottom) {
                if (isShowing) {
                    Color.black
                        .opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            isShowing.toggle()
                        }
                    SideMenu(reMode: $reMode, limitAudio: $limitAudio)
                        .transition(edgeTransition)
                        .background(
                            Color.clear
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea()
            .animation(.easeInOut, value: isShowing)
            .foregroundColor(.black)
        }
}

struct SideMenu: View {
    @Binding var reMode: Bool
    @Binding var limitAudio: Bool
    var body: some View {
        HStack{
            ZStack{
                Rectangle()
                    .fill(.white)
                    .frame(width: 270)
                    .shadow(color: .purple.opacity(0.1), radius: 5, x: 0, y: 3)
                VStack(alignment: .leading, spacing: 0){
                    Text("Search Settings")
                        .font(.title)
                        .bold()
                        .padding()
                    HStack{
                        Text("[.*]")
                        Toggle(
                            "Regular Expressions Mode",
                            isOn: $reMode
                        )
                    }.padding()
                    HStack{
                        Toggle("Only show entries with audio",
                               isOn: $limitAudio)
                    }.padding()
                    Spacer()
                }.padding(.top, 50)
                    .frame(width: 270)
                    .background(
                        Color(.white)                    )
            }
            Spacer()
        }
    }
}
