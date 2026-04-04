//
//  CalendarCreationSheetView.swift
//  Drafts
//
//  Created by Eyhciurmrn Zmpodackrl on 04.04.2026.
//


import SwiftUI

struct CalendarCreationSheetView: View {
  @Binding var newCalendarTitle: String
  @Binding var newCalendarColor: Color
  
  var creationCalendarAction: () -> ()
  var isNewCalendarTitleValidate: Bool
  
  @FocusState private var calendarTitleFocus: Bool
  
  var body: some View {
    NavigationStack {
      Form {
        TextField("Название", text: $newCalendarTitle, prompt: Text("Название"))
          .focused($calendarTitleFocus)
          .submitLabel(.done)
        ColorPicker("Цвет", selection: $newCalendarColor, supportsOpacity: false)
      }
      .toolbar {
        // CREATE button
        ToolbarItem(placement: .bottomBar) {
          Button("Create", systemImage: "plus", role: .confirm) {
            creationCalendarAction()
          }
          .tint(.accentColor) // TODO: CHANGE ACCENT COLOR TO BREND COLOR
          .controlSize(.extraLarge)
          .disabled(!isNewCalendarTitleValidate)
        }
      }
    }
    .navigationTitle("Создание календаря")
    .onAppear {
      calendarTitleFocus = true
    }
  }
}
