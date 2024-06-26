//
//  AI.swift
//  simple-search
//
//  Created by Wayne Carter on 5/18/24.
//

import UIKit
import Vision

struct AI {
    static let shared = AI()
    private init() {}
    
    // MARK: - Embedding
    
    func embedding(for image: UIImage, attention: Attention = .none) -> [NSNumber]? {
        guard let cgImage = image.cgImage else {
            return nil
        }
        
        // Process the input image
        let processedCgImage = process(cgImage: cgImage, attention: attention)
        
        // Return the embeddings
        let embedding = embedding(for: processedCgImage)
        return embedding
    }
        
    private func embedding(for cgImage: CGImage) -> [NSNumber]? {
        // Perform saliency detection
        let request = VNGenerateImageFeaturePrintRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
        } catch {
            return nil
        }
        
        guard let observation = request.results?.first as? VNFeaturePrintObservation else {
            return nil
        }

        // Access the feature print data
        let data = observation.data
        guard data.isEmpty == false else {
            return nil
        }

        // Determine the element type and size
        let elementType = observation.elementType
        let elementCount = observation.elementCount
        let typeSize = VNElementTypeSize(elementType)
        var embedding: [NSNumber]?
        
        // Handle the different element types
        switch elementType {
        case .float where typeSize == MemoryLayout<Float>.size:
            data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
                let buffer = bytes.bindMemory(to: Float.self)
                if buffer.count == elementCount {
                    embedding = buffer.map { NSNumber(value: $0) }
                }
            }
        case .double where typeSize == MemoryLayout<Double>.size:
            data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
                let buffer = bytes.bindMemory(to: Double.self)
                if buffer.count == elementCount {
                    embedding = buffer.map { NSNumber(value: $0) }
                }
            }
        default:
            print("Unsupported VNElementType: \(elementType)")
            return nil
        }

        return embedding
    }
    
    // MARK: - Barcode
    
    func barcode(from image: UIImage) -> String? {
        guard let cgImage = image.cgImage else {
            return nil
        }
        
        let barcode = barcode(from: cgImage)
        return barcode
    }
    
    private func barcode(from cgImage: CGImage) -> String? {
        // Perform barcode detection
        let request = VNDetectBarcodesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
        } catch {
            return nil
        }
        
        guard let results = request.results else {
            return nil
        }
        
        if let payloadString = results.first(where: { $0.payloadStringValue != nil })?.payloadStringValue {
            return payloadString
        }
        
        return nil
    }
    
    // MARK: - Image Processing
    
    enum Attention {
        case none, saliency
    }
    
    func process(cgImage: CGImage, attention: Attention) -> CGImage {
        var processedImage = cgImage
        
        switch attention {
        case .none:
            _ = processedImage // No attention, do nothing.
        case .saliency:
            processedImage = cropToSalientRegion(cgImage: cgImage)
        }
        
        processedImage = fit(cgImage: processedImage, to: CGSize(width: 100, height: 100))
        
        return processedImage
    }
    
    private func cropToSalientRegion(cgImage: CGImage) -> CGImage {
        // Perform saliency detection
        let request = VNGenerateObjectnessBasedSaliencyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
        } catch {
            return cgImage
        }

        // Get the salient objects
        guard let observation = request.results?.first as? VNSaliencyImageObservation,
              let salientObject = observation.salientObjects?.first else
        {
            // No salient object detected, crop to the center square
            let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
            let sideLength = min(imageSize.width, imageSize.height)
            let centerRect = CGRect(
                x: (imageSize.width - sideLength) / 2,
                y: (imageSize.height - sideLength) / 2,
                width: sideLength,
                height: sideLength
            )
            
            return cgImage.cropping(to: centerRect) ?? cgImage
        }

        // Get the bounding box of the salient object and convert the bounding box
        // from Vision normalized coordinates to CoreGraphics coordinates
        let boundingBox = salientObject.boundingBox
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        var salientRect = CGRect(
            x: boundingBox.origin.x * imageSize.width,
            y: (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height,
            width: boundingBox.width * imageSize.width,
            height: boundingBox.height * imageSize.height
        )
        // Outset by a margin making the rect slightly larger
        salientRect = salientRect.insetBy(dx: -16, dy: -16)

        // Crop the image to the salient region
        return cgImage.cropping(to: salientRect) ?? cgImage
    }
    
    private func fit(cgImage: CGImage, to targetSize: CGSize) -> CGImage {
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        
        // Calculate the aspect ratios
        let widthRatio = targetSize.width / imageSize.width
        let heightRatio = targetSize.height / imageSize.height
        let scaleFactor = min(widthRatio, heightRatio)

        let scaledWidth = imageSize.width * scaleFactor
        let scaledHeight = imageSize.height * scaleFactor
        let offsetX = (targetSize.width - scaledWidth) / 2.0 // Center horizontally
        let offsetY = (targetSize.height - scaledHeight) / 2.0 // Center vertically
        let scaledRect = CGRect(x: offsetX, y: offsetY, width: scaledWidth, height: scaledHeight)

        let rendererFormat = UIGraphicsImageRendererFormat.default()
        rendererFormat.scale = 1 // Use a scale factor of 1 for CGImage

        let renderer = UIGraphicsImageRenderer(size: targetSize, format: rendererFormat)
        let fitImage = renderer.image { _ in
            UIImage(cgImage: cgImage).draw(in: scaledRect)
        }
        
        guard let fitImage = fitImage.cgImage else {
            return cgImage
        }
        
        return fitImage
    }
}
