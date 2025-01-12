//
//  AboutView.swift
//  AlabamaDictionaryMobile
//
//  Created by Jacob Fernandes on 12/30/24.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        ScrollView{
            VStack(spacing:5){
                HStack(alignment: .center, spacing: 16) {
                    Image("Alabama-Coushata")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 75, height: 75)
                    
                    Text("Dictionary of the Alabama Language").font(.system(size: 25)).bold()
                }.padding()
                HStack{
                    Text("Mobile version; Compiled by Jacob Fernandes")
                    Spacer()
                }.padding(.leading, 20)
                HStack{
                    Text("This is a mobile electronic edition based on the following work: ")
                    Spacer()
                }.padding(.leading, 20)
                VStack(spacing:0){
                    HStack{
                        Text("Dictionary of the Alabama Language").italic()
                        Spacer()
                    }
                    HStack{
                        Text("Cora Sylestine, Heather K.Hardy, and Timothy Montler.")
                        Spacer()
                    }
                    HStack{
                        Text("Austin: University of Texas Press. 1993.")
                        Spacer()
                    }
                }.padding(.leading, 40)
                HStack{
                    Text("Alabama is Muskogean Language spoken by the Alabama people of the Alabama-Coushatta tribe of Texas and formerly spoken in the Alabama-Quassarte Tribal Town in Oklahoma.")
                    Spacer()
                }.padding(.leading, 20)
                HStack{
                    Text("Acknowledgements").bold()
                    Spacer()
                }.padding()
                HStack{
                    Text("The Alabama Dictionary Online is the result of a collaborative project between the Alabama-Coushatta tribe of Texas and the WOLF (Working on Language in the Field) Lab at Harvard University.")
                    Spacer()
                }.padding(.leading, 20)
                HStack{
                    Text("We deeply thank the Tribal Council of the Alabama-Coushatta tribe of Texas, and all the consultants who collaborated for their patience and their willingness to share their stories, their homes, and especially their language with us. This project would not have been possible without them.")
                    Spacer()
                }.padding(.leading, 20)
                Spacer()
            }
        }
    }
}

#Preview {
    AboutView()
}
