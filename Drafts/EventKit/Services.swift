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
  private let local = UserDefaults.standard
  
  private init() {
    self._synchronizeCalendar = local.bool(forKey: SettingKey.synchronizeCalendar.rawValue)
    self._selectedCalendar = {
      guard let data = local.data(forKey: SettingKey.selectedCalendar.rawValue) else {
        print("No data found in UserDefaults for 'selected_calendar' key")
        return nil
      }
      let decoder = JSONDecoder()
      do {
        return try decoder.decode(CalendarItem.self, from: data)
      } catch {
        print("Decoding error: \(error.localizedDescription)")
        return nil
      }
    }()
  }
  
  // TODO: связь с settingsManager через вычисляемые свойства
  var synchronizeCalendar: Bool {
    didSet {
      local.set(synchronizeCalendar, forKey: SettingKey.synchronizeCalendar.rawValue)
    }
  }
  var selectedCalendar: CalendarItem? {
    didSet {
      print("[AppSettings][selectedCalendar] didSet was called \(Date())")
      guard oldValue != selectedCalendar else {
        print("[AppSettings][selectedCalendar] selected calendar has not changed. Exiting didSet closure")
        return
      }
      let encoder = JSONEncoder()
      if let data = try? encoder.encode(selectedCalendar) {
        local.set(data, forKey: SettingKey.selectedCalendar.rawValue)
      } else {
        local.removeObject(forKey: SettingKey.selectedCalendar.rawValue)
      }
    }
  }
  
  enum SettingKey: String {
    case synchronizeCalendar = "synchronize_calendar"
    case selectedCalendar = "selected_calendar"
  }
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
  
  func addEvent(event name: String, start startDate: Date, end endDate: Date, calendar calendarItem: CalendarItem) {
    guard let calendar = eventStore.calendar(withIdentifier: calendarItem.id) else {
      print("The event wasn not added. Could not find EKCalendar by identifier from CalendarItem")
      return
    }
    let event = EKEvent(eventStore: self.eventStore)
    event.title = name
    event.startDate = startDate
    event.endDate = endDate
    event.calendar = calendar
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
    print("fetchAvailableCalendars was called")
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

struct CalendarItem: Identifiable, Hashable, Codable {
  let id: String
  let color: CGColor
  let title: String
  let sourceTitle: String
  
  init(from ekCalendar: EKCalendar) {
    self.id = ekCalendar.calendarIdentifier
    self.color = ekCalendar.cgColor
    self.title = ekCalendar.title
    self.sourceTitle = ekCalendar.source.title
  }
  
  // MARK: - Encoding and Decoding
  
  enum CodingKeys: String, CodingKey {
    case id
    case color
    case title
    case sourceTitle
  }
  
  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    self.id = try container.decode(String.self, forKey: .id)
    
    let codableCGColor = try container.decode(CodableCGColor.self, forKey: .color)
    self.color = codableCGColor.cgColor
    
    self.title = try container.decode(String.self, forKey: .title)
    self.sourceTitle = try container.decode(String.self, forKey: .sourceTitle)
  }
  
  func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    let codableCGColor = CodableCGColor(from: self.color)
    
    try container.encode(self.id, forKey: .id)
    try container.encode(codableCGColor, forKey: .color)
    try container.encode(self.title, forKey: .title)
    try container.encode(self.sourceTitle, forKey: .sourceTitle)
  }
  
  // Hash function
  func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
    hasher.combine(self.title)
    hasher.combine(self.color)
    hasher.combine(self.sourceTitle)
  }
  
  // Structure for encoding CGColor
  struct CodableCGColor: Codable {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat
    
    init(from color: CGColor) {
      let components = color.components ?? [0, 0, 0, 0]
      self.red = components[0]
      self.green = components[1]
      self.blue = components[2]
      self.alpha = components[3]
    }
    
    var cgColor: CGColor {
      CGColor(red: red, green: green, blue: blue, alpha: alpha)
    }
  }
}
