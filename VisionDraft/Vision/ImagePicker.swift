//
//  ImagePicker.swift
//  VisionDraft
//
//  Created by Eyhciurmrn Zmpodackrl on 07.04.2026.
//

import Foundation
import UIKit
import SwiftUI


enum ImagePickerSourceType {
  case camera
  case photoLibrary
}

struct ImagePicker: UIViewControllerRepresentable {
  @Binding var image: UIImage?
  var pickerSourceType: ImagePickerSourceType
  var onImagePicked: (UIImage) -> Void
  
  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.delegate = context.coordinator

    switch pickerSourceType {
    case .camera:
      if UIImagePickerController.isSourceTypeAvailable(.camera) {
        picker.sourceType = .camera
      } else {
        picker.sourceType = .photoLibrary
      }
    case .photoLibrary:
      picker.sourceType = .photoLibrary
    }
    
    return picker
  }
  
  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    let parent: ImagePicker
    
    init(_ parent: ImagePicker) {
      self.parent = parent
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
      if let uiImage = info[.originalImage] as? UIImage {
        parent.image = uiImage
        parent.onImagePicked(uiImage)
      }
      picker.dismiss(animated: true)
    }
  }
}
