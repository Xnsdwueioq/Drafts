//
//  PeriodInterval.swift
//  Drafts
//
//  Created by Eyhciurmrn Zmpodackrl on 04.04.2026.
//


import Foundation

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
