//
//  CalendarService.swift
//  Drafts
//
//  Created by Eyhciurmrn Zmpodackrl on 04.04.2026.
//


import Foundation
import EventKit
import SwiftUI

@Observable
final class CalendarService {
  let eventStore: EKEventStore
  
  private(set) var availableCalendars: [CalendarItem] = []
  private var calendarChangeObserver: Any?
  
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
