//
//  SignInferenceService.swift
//  iOS-ToolKit
//
//  Created by Srivinayak Chaitanya Eshwa on 11/09/24.
//

import UIKit
import Accelerate
import TensorFlowLite

/**
 This class handles all data preprocessing and makes calls to run inference on
 a given frame through the TensorFlow Lite Interpreter. It then formats the
 inferences obtained and returns the top N results for a successful inference.
 */
final class SignInferenceService {
    
    
    // MARK: Instance Variables
    /// The current thread count used by the TensorFlow Lite Interpreter.
    let threadCount: Int
    
    private var labels: [String] = []
    
    private let resultCount = 1
    private let threshold = 0.5
    
    /// TensorFlow Lite `Interpreter` object for performing inference on a given model.
    private var interpreter: Interpreter
    
    // MARK: Initializer
    /**
     This is a failable initializer for ModelDataHandler. It successfully initializes an object of the class if the model file and labels file is found, labels can be loaded and the interpreter of TensorflowLite can be initialized successfully.
     */
    init(settings: SignInferenceSettings) throws {
        // TODO: Convert to try catch
        // Construct the path to the model file.
        guard let modelPath = settings.modelPath.resourcePathString else {
            throw PathError.signInference
        }
        
        // Specify the options for the `Interpreter`.
        self.threadCount = settings.threadCount
        var options = Interpreter.Options()
        options.threadCount = threadCount
        do {
            // Create the `Interpreter`.
            interpreter = try Interpreter(modelPath: modelPath, options: options)
            // Allocate memory for the model's input `Tensor`s.
            try interpreter.allocateTensors()
        } catch let error {
            throw PassAlongError.tensorFlow(message: "Failed to create the interpreter with error: \(error.localizedDescription)")
        }
        
        // Opens and loads the classes listed in labels file
        try loadLabels(from: settings.labelsPath)
    }
    
    /**
     Calls the TensorFlow Lite Interpreter methods
     to feed the input array into the input tensor and run inference
     on the pixel buffer.
     */
    func runModel(using inputArray: [Float]) -> SignInferenceResult? {
        
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
        return SignInferenceResult(inferenceTime: interval, inferences: topNInferences)
    }
    
    /// Returns the top N inference results sorted in descending order.
    private func getTopN(results: [Float]) -> [SignInference] {
        // Create a zipped array of tuples [(labelIndex: Int, confidence: Float)].
        let zippedResults = zip(labels.indices, results)
        
        // Sort the zipped results by confidence value in descending order.
        let sortedResults = zippedResults.sorted { $0.1 > $1.1 }.prefix(resultCount)
        
        // Return the `Inference` results.
        return sortedResults.map { result in SignInference(confidence: result.1, label: labels[result.0]) }
    }
    
    /**
     Loads the labels from the labels file and stores it in an instance variable
     */
    func loadLabels(from labelsPath: AssetPath) throws {
        
        guard let labelsURL = labelsPath.url else {
            throw PathError.labels
        }
        
        do {
            let contents = try String(contentsOf: labelsURL, encoding: .utf8)
            self.labels = contents.components(separatedBy: "\n")
            self.labels.removeAll { (label) -> Bool in
                return label == ""
            }
        }
        catch {
            throw CorruptedFileError.labels(path: "\(labelsPath.name).\(labelsPath.fileExtension)")
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

