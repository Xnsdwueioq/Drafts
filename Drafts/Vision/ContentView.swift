//
//  ContentView.swift
//  Drafts
//
//  Created by Eyhciurmrn Zmpodackrl on 07.04.2026.
//

import SwiftUI

struct ContentView: View {
  @State private var detector = PoseDetector()
  @State private var showCamera = false
  @State private var imageSource = ImagePickerSourceType.camera
  
  var body: some View {
    VStack {
      if let image = detector.image {
        ZStack {
          Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .overlay {
              GeometryReader { geometry in
                PoseOverlayView(points: detector.detectedPoints, size: geometry.size)
              }
            }
        }
        .frame(maxHeight: 500)
      } else {
        ContentUnavailableView("Нет фото", systemImage: "person.and.background.dotted", description: Text("Сделайте фото или выберите из галереи"))
      }
    }
    .toolbar {
      ToolbarItem(placement: .bottomBar) {
        Button(action: {
          imageSource = .camera
          showCamera = true
        }, label: {
          Image(systemName: "camera.circle.fill")
            .resizable()
            .scaledToFit()
            .padding()
            .frame(width: 60, height: 60)
        })
      }
      ToolbarItem(placement: .bottomBar) {
        Button(action: {
          imageSource = .photoLibrary
          showCamera = true
        }, label: {
          Image(systemName: "photo.stack")
            .resizable()
            .scaledToFit()
            .padding()
            .frame(width: 60, height: 60)
        })
      }
    }
    .sheet(
      isPresented: $showCamera,
      content: {
        ImagePicker(
          image: $detector.image,
          pickerSourceType: imageSource
        ) { selectedImage in
          detector.detectPose(in: selectedImage)
        }
        .id(imageSource)
        .ignoresSafeArea()
      }
    )
    .tint(.teal)
  }
}

#Preview {
  ContentView()
}
