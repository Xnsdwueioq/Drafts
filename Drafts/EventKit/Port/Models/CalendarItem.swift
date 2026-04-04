//
//  CalendarItem.swift
//  Drafts
//
//  Created by Eyhciurmrn Zmpodackrl on 04.04.2026.
//


import Foundation
import EventKit

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
