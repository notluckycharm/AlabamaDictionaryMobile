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
    
    var body: some View {
        VStack{
            HStack{
                Text(entry.lemma)
                    .font(.title)
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
                VStack(spacing:-10){
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
                }
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

