//
//  EventKitManager.swift
//  Drafts
//
//  Created by Eyhciurmrn Zmpodackrl on 04.04.2026.
//


import Foundation
import EventKit

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
