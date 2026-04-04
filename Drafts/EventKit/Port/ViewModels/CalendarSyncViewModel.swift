//
//  CalendarSyncViewModel.swift
//  Drafts
//
//  Created by Eyhciurmrn Zmpodackrl on 04.04.2026.
//


import Foundation
import EventKit
import SwiftUI

@Observable
final class CalendarSyncViewModel {
  private let appSettings: AppSettings
  
  private let eventKitManager: EventKitManager
  private let eventsService: EventsService
  private let calendarService: CalendarService
  
  var hasFullAccess: Bool {
    eventKitManager.authrorizationStatus == .fullAccess
  }
  
  var calendarsToDisplay: [CalendarItem] {
    calendarService.availableCalendars
  }
  
  init(
    appSettings: AppSettings = AppSettings.shared,
    eventKitManager: EventKitManager = EventKitManager.shared,
    eventsService: EventsService,
    calendarService: CalendarService
  ) {
    self.appSettings = appSettings
    self.eventKitManager = eventKitManager
    self.eventsService = eventsService
    self.calendarService = calendarService
    
    self._isSynchronizeOn = appSettings.synchronizeCalendar
    
    repickCalendar()
    processNilCalendar()
  }
  
  // DEBUG
  var startTime: Date = Date()
  var endTime: Date = Date().advanced(by: 3600)
  
  func checkAuthorisationStatus() {
    print("[SettingsTabViewModel][checkAuthorizationStatus] was called")
    if isSynchronizeOn && !hasFullAccess {
      isSynchronizeOn = false
      isAlertPresent = true
    }
  }
  
  func processNilCalendar() {
    if isSynchronizeOn && hasFullAccess && appSettings.selectedCalendar == nil {
      isCalendarNilPresent = true
    }
  }
  
  // MARK: - Additional Screens Logic
  
  var isAlertPresent = false
  
  var isCalendarNilPresent = false
  
  var isCalendarSelected = false
  
  func onDismissCalendarSelected() {
    if !isCalendarCreated && appSettings.selectedCalendar == nil {
      isSynchronizeOn = false
    }
  }
  
  func openCalendarSelectionSheet() {
    isCalendarSelected = true
  }
  
  var isCalendarCreated = false
  
  func onDismissCalendarCreated() {
    isCalendarSelected = true
  }
  
  func openCalendarCreationSheet() {
    isCalendarSelected = false
    isCalendarCreated = true
  }
  
  private func presentAlert(with status: Bool = false) {
    if !status {
      isAlertPresent = true
    }
  }
  
  func openSettings() async {
    if let url = URL(string: UIApplication.openSettingsURLString) {
      await UIApplication.shared.open(url)
    }
  }
  
  // MARK: - Calendar Creation
  
  var newCalendarTitle = ""
  var newCalendarColor = Color.accentColor // TODO: CHANGE ACCENT COLOR TO BREND COLOR
  var isNewCalendarTitleValidate: Bool {
    let trimmedTitle = newCalendarTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    return !trimmedTitle.isEmpty
  }
  
  private func resetNewCalendarData() {
    newCalendarTitle = ""
    newCalendarColor = Color.accentColor // TODO: CHANGE ACCENT COLOR TO BREND COLOR
  }
  
  func creationCalendarAction() {
    let createdCalendarId = calendarService.createCalendar(title: newCalendarTitle, color: newCalendarColor)
    isCalendarCreated = false
    isCalendarSelected = true
    resetNewCalendarData()
    
    if let createdCalendarId {
      pickCalendar(with: createdCalendarId)
    }
  }
  
  var isSynchronizeOn: Bool = false {
    didSet {
      if isSynchronizeOn == oldValue { return }
      if !isSynchronizeOn {
        appSettings.synchronizeCalendar = false
      } else {
        handleSyncTurnedOn()
      }
    }
  }
  
  // MARK: - Calendar Selection
  
  var pickedCalendarID: String? {
    get {
      appSettings.selectedCalendar?.id
    }
    set {
      guard let newId = newValue,
            newId != appSettings.selectedCalendar?.id else {
        return
      }
      pickCalendar(with: newId)
    }
  }
  
  var selectedCalendarColorView: Color {
    guard let selectedCalendar = appSettings.selectedCalendar else {
      return Color.white.opacity(0)
    }
    return Color(cgColor: selectedCalendar.color)
  }
  
  var selectedCalendarTitleView: String {
    guard let selectedCalendar = appSettings.selectedCalendar else {
      return "Не выбран"
    }
    return selectedCalendar.title
  }
  
  func onCalendarsChangedAction() {
    print("[SettingsTabViewModel][onCalendarsChangedAction] was called")
    guard let pickedCalendarID,
          let selectedEKCalendarActual = calendarService.findCalendar(with: pickedCalendarID),
          let selectedCalendar = appSettings.selectedCalendar else {
      return
    }
    
    let selectedCalendarActual = CalendarItem(from: selectedEKCalendarActual)
    if selectedCalendarActual.hashValue != selectedCalendar.hashValue {
      repickCalendar()
    }
  }
  
  func repickCalendar() {
    print("[SettingsTabViewModel][repickCalendar] was called")
    guard let currentId = pickedCalendarID else {
      return
    }
    pickCalendar(with: currentId)
  }
  
  private func pickCalendar(with id: String) {
    print("[SettingsTabViewModel][pickCalendar] was called")
    guard let selectedCalendar = calendarService.findCalendar(with: id) else {
      print("Can't select a calendar because it can't be found by calendarIdentifier via the CalendarService. AppSettings.selectedCalendar became equal to nil.")
      appSettings.selectedCalendar = nil
      
      processNilCalendar()

      return
    }
    appSettings.selectedCalendar = CalendarItem(from: selectedCalendar)
  }
  
  
  // MARK: - Sync Toggle Logic
  
  @MainActor
  private func handleSyncTurnedOn() {
    let status = eventKitManager.authrorizationStatus
    
    switch status {
    case .fullAccess:
      appSettings.synchronizeCalendar = true
      if appSettings.selectedCalendar == nil {
        isCalendarSelected = true
      }
      
    case .notDetermined:
      Task {
        do {
          let granted = try await eventKitManager.requestAccess()
          if granted {
            self.appSettings.synchronizeCalendar = true
            self.isSynchronizeOn = true
          } else {
            self.isSynchronizeOn = false
            presentAlert()
          }
        } catch {
          self.isSynchronizeOn = false
          print("Ошибка доступа: \(error.localizedDescription)")
        }
      }
      
    case .denied, .restricted, .writeOnly:
      self.isSynchronizeOn = false
      presentAlert()
      
    @unknown default:
      self.isSynchronizeOn = false
    }
  }
      
  func addEventAction() {
    if appSettings.synchronizeCalendar {
      guard let calendar = appSettings.selectedCalendar else {
        print("Event was not added. 'selectedCalendar' property equals nil")
        processNilCalendar()
        
        return
      }
      // DEBUG function
      eventsService.addEvent(event: "Test", start: startTime, end: endTime, calendar: calendar)
    }
  }
}
