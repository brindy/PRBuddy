//
//  GithubPolling.swift
//  PRBuddy
//
//  Created by Chris Brind on 23/02/2018.
//  Copyright © 2018 DuckDuckGo, Inc. All rights reserved.
//

import Foundation
import Alamofire

class GithubPolling {
    
    struct Notifications {
        
        static let reviewsRequested = Notification.Name("GithubPolling.reviewsRequested")
        static let pollingStarted = Notification.Name("GithubPolling.pollingStarted")
        static let pollingFinished = Notification.Name("GithubPolling.pollingFinished")

    }
    
    struct GithubPullRequest: Decodable, Hashable, Equatable {
        
        struct User: Decodable {
            var login: String
            var avatar_url: String
        }
        
        var url: String
        var title: String
        var state: String
        var user: User
        var requested_reviewers: [User]

        var hashValue: Int {
            return url.hashValue
        }

        static func ==(lhs: GithubPolling.GithubPullRequest, rhs: GithubPolling.GithubPullRequest) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
        
    }
    
    struct GithubNotification: Decodable {
        
        struct Subject: Decodable {
            var title: String
            var url: String
            var type: String
        }
        
        struct Repository: Decodable {
            var name: String
            var full_name: String
        }
        
        var id: String
        var reason: String
        var subject: Subject
        var repository: Repository
        
    }
    
    var error: String?

    var allPullRequests = Set<GithubPullRequest>()
    var reviewsRequested: [GithubPullRequest] {
        let requests = allPullRequests.filter( { $0.requested_reviewers.contains(where: { $0.login == settings.username }) } )
        return Array<GithubPullRequest>(requests)
    }
    
    private let settings = AppSettings()
    private var timer:Timer?

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.onSettingsChanged), name: AppSettings.Notifications.changed, object: nil)
        start()
    }
    
    @objc func onSettingsChanged() {
        stop()
        start()
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    func start() {
        guard settings.username != nil, settings.personalAccessToken != nil else { return }
        timer = Timer(timeInterval: Double(settings.pollingTime) * 60.0, repeats: true) { timer in
            self.pollNow()
        }
    }
    
    func pollNow() {
        print(#function)
        error = nil
        allPullRequests = []
        firePollingStarted()
        loadNotifications()
        loadPullRequests()
    }
    
    func loadPullRequests() {

        for repo in settings.repos {
            let url = URL(string: "https://api.github.com/repos/\(repo)/pulls")!
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10.0)
            request.addValue(settings.basicAuthorization(), forHTTPHeaderField: "Authorization")

            Alamofire.request(request)
                .validate(statusCode: 200..<300)
                .responseData() { response in
                    guard let data = response.data, response.error == nil else {
                        self.error("Failed to retrieve notifications")
                        return
                    }
                    self.parsePullRequestList(data)
            }
            
        }
        
    }
    
    func loadNotifications() {
        let url = URL(string: "https://api.github.com/notifications")!
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10.0)
        request.addValue(settings.basicAuthorization(), forHTTPHeaderField: "Authorization")
        
        Alamofire.request(request)
            .validate(statusCode: 200..<300)
            .responseData() { response in
                guard let data = response.data, response.error == nil else {
                    self.error("Failed to retrieve notifications")
                    return
                }
                self.parseNotifications(data)
            }
        
    }
    
    func parseNotifications(_ data: Data) {
        
        guard let notifications = try? JSONDecoder().decode(Array<GithubNotification>.self, from: data) else {
            self.error("Failed to decode notifications")
            return
        }
        
        let reviewRequests = notifications.filter({ $0.reason == "review_requested" })
        
        guard reviewRequests.count > 0 else {
            firePollingFinished()
            return
        }
        
        let semaphore = DispatchSemaphore(value: reviewRequests.count)
        for notification in reviewRequests {
            let url = URL(string: notification.subject.url)!
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10.0)
            request.addValue(settings.basicAuthorization(), forHTTPHeaderField: "Authorization")

            Alamofire.request(request)
                .validate(statusCode: 200..<300)
                .responseData() { response in
                    semaphore.signal()
                    
                    guard let data = response.data, response.error == nil else {
                        self.error("Failed to retrieve pull request")
                        return
                    }
                    self.parsePullRequest(data)
            }
        }

        semaphore.wait()
        firePollingFinished()
    }
    
    func parsePullRequest(_ data: Data) {
        
        guard let pullRequest = try? JSONDecoder().decode(GithubPullRequest.self, from: data) else {
            error("Failed to decode pull request")
            return
        }
        
        if pullRequest.state != "closed" {
            allPullRequests.insert(pullRequest)
            fireReviewsRequested()
        }
    }

    func parsePullRequestList(_ data: Data) {
        
        guard let list = try? JSONDecoder().decode(Array<GithubPullRequest>.self, from: data) else {
            error("Failed to decode pull requestlist ")
            return
        }
        
        for pullRequest in list {
            if pullRequest.state != "closed" {
                allPullRequests.insert(pullRequest)
                fireReviewsRequested()
            }
        }
    }

    private func error(_ message: String) {
        error = message
    }
    
    private func fireReviewsRequested() {
        NotificationCenter.default.post(name: Notifications.reviewsRequested, object: nil)
    }

    private func firePollingStarted() {
        NotificationCenter.default.post(name: Notifications.pollingStarted, object: nil)
    }

    private func firePollingFinished() {
        NotificationCenter.default.post(name: Notifications.pollingFinished, object: nil)
    }

}

extension AppSettings {
    
    func basicAuthorization() -> String {
        let creds = "\(username ?? ""):\(personalAccessToken ?? "")"
        let base64 = creds.toBase64()
        let auth = "Basic \(base64)"
        return auth
    }
    
}

extension String {
    
    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }
    
}
