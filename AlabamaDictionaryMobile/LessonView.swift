//
//  LessonView.swift
//  AlabamaDictionaryMobile
//
//  Created by Jacob Fernandes on 1/22/25.
//

import SwiftUI

struct LessonView: View {
    var Prompts = [
        0 : "Translate the following into Alabama.",
        1 : "Translate the following into English.",
        2 : "Translate what you hear.",
        3 : "Choose the correct answer."
    ]
    @State var mode = 1 // 0 == wordbank, 1 == text selection, 2 == multiple choice
    @State var text : String = ""
    @State var question: String = "Aliilamoolo."
    @State var answers: [String] = []
    var body: some View {
        VStack{
            Text(Prompts[3] ?? "Complete the task.").font(.title).padding()
            Text(question)
                .font(.largeTitle)
                    .fontWeight(.bold)
                .padding()
            if mode == 1 {
                UnderlinedTextBoxesView(answers: $answers)
            }
            Spacer()
            if mode == 0 {
                TextEditor(text: $text)
                    .frame(height: 250) // Adjust the height as needed
                    .background(Color.gray.opacity(0.2)) // Optional background color
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    ).padding()
            }
            else if mode == 1 {
                FlowLayout(items: ["thank", "welcome", "hello!", "you", "see", "help", "test", "cmon", "this", "is", "a", "test"], spacing: 10, answers: $answers)
            }
            ZStack{
                Text("Check Answer")
                    .zIndex(1)
                    .foregroundColor(Color.white)
                    .bold()
                RoundedRectangle(cornerRadius: 10)
                    .frame(height: 50)
                    .foregroundColor(Color.yellow)
            }.padding()
        }.padding()
        .toolbar {
            if mode == 1 || mode == 0 {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack{
                        Button(action: {
                            withAnimation{
                                mode = mode == 0 ? 1 : 0
                            }
                        }) {
                            Image(systemName: mode == 0 ? "pencil.slash" : "pencil")
                                .foregroundColor(.gray)
                        }
                        Text(mode == 0 ? "Text entry mode" : "Word bank mode")
                    }
                }
            }
        }
    }
}

struct UnderlinedTextBoxesView: View {
    @State var text: String = ""
    @Binding var answers: [String]
    var body: some View {
        HStack(spacing: 10) { // Adjust spacing between boxes
            VStack {
                ForEach(answers.indices, id: \.self) { row in
                    VStack {
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(.gray)
                            .opacity(0.3)
                        HStack {
                            answer(
                                cellPadding: 10,
                                item: answers[row],
                                onClick: { isVisible in
                                    // Toggle visibility
                                    if isVisible {
                                        if let index = answers.firstIndex(of: answers[row]) {
                                            answers.remove(at: index)
                                        }
                                    }
                                },
                                answers: $answers,
                                resultColor: Color.white,
                                isVisible: true
                            )
                        }
                        .frame(height: 32)
                    }
                }
                if [answers].count < 3 {
                    ForEach(0..<(3 - answers.count), id: \.self) { _ in
                        VStack {
                            Rectangle()
                                .frame(height: 2)
                                .foregroundColor(.gray)
                                .opacity(0.3)
                            HStack {
                                // Add your HStack content here, if any
                            }
                            .frame(height: 32)
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    // Calculate text width dynamically
    func textWidth(for text: String, fontSize: CGFloat) -> CGFloat {
        let font = UIFont.systemFont(ofSize: fontSize)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let size = (text as NSString).size(withAttributes: attributes)
        return size.width + 10 // Add padding to avoid being too tight
    }
    
}

struct FlowLayout: View {
    let items: [String]
    let spacing: CGFloat
    @Binding var answers: [String]
    let cellPadding: CGFloat = 8
    
    @State private var contentHeight: CGFloat = .zero // Dynamic height tracking

        var body: some View {
            GeometryReader { geometry in
                generateContent(in: geometry.size)
                    .background(
                        GeometryReader { contentGeometry in
                            Color.clear
                                .onAppear {
                                    self.contentHeight = contentGeometry.size.height
                                }
                                .onChange(of: contentGeometry.size) { newSize in
                                    self.contentHeight = newSize.height
                                }
                        }
                    )
                    .frame(height: contentHeight)
            }
            .frame(height: contentHeight)
        }
    
    private func generateContent(in size: CGSize) -> some View {
        var rows: [[String]] = [[]]
        var currentRowWidth: CGFloat = spacing * 2
        
        for item in items {
            let itemWidth = textWidth(for: item, in: size) + spacing + (cellPadding * 2)
            
            if currentRowWidth + itemWidth + spacing > size.width {
                rows.append([item]) // Start a new row
                currentRowWidth = itemWidth
            } else {
                rows[rows.count - 1].append(item) // Add to the current row
                currentRowWidth += itemWidth
            }
        }
        
        return VStack(spacing: spacing) {
            ForEach(0..<rows.count, id: \.self) { rowIndex in
                HStack(spacing: spacing) {
                    ForEach(rows[rowIndex], id: \.self) { item in
                        answer(cellPadding: cellPadding, item: item,
                               onClick: { isVisible in
                                   // Toggle visibility
                                    answers.append(item)
                               },
                               answers: $answers,
                               resultColor: Color.gray,
                               isVisible: !answers.contains(item))
                    }
                }
            }
        }
        .padding(.horizontal, cellPadding)
    }
    
    private func textWidth(for text: String, in size: CGSize) -> CGFloat {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let attributes = [NSAttributedString.Key.font: font]
        let textSize = text.size(withAttributes: attributes)
        return textSize.width
    }
}

struct answer: View {
    let cellPadding: CGFloat
    let item: String
    let onClick: (Bool) -> Void
    @Binding var answers : [String]
    let resultColor: Color
    @State var isVisible: Bool

    var body: some View {
            Button(action: {
                withAnimation{
                    onClick(isVisible)
                    isVisible.toggle()
                }
            }){
                Text(item)
                    .padding(cellPadding)
                    .cornerRadius(8)
                    .opacity(isVisible ? 1 : 0)
            }.buttonStyle(PlainButtonStyle())
            .background(isVisible ? Color.white : resultColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, lineWidth: 1)
            )
    }
    private func textWidth(for text: String, in size: CGSize) -> CGFloat {
        let font = UIFont.preferredFont(forTextStyle: .body)
        let attributes = [NSAttributedString.Key.font: font]
        let textSize = text.size(withAttributes: attributes)
        return textSize.width
    }
}

#Preview {
    LessonView()
}
