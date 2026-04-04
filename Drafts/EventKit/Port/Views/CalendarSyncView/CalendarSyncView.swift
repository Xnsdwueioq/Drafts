//
//  CalendarSyncView.swift
//  Drafts
//
//  Created by Eyhciurmrn Zmpodackrl on 04.04.2026.
//


import SwiftUI

struct CalendarSyncView: View {
  @Bindable var viewModel: CalendarSyncViewModel
  
  var body: some View {
    NavigationStack {
      List {
        Section("Apple Calendar") {
          Toggle("Синхронизация с календарем", isOn: $viewModel.isSynchronizeOn)
          if viewModel.isSynchronizeOn {
            Button(action: {
              viewModel.isCalendarSelected = true
            }, label: {
              HStack(spacing: 10) {
                Text("Календарь")
                Spacer()
                Circle()
                  .frame(width: 20, height: 20)
                  .foregroundStyle(viewModel.selectedCalendarColorView)
                Text(viewModel.selectedCalendarTitleView)
              }
              .animation(.snappy, value: viewModel.selectedCalendarColorView)
              .animation(.snappy, value: viewModel.selectedCalendarTitleView)
            })
            .tint(.primary)
            .onChange(of: viewModel.calendarsToDisplay) {
              viewModel.onCalendarsChangedAction()
            }
          }
        }
      }
      .animation(.snappy, value: viewModel.isSynchronizeOn)
    }
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
