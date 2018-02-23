//
//  AppSettings.swift
//  PRBuddy
//
//  Created by Chris Brind on 23/02/2018.
//  Copyright © 2018 DuckDuckGo, Inc. All rights reserved.
//

import Foundation

class AppSettings {
    
    struct Defaults {
        
        static let reviewRequested = "👋"
        static let noPRs = "💤"
        static let pollingTime = 1
        
    }
    
    struct Keys {
        
        static let username = "username"
        static let personalAccessToken = "personalAccessToken"
        static let reviewRequested = "reviewRequested"
        static let noPRs = "noPRs"
        static let pollingTime = "pollingTime"
        
    }
    
    struct Notifications {
        
        static let changed = NSNotification.Name(rawValue: "AppSettings.Changed")
        
    }

    private var userDefaults: UserDefaults = UserDefaults.standard
    
    var reviewRequested: String {
        get {
            return userDefaults.string(forKey: Keys.reviewRequested) ?? Defaults.reviewRequested
        }
        set {
            userDefaults.set(newValue, forKey: Keys.reviewRequested)
            fireChanged()
        }
    }
    
    var noPRs: String {
        get {
            return userDefaults.string(forKey: Keys.noPRs) ?? Defaults.noPRs
        }
        set {
            userDefaults.set(newValue, forKey: Keys.noPRs)
            fireChanged()
        }
    }
    
    var pollingTime: Int {
        get {
            return userDefaults.object(forKey: Keys.pollingTime) != nil ? userDefaults.integer(forKey: Keys.pollingTime) : Defaults.pollingTime
        }
        set {
            userDefaults.set(newValue, forKey: Keys.pollingTime)
            fireChanged()
        }
    }
    
    var username: String? {
        get {
            return userDefaults.string(forKey: Keys.username)
        }
        set {
            userDefaults.set(newValue == "" ? nil : newValue, forKey: Keys.username)
            fireChanged()
        }
    }
    
    var personalAccessToken: String? {
        get {
            return userDefaults.string(forKey: Keys.personalAccessToken)
        }
        set {
            userDefaults.set(newValue == "" ? nil : newValue, forKey: Keys.personalAccessToken)
            fireChanged()
        }
    }
    
    private func fireChanged() {
        NotificationCenter.default.post(name: Notifications.changed, object: nil)
    }
    
}
