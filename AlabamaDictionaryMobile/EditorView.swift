//
//  EditorView.swift
//  AlabamaDictionaryMobile
//
//  Created by Jacob Fernandes on 12/28/24.
//

import SwiftUI
import AVFoundation

struct EditorView: View {
    let entry: DictionaryEntry
    @State private var audioPlayer: AVPlayer? = nil
    @State private var fontSize: CGFloat = 18
    @State private var showOverlay = false
    var body: some View {
        ZStack(alignment: .top){
            if showOverlay {
                VStack{
                    TextModifyView(fontSize: $fontSize)
                        .frame(maxWidth: .infinity)
                        .background(.white)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        .padding()
                        .transition(.move(edge: .top))
                }.zIndex(1)
            }
            VStack{
                HStack{
                    Text(entry.lemma)
                        .font(.system(size: fontSize + 8))
                        .bold()
                    if (entry.audio.count > 0) {
                        Button(action: { playAudio(at: entry.audio[0]) }) {
                            Image(systemName: "speaker.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 25, height: 25) // Adjust size as needed
                                .foregroundColor(.gray) // Change color as desired
                        }
                    }
                }
                VStack{
                    let defs: [String] = entry.definition.components(separatedBy: ";");
                    ForEach(Array(defs.enumerated()), id: \.element) { index, def in
                        HStack{
                            if (def.prefix(3) != "to " && !entry.lemma.contains("-") && !entry.definition.contains("Var") && !entry.definition.contains("Negative form")) {
                                Text("(Noun)").italic().foregroundColor(.cyan)
                            }
                            else {
                                if let wordClass = entry.wordClass, wordClass != "nan" {
                                    Text("[\(wordClass)]").italic().foregroundColor(.cyan)
                                }
                                else if (def.prefix(3) == "to ") {
                                    Text("(Verb)").italic().foregroundColor(.cyan)
                                }
                            }
                            Spacer()
                        }
                        HStack {
                            Text("\(index + 1).") // Display the counter
                                .bold()
                            Text(def) // Display the string
                            Spacer()
                        }
                        .padding(.vertical, 2)
                    }
                    ForEach(entry.sentences) { sentence in
                        VStack(spacing:0){
                            if let alabama = sentence.akz {
                                HStack{
                                    Text(alabama).bold()
                                    Spacer()
                                }
                            }
                            if let english = sentence.en {
                                HStack{
                                    Text(english)
                                    Spacer()
                                }
                            }
                        }.padding(.leading, 15)
                    }
                    if let notes = entry.notes, notes != "nan" {
                        HStack{
                            Text("Notes:").italic()
                            Spacer()
                        }.padding(.top, 8)
                        HStack{
                            Text("\(notes)").italic().foregroundColor(.gray)
                            Spacer()
                        }
                    }
                    Spacer()
                }.environment(\.font, .system(size: fontSize))
            }.toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            showOverlay.toggle()
                        }
                    }) {
                        Image(systemName: "textformat.size")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    func playAudio(at path: String) {
        // Find the file URL in the app bundle
        guard let filePath = Bundle.main.url(forResource: "\(path)", withExtension: "wav")
        else {
            print("Invalid URL for file: \(path)")
            return
        }
        
        // Create and play the AVPlayer
        audioPlayer = AVPlayer(url: filePath)
        audioPlayer?.play()
    }

}

struct TextModifyView: View {
    @Binding var fontSize: CGFloat
    
    var body: some View {
        VStack(spacing:0){
            HStack(alignment: .lastTextBaseline){
                Text("Small text")
                    .font(.system(size: 12))
                    .padding(.leading, 5 )
                Spacer()
                Text("Large text")
                    .font(.system(size: 30))
                    .padding(.trailing, 5)
            }
            Slider(value: $fontSize, in: 12...30) {
                Text("Font Size")
            }.padding(10)
        }
    }
}
