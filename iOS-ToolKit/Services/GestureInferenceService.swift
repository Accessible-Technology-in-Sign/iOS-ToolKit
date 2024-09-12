//
//  GestureInferenceService.swift
//  iOS-ToolKit
//
//  Created by Srivinayak Chaitanya Eshwa on 11/09/24.
//

import UIKit
import Accelerate
import TensorFlowLite

struct InferenceResult{
    let inferenceTime: Double
    let inferences: [Inference]
}

/**
 Stores one formatted inference.
 */
struct Inference {
    let confidence: Float
    let label: String
}

/// Information about a model file or labels file.
struct FileInfo {
    let name: String
    let fileExtension: String
}

// Information about the model to be loaded.
enum Model {
    static let modelInfo: FileInfo = FileInfo(name: "model_2", fileExtension: "tflite")
    static let labelsInfo: FileInfo = FileInfo(name: "signsList", fileExtension: "txt")
}

/**
 This class handles all data preprocessing and makes calls to run inference on
 a given frame through the TensorFlow Lite Interpreter. It then formats the
 inferences obtained and returns the top N results for a successful inference.
 */
final class GestureInferenceService {
    
    // MARK: Paremeters on which model was trained
    let batchSize = 1
    let wantedInputChannels = 3
    let wantedInputWidth = 224
    let wantedInputHeight = 224
    let stdDeviation: Float = 127.0
    let mean: Float = 1.0
    
    // MARK: Constants
    let threadCountLimit: Int32 = 10
    
    // MARK: Instance Variables
    /// The current thread count used by the TensorFlow Lite Interpreter.
    let threadCount: Int
    
    var labels: [String] = []
    private let resultCount = 1
    private let threshold = 0.5
    
    /// TensorFlow Lite `Interpreter` object for performing inference on a given model.
    private var interpreter: Interpreter
    
    private let bgraPixel = (channels: 4, alphaComponent: 3, lastBgrComponent: 2)
    private let rgbPixelChannels = 3
    private let colorStrideValue = 10
    
    /// Information about the alpha component in RGBA data.
    private let alphaComponent = (baseOffset: 4, moduloRemainder: 3)
    
    // MARK: Initializer
    /**
     This is a failable initializer for ModelDataHandler. It successfully initializes an object of the class if the model file and labels file is found, labels can be loaded and the interpreter of TensorflowLite can be initialized successfully.
     */
    init?(modelFileInfo: FileInfo, labelsFileInfo: FileInfo, threadCount: Int = 1) {
        // TODO: Convert to try catch
        // Construct the path to the model file.
        guard let modelPath = Bundle.main.path(
            forResource: modelFileInfo.name,
            ofType: modelFileInfo.fileExtension
        ) else {
            print("Failed to load the model file with name: \(modelFileInfo.name).")
            return nil
        }
        
        // Specify the options for the `Interpreter`.
        self.threadCount = threadCount
        var options = Interpreter.Options()
        options.threadCount = threadCount
        do {
            // Create the `Interpreter`.
            interpreter = try Interpreter(modelPath: modelPath, options: options)
            // Allocate memory for the model's input `Tensor`s.
            try interpreter.allocateTensors()
        } catch let error {
            print("Failed to create the interpreter with error: \(error.localizedDescription)")
            return nil
        }
        
        // Opens and loads the classes listed in labels file
        loadLabels(fromFileName: Model.labelsInfo.name, fileExtension: Model.labelsInfo.fileExtension)
    }
    
    // MARK: Methods for data preprocessing and post processing.
    /**
     Calls the TensorFlow Lite Interpreter methods
     to feed the input array into the input tensor and run inference
     on the pixel buffer.
     */
    func runModel(using inputArray: [Float]) -> InferenceResult? {
        
        let interval: TimeInterval
        let outputTensor: Tensor
        do {
            let inputData = Data(copyingBufferOf: inputArray)
            try interpreter.copy(inputData, toInputAt: 0)
            
            // Run inference by invoking the `Interpreter`.
            let startDate = Date()
            try interpreter.invoke()
            interval = Date().timeIntervalSince(startDate) * 1000
            
            // Get the output `Tensor` to process the inference results.
            outputTensor = try interpreter.output(at: 0)
        } catch let error {
            print("Failed to invoke the interpreter with error: \(error.localizedDescription)")
            return nil
        }
        
        let results: [Float]
        switch outputTensor.dataType {
        case .uInt8:
            guard let quantization = outputTensor.quantizationParameters else {
                print("No results returned because the quantization values for the output tensor are nil.")
                return nil
            }
            let quantizedResults = [UInt8](outputTensor.data)
            results = quantizedResults.map {
                quantization.scale * Float(Int($0) - quantization.zeroPoint)
            }
        case .float32:
            results = [Float32](unsafeData: outputTensor.data) ?? []
        default:
            print("Output tensor data type \(outputTensor.dataType) is unsupported for this example app.")
            return nil
        }
        
        // Process the results.
        let topNInferences = getTopN(results: results)
        
        // Return the inference time and inference results.
        return InferenceResult(inferenceTime: interval, inferences: topNInferences)
    }
    
    /// Returns the top N inference results sorted in descending order.
    private func getTopN(results: [Float]) -> [Inference] {
        // Create a zipped array of tuples [(labelIndex: Int, confidence: Float)].
        let zippedResults = zip(labels.indices, results)
        
        // Sort the zipped results by confidence value in descending order.
        let sortedResults = zippedResults.sorted { $0.1 > $1.1 }.prefix(resultCount)
        
        // Return the `Inference` results.
        return sortedResults.map { result in Inference(confidence: result.1, label: labels[result.0]) }
    }
    
    /**
     Loads the labels from the labels file and stores it in an instance variable
     */
    func loadLabels(fromFileName fileName: String, fileExtension: String) {
        
        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            fatalError("Labels file not found in bundle. Please add a labels file with name \(fileName).\(fileExtension) and try again")
        }
        do {
            let contents = try String(contentsOf: fileURL, encoding: .utf8)
            self.labels = contents.components(separatedBy: "\n")
            self.labels.removeAll { (label) -> Bool in
                return label == ""
            }
        }
        catch {
            fatalError("Labels file named \(fileName).\(fileExtension) cannot be read. Please add a valid labels file and try again.")
        }
        
    }
}

// MARK: - Extensions

extension Data {
    /// Creates a new buffer by copying the buffer pointer of the given array.
    ///
    /// - Warning: The given array's element type `T` must be trivial in that it can be copied bit
    ///     for bit with no indirection or reference-counting operations; otherwise, reinterpreting
    ///     data from the resulting buffer has undefined behavior.
    /// - Parameter array: An array with elements of type `T`.
    init<T>(copyingBufferOf array: [T]) {
        self = array.withUnsafeBufferPointer(Data.init)
    }
}

extension Array {
    /// Creates a new array from the bytes of the given unsafe data.
    ///
    /// - Warning: The array's `Element` type must be trivial in that it can be copied bit for bit
    ///     with no indirection or reference-counting operations; otherwise, copying the raw bytes in
    ///     the `unsafeData`'s buffer to a new array returns an unsafe copy.
    /// - Note: Returns `nil` if `unsafeData.count` is not a multiple of
    ///     `MemoryLayout<Element>.stride`.
    /// - Parameter unsafeData: The data containing the bytes to turn into an array.
    init?(unsafeData: Data) {
        guard unsafeData.count % MemoryLayout<Element>.stride == 0 else { return nil }
        self = unsafeData.withUnsafeBytes { .init($0.bindMemory(to: Element.self)) }
    }
}

