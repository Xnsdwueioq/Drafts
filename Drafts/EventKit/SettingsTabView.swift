//
//  SettingsTabView.swift
//  Drafts
//
//  Created by Eyhciurmrn Zmpodackrl on 19.03.2026.
//

import SwiftUI

struct SettingsTabView: View {
  // MARK: - Composition Root
  @State private var eventKitManager: EventKitManager
  
  @State private var eventsService: EventsService
  @State private var calendarService: CalendarService

  
  init(manager: EventKitManager = EventKitManager.shared) {
    self.eventKitManager = manager
    self._eventsService = State(initialValue: EventsService(eventStore: manager.eventStore))
    self._calendarService = State(initialValue: CalendarService(eventStore: manager.eventStore))
  }
  
  var body: some View {
    CalendarSyncContainer(
      eventsService: eventsService,
      calendarService: calendarService
    )
    .environment(eventsService)
    .environment(calendarService)
  }
}

#Preview {
  SettingsTabView()
}
