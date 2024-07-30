//
//  ContentView.swift
//  Wavify
//
//  Created by Manuel Plank on 23.07.24.
//

import SwiftUI

enum WavifyError: Error {
    case runtimeError(String)
}

struct ContentView: View {
    private let audioRecorder = AudioRecorder()
    private let modelPath: String
    private let engine: SttEngine

    init() {
        guard let modelPath = Bundle.main.path(forResource: "model-en", ofType: "bin") else {
            fatalError("Failed to find model file.")
        }
        self.modelPath = modelPath
        SttEngine.setupLogger()
        self.engine = SttEngine(modelPath: modelPath, apiKey: "80aceba391aaac80f3000fab53f694ba")! // TODO: remove unwrap and apiKey
    }

    @State private var message: String = ""
    @State private var successful: Bool = true

    @State private var readyToRecord: Bool = true

    private func recordAndRecognize() {
      audioRecorder.record { recordResult in
        let recognizeResult = recordResult.flatMap { recordingBufferAndData in
            let modelResult = engine.recognizeSpeech(from: convertDataToFloatArray(data: recordingBufferAndData.data))
            switch modelResult {
            case .some(let res):
                return .success(res)
            case .none:
                return .failure(WavifyError.runtimeError("Could not process data"))
            }
        }
        endRecordAndRecognize(recognizeResult)
      }
    }

    private func endRecordAndRecognize(_ result: Result<String, Error>) {
      DispatchQueue.main.async {
        switch result {
        case .success(let transcription):
          message = transcription
          successful = true
        case .failure(let error):
          message = "Error: \(error)"
          successful = false
        }
        readyToRecord = true
      }
    }

    var body: some View {
      VStack {
        Text("Press \"Record\", say something, and get recognized!")
          .padding()

        Button("Record") {
          readyToRecord = false
          recordAndRecognize()
        }
        .padding()
        .disabled(!readyToRecord)

        Text("\(message)")
          .foregroundColor(successful ? .none : .red)
          .padding()
      }
    }
}

#Preview {
    ContentView()
}
