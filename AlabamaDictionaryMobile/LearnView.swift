//
//  LearnView.swift
//  AlabamaDictionaryMobile
//
//  Created by Jacob Fernandes on 1/21/25.
//

import SwiftUI

struct LearnView: View {
    @State var current : Int = 0

    var body: some View {
        NavigationStack{
            ScrollView(){
                VStack{
                    NavigationLink(destination: LessonView()){
                        ZStack{
                            Text("Unit 1: Introductions and Greetings")
                                .zIndex(1)
                                .foregroundColor(Color.white)
                                .bold()
                            RoundedRectangle(cornerRadius: 10)
                                .frame(height: 50)
                                .foregroundColor(current == 0 ? Color.yellow : Color.gray)
                        }.padding()
                    }
                }
            }
        }
    }
}

#Preview {
    LearnView()
}
