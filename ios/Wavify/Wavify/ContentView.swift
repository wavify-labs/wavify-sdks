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
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "WAVIFY_API_KEY") as? String else {
            fatalError("No api key found.")
        }
        self.engine = SttEngine(modelPath: modelPath, apiKey: apiKey)!
    }

    @State private var message: String = ""
    @State private var successful: Bool = true

    @State private var readyToRecord: Bool = true

    private func recordAndRecognize() {
      audioRecorder.startRecording { recordResult in
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
        Image("Logo")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 150, height: 150)
          
        Text("Press \"Record\", say something, and get recognized!")
              .padding()

        Button("Record") {
            readyToRecord = false
            recordAndRecognize()
            }
            .padding()
            .disabled(!readyToRecord)
          
        Button("Stop") {
            readyToRecord = true
            audioRecorder.stopRecording()
            }
            .padding()
            .disabled(readyToRecord)

        Text("\(message)")
              .foregroundColor(successful ? .none : .red)
              .padding()
      }
    }
}

#Preview {
    ContentView()
}
