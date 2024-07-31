//
//  WavifyLib.swift
//  Wavify
//
//  Created by Manuel Plank on 26.07.24.
//

import Foundation
import WavifyCore



class SttEngine {
    private var engine: OpaquePointer?

    init?(modelPath: String, apiKey: String) {
        guard let engine = create_stt_engine(modelPath, apiKey) else {
            return nil
        }
        self.engine = engine
    }

    deinit {
        if let engine = engine {
            destroy_stt_engine(engine)
        }
    }

    func recognizeSpeech(from data: FloatArray) -> String? {
        guard let engine = engine else { return nil }
        guard let result = stt(engine, data) else { return nil }
        defer { free_result(result) }
        return String(cString: result)
    }

    static func setupLogger() {
        setup_logger()
    }
}

func convertDataToFloatArray(data: Data) -> FloatArray {
    let floatSize = MemoryLayout<Float>.size
    let count = data.count / floatSize

    let floatPointer = data.withUnsafeBytes { (rawBufferPointer) -> UnsafePointer<Float> in
        let rawPointer = rawBufferPointer.baseAddress!.assumingMemoryBound(to: Float.self)
        return UnsafePointer(rawPointer)
    }

    return FloatArray(data: floatPointer, len: UInt(count))
}
