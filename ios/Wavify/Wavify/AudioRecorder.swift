//
//  AudioRecorder.swift
//  Wavify
//
//  Created by Manuel Plank on 30.07.24.
//

import AVFoundation
import Foundation

private let kSampleRate: Int = 16000

class AudioRecorder: ObservableObject {
  typealias RecordingBufferAndData = (buffer: AVAudioBuffer, data: Data)
  typealias RecordResult = Result<RecordingBufferAndData, Error>
  typealias RecordingDoneCallback = (RecordResult) -> Void

  enum AudioRecorderError: Error {
    case Error(message: String)
  }

  private var recorderDelegate: RecorderDelegate?
  private var recorder: AVAudioRecorder?
    
  @Published var audioLevel: Float = 0.0
  private var meteringTimer: Timer?

  func startRecording(callback: @escaping RecordingDoneCallback) {
    let session = AVAudioSession.sharedInstance()
    session.requestRecordPermission { allowed in
      do {
        guard allowed else {
          throw AudioRecorderError.Error(message: "Recording permission denied.")
        }

        try session.setCategory(.record)
        try session.setActive(true)

        let tempDir = FileManager.default.temporaryDirectory
        let recordingUrl = tempDir.appendingPathComponent("recording.wav")

        let formatSettings: [String: Any] = [
          AVFormatIDKey: kAudioFormatLinearPCM,
          AVSampleRateKey: kSampleRate,
          AVNumberOfChannelsKey: 1,
          AVLinearPCMBitDepthKey: 16,
          AVLinearPCMIsBigEndianKey: false,
          AVLinearPCMIsFloatKey: false,
          AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        let recorder = try AVAudioRecorder(url: recordingUrl, settings: formatSettings)
        self.recorder = recorder
        recorder.isMeteringEnabled = true

        let delegate = RecorderDelegate(callback: callback)
        recorder.delegate = delegate
        self.recorderDelegate = delegate

        guard recorder.record() else {
          throw AudioRecorderError.Error(message: "Failed to start recording.")
        }
          
        self.startMetering()

      } catch {
        callback(.failure(error))
      }
    }
  }

  func stopRecording() {
    recorder?.stop()
    stopMetering()
  }
    
  // For the sound wave animation
  private func startMetering() {
      meteringTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
        self.recorder?.updateMeters()
        if let averagePower = self.recorder?.averagePower(forChannel: 0) {
            DispatchQueue.main.async {
                let minLevel: Float = -60.0
                let maxLevel: Float = 0.0
                let clampedLevel = max(minLevel, min(averagePower, maxLevel))
                self.audioLevel = (clampedLevel - minLevel) / (maxLevel - minLevel)
            }
        }
    }
  }

  private func stopMetering() {
    meteringTimer?.invalidate()
    meteringTimer = nil
  }

  private class RecorderDelegate: NSObject, AVAudioRecorderDelegate {
    private let callback: RecordingDoneCallback

    init(callback: @escaping RecordingDoneCallback) {
      self.callback = callback
    }

    func audioRecorderDidFinishRecording(
      _ recorder: AVAudioRecorder,
      successfully flag: Bool
    ) {
      let recordResult = RecordResult { () -> RecordingBufferAndData in
        guard flag else {
          throw AudioRecorderError.Error(message: "Recording was unsuccessful.")
        }

        let recordingUrl = recorder.url
        let recordingFile = try AVAudioFile(forReading: recordingUrl)

        guard
          let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: recordingFile.fileFormat.sampleRate,
            channels: 1,
            interleaved: false)
        else {
          throw AudioRecorderError.Error(message: "Failed to create audio format.")
        }

        guard
          let recordingBuffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(recordingFile.length))
        else {
          throw AudioRecorderError.Error(message: "Failed to create audio buffer.")
        }

        try recordingFile.read(into: recordingBuffer)

        guard let recordingFloatChannelData = recordingBuffer.floatChannelData else {
          throw AudioRecorderError.Error(message: "Failed to get float channel data.")
        }

        let recordingData = Data(
          bytesNoCopy: recordingFloatChannelData[0],
          count: Int(recordingBuffer.frameLength) * MemoryLayout<Float>.size,
          deallocator: .none)

        return (recordingBuffer, recordingData)
      }

      callback(recordResult)
    }

    func audioRecorderEncodeErrorDidOccur(
      _ recorder: AVAudioRecorder,
      error: Error?
    ) {
      if let error = error {
        callback(.failure(error))
      } else {
        callback(.failure(AudioRecorderError.Error(message: "Encoding was unsuccessful.")))
      }
    }
  }
}
