//
//  Services.swift
//  Drafts
//
//  Created by Eyhciurmrn Zmpodackrl on 18.03.2026.
//

import Foundation
import EventKit
import SwiftUI

// MARK: - Model

final class PeriodInterval {
  var startTime: Date
  var endTime: Date?
  var calendarEventID: String?
  
  var duration: TimeInterval {
    startTime.distance(to: endTime ?? Date())
  }
  
  init(startTime: Date = Date(), endTime: Date? = nil, calendarEventID: String? = nil) {
    self.startTime = startTime
    self.endTime = endTime
    self.calendarEventID = calendarEventID
  }
}


// MARK: - Settings Service

@Observable
final class AppSettings {
  static let shared = AppSettings()
  
  private init() {}
  
  // связь с settingsManager через вычисляемые свойства
  var synchronizeCalendar: Bool = false
  var selectedCalendar: CalendarItem?
}


// MARK: - EventKit Service

@Observable
final class EventKitManager {
  static let shared = EventKitManager()
  let eventStore = EKEventStore()
  
  private init() {}
  
  // MARK: - Access
  var authrorizationStatus: EKAuthorizationStatus {
    EKEventStore.authorizationStatus(for: .event)
  }
  
  func requestAccess() async throws -> Bool {
    return try await eventStore.requestFullAccessToEvents()
  }
}

// MARK: - Events Service

@Observable
final class EventsService {
  let eventStore: EKEventStore
  
  init(eventStore: EKEventStore) {
    self.eventStore = eventStore
  }
  
  func addEvent(event name: String, with startTime: Date, and endTime: Date) {
    let event = EKEvent(eventStore: self.eventStore)
    event.title = name
    event.startDate = startTime
    event.endDate = endTime
    event.calendar = self.eventStore.defaultCalendarForNewEvents
    
    do {
      try self.eventStore.save(event, span: .thisEvent)
    } catch {
      print("Save Error: \(error.localizedDescription)")
    }
  }
}

// MARK: - Calendar Service

@Observable
final class CalendarService {
  let eventStore: EKEventStore
  
  private(set) var availableCalendars: [CalendarItem] = []
  private var calendarChangeObserver: Any?
  
  // Выборка календарей
  var defaultCalendar: EKCalendar? {
    eventStore.defaultCalendarForNewEvents
  }
  var anyCalendar: EKCalendar? {
    eventStore.calendars(for: .event).first
  }
  
  init(eventStore: EKEventStore) {
    self.eventStore = eventStore
    
    fetchAvailableCalendars()

    // Наблюдатель за изменениями календарей, вызывает их подгрузку
    self.calendarChangeObserver = NotificationCenter.default.addObserver(
      forName: .EKEventStoreChanged,
      object: eventStore,
      queue: .main,
      using: { [weak self] _ in
        self?.fetchAvailableCalendars()
      }
    )
  }
  
  deinit {
    // Удаление токена
    if let observer = calendarChangeObserver {
      NotificationCenter.default.removeObserver(observer)
    }
  }
  
  // MARK: - Calendars Fetching
  
  private func getAllowModificationsCalendars() -> [EKCalendar] {
    return eventStore.calendars(for: .event).filter {
      $0.allowsContentModifications }
  }
  
  func fetchAvailableCalendars() {
    let rawCalendars = getAllowModificationsCalendars()
    let calendars = rawCalendars.map { CalendarItem(from: $0) }
    
    self.availableCalendars = calendars
  }
  
  // MARK: - Calendar Creating
  
  private func findBestSource(in store: EKEventStore) -> EKSource? {
    if let icloud = store.sources.first(where: { $0.sourceType == .calDAV && $0.title.lowercased() == "icloud" }) {
      return icloud
    } else {
      return store.sources.first(where: { $0.sourceType == .local })
    }
  }
  
  func createCalendar(title: String, color: Color) -> String? {
    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedTitle.isEmpty else {
        print("The calendar was not created. Invalid name: '\(title)'")
        return nil
    }
    
    let calendar = EKCalendar(for: .event, eventStore: eventStore)
    
    calendar.title = title
    calendar.cgColor = color.resolve(in: EnvironmentValues()).cgColor
    calendar.source = findBestSource(in: eventStore)
    
    if let source = findBestSource(in: eventStore) {
      calendar.source = source
      try? eventStore.saveCalendar(calendar, commit: true)
      print("Calendar was created with title '\(calendar.title)', color '\(calendar.cgColor.debugDescription)', source '\(calendar.source.debugDescription)'")
      return calendar.calendarIdentifier
    } else {
      print("Calendar was not created")
      return nil
    }
  }
  
  // MARK: - Calendar Selecting
  
  func findCalendar(with id: String) -> EKCalendar? {
    let selectedCalendar = eventStore.calendar(withIdentifier: id)
    
    return selectedCalendar
  }
}

// MARK: - Settings View Model

@Observable
final class SettingsTabViewModel {
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
  }
  
  // DEBUG
  var startTime: Date = Date()
  var endTime: Date = Date().advanced(by: 3600)
  
  // MARK: - Additional Screens Logic
  
  var isAlertPresent = false
  
  var isCalendarSelected = false
  func onDismissCalendarSelected() {
    
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
      guard let newId = newValue else {
        return
      }
      pickCalendar(with: newId)
    }
  }
  
  var pickedCalendarHash: Int {
    guard let pickedID = pickedCalendarID,
          let pickedEKCalendar = calendarService.findCalendar(with: pickedID)
    else {
      return 0
    }
    let pickedCalendar = CalendarItem(from: pickedEKCalendar)
    
    var hasher = Hasher()
    hasher.combine(pickedCalendar.id)
    hasher.combine(pickedCalendar.title)
    hasher.combine(pickedCalendar.color)
    hasher.combine(pickedCalendar.source.title)
    let hash = hasher.finalize()
    
    return hash
  }
  
  var selectedCalendarColorView: Color {
    guard let selectedCalendar = appSettings.selectedCalendar else {
      return Color.white
    }
    return Color(cgColor: selectedCalendar.color)
  }
  
  var selectedCalendarTitleView: String {
    guard let selectedCalendar = appSettings.selectedCalendar else {
      return "Не выбран"
    }
    return selectedCalendar.title
  }
  
  func onHashChangeAction() {
    guard let currentId = pickedCalendarID else {
      return
    }
    pickCalendar(with: currentId)
  }
  
  private func pickCalendar(with id: String) {
    guard let selectedCalendar = calendarService.findCalendar(with: id) else {
      appSettings.selectedCalendar = nil
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
    
  // TODO: Fix event addition
  func addEvenButton() {
    if appSettings.synchronizeCalendar {
      eventsService.addEvent(event: "Test", with: startTime, and: endTime)
    }
  }
}

struct CalendarItem: Identifiable {
  let id: String
  let color: CGColor
  let title: String
  let source: EKSource
  
  init(from ekCalendar: EKCalendar) {
    self.id = ekCalendar.calendarIdentifier
    self.color = ekCalendar.cgColor
    self.title = ekCalendar.title
    self.source = ekCalendar.source
  }
}
