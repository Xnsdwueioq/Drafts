//
//  CalendarsSheetView.swift
//  Drafts
//
//  Created by Eyhciurmrn Zmpodackrl on 04.04.2026.
//


import SwiftUI

struct CalendarsSheetView: View {
  @Bindable var viewModel: CalendarSyncViewModel
    
  var body: some View {
    List {
      // Кнопка добавления календаря
      Button(action: {
        viewModel.openCalendarCreationSheet()
      }, label: {
        HStack {
          Text("Добавить календарь")
          Spacer()
          Image(systemName: "plus")
            .foregroundStyle(.secondary)
        }
        .tint(.primary)
      })
      .disabled(!viewModel.hasFullAccess)
      
      // Список календарей
      Picker(selection: $viewModel.pickedCalendarID, content: {
        ForEach(viewModel.calendarsToDisplay) { calendar in
          HStack(spacing: 10) {
            Circle()
              .frame(width: 20, height: 20)
              .foregroundStyle(Color(cgColor: calendar.color))
            Text(calendar.title)
            Spacer()
          }
          .tag(calendar.id)
        }
      }, label: { EmptyView() })
      .pickerStyle(.inline)
      
      // Заглушка при отсутствии доступа
      if !viewModel.hasFullAccess {
        ContentUnavailableView("Нет доступа", systemImage: "calendar.badge.exclamationmark", description: Text("Предоставьте полный доступ к Apple Calendar в настройках приложения"))
      }
      
      // Заглушка при пустом списке
      if viewModel.hasFullAccess && viewModel.calendarsToDisplay.isEmpty {
        ContentUnavailableView("Список пуст", systemImage: "tray.fill", description: Text("Не найдено ни одного доступного календаря. Добавьте новый"))
      }
    }
  }
}