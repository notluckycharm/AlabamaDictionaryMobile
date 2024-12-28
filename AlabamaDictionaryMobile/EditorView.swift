//
//  EditorView.swift
//  AlabamaDictionaryMobile
//
//  Created by Jacob Fernandes on 12/28/24.
//

import SwiftUI

struct EditorView: View {
    let entry: DictionaryEntry
    var body: some View {
        VStack{
            HStack{
                Text(entry.lemma)
                    .font(.title)
                    .bold()
            }
            let defs: [String] = entry.definition.components(separatedBy: ";");
            ForEach(Array(defs.enumerated()), id: \.element) { index, def in
                            HStack {
                                Text("\(index + 1).") // Display the counter
                                    .bold()
                                Text(def) // Display the string
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
            Spacer()
        }
    }
}

