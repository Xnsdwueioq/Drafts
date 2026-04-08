//
//  CalendarSyncContainer.swift
//  Drafts
//
//  Created by Eyhciurmrn Zmpodackrl on 04.04.2026.
//

import SwiftUI
import EventKit

struct CalendarSyncContainer: View {
  @State private var viewModel: CalendarSyncViewModel
  
  init(
//    eventsService: EventsService,
    calendarService: CalendarService
  ) {
    self._viewModel = State(initialValue: CalendarSyncViewModel(
//      eventsService: eventsService,
      calendarService: calendarService
    ))
  }
  
  var body: some View {
    CalendarSyncView(viewModel: viewModel)
      .onAppear {
        viewModel.checkAuthorisationStatus()
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
      .alert("Календарь не выбран",
             isPresented: $viewModel.isCalendarNilPresent,
             actions: {
        Button("Выбрать календарь", role: .cancel) { viewModel.openCalendarSelectionSheet() }
        Button("Выключить синхронизацию", role: .destructive) { viewModel.isSynchronizeOn = false }
      },
             message: { Text("Выберите новый календарь для возможности синхронизации с Apple Calendar") }
      )
  }
}
