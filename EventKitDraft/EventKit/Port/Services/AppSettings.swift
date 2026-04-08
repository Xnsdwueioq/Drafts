//
//  AppSettings.swift
//  Drafts
//
//  Created by Eyhciurmrn Zmpodackrl on 04.04.2026.
//


import Foundation

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
