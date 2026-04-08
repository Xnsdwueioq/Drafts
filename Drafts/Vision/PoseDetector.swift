//
//  PoseDetector.swift
//  Drafts
//
//  Created by Eyhciurmrn Zmpodackrl on 07.04.2026.
//

import Foundation
import SwiftUI
import Vision

@Observable
final class PoseDetector {
  var image: UIImage?
  var detectedPoints: [CGPoint] = []
  
  func detectPose(in image: UIImage) {
    self.image = image
    
    guard let cgImage = image.cgImage else {
      print("Can`t convert UIImage to CGImage")
      return
    }
    
    let request = VNDetectHumanBodyPoseRequest()
    let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
    
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        try handler.perform([request])
        guard let observation = request.results?.first else {
          print("Observation results is empty")
          return
        }
        
        let allJoints = try observation.recognizedPoints(.all)
        
        let points = allJoints.values
          .filter { $0.confidence > 0.3 }
          .map { point in
            let x = point.location.x
            let y = point.location.y
            
            return CGPoint(x: x, y: 1 - y)
          }
        
        DispatchQueue.main.async {
          self.detectedPoints = points
        }
        
      } catch {
        print("Ошибка Vision \(error.localizedDescription)")
      }
    }
  }
}
