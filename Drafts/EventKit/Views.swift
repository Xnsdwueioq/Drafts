//
//  Views.swift
//  Drafts
//
//  Created by Eyhciurmrn Zmpodackrl on 18.03.2026.
//

import SwiftUI
import EventKit

struct EventViewContainer: View {
  @State private var viewModel: SettingsTabViewModel
  
  init(
    eventsService: EventsService,
    calendarService: CalendarService
  ) {
    self._viewModel = State(initialValue: SettingsTabViewModel(
      eventsService: eventsService,
      calendarService: calendarService
    ))
  }
  
  var body: some View {
    EventView(viewModel: viewModel)
  }
}

struct EventView: View {
  @Bindable var viewModel: SettingsTabViewModel
  
  var body: some View {
    NavigationStack {
      List {
        Section {
          DatePicker("Start Date", selection: $viewModel.startTime)
          DatePicker("End Date", selection: $viewModel.endTime)
          
          Button("Add Event") {
            viewModel.addEvenButton()
          }
        }
        
        Section {
          Toggle("Синхронизация с Apple Calendar", isOn: $viewModel.isSynchronizeOn)
          if viewModel.isSynchronizeOn {
            Button(action: {
              viewModel.isCalendarSelected = true
            }, label: {
              HStack(spacing: 10) {
                // TODO: [BUG] После выбора календаря, 2 итерации "выкл->вкл" на мгновение появляется прошлый выбранный календарь
                Text("Календарь")
                Spacer()
                Circle()
                  .frame(width: 20, height: 20)
                  .foregroundStyle(Color(cgColor: viewModel.selectedCalendarItem.color))
                Text(viewModel.selectedCalendarItem.title)
              }
              .animation(.easeInOut(duration: 0.3), value: viewModel.selectedCalendarItem.id)
            })
            .tint(.primary)
          }
        }
      }
      .animation(.snappy, value: viewModel.isSynchronizeOn)
    }
    .alert("Нет доступа к календарю",
           isPresented: $viewModel.isAlertPresent,
           actions: {
      Button("Перейти в настройки", role: .confirm) {
        Task {
          await viewModel.openSettings()
        }
      }
      Button("Ок", role: .close) { }
    },
           message: { Text("Перейдите в настройки и разрешите полный доступ") }
    )
    .sheet(
      isPresented: $viewModel.isCalendarSelected,
      onDismiss: viewModel.onDismissCalendarSelected
    ) {
      CalendarsSheetView(viewModel: viewModel)
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium, .large])
    }
    .sheet(
      isPresented: $viewModel.isCalendarCreated,
      onDismiss: viewModel.onDismissCalendarCreated
    ) {
      CalendarCreationSheetView(
        newCalendarTitle: $viewModel.newCalendarTitle,
        newCalendarColor: $viewModel.newCalendarColor,
        creationCalendarAction: viewModel.creationCalendarAction,
        isNewCalendarTitleValidate: viewModel.isNewCalendarTitleValidate
      )
        .presentationDragIndicator(.visible)
        .presentationDetents([.medium, .large])
    }
  }
}

struct CalendarsSheetView: View {
  @Bindable var viewModel: SettingsTabViewModel
    
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
      .disabled(viewModel.calendarsToDisplay.isEmpty)
      
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
      if viewModel.calendarsToDisplay.isEmpty {
        ContentUnavailableView("Нет доступа", systemImage: "calendar.badge.exclamationmark", description: Text("Предоставьте полный доступ к Apple Calendar в настройках приложения"))
      }
    }
  }
}

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

#Preview {
  MockApp()
}
