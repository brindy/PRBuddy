//
//  GithubPolling.swift
//  PRBuddy
//
//  Created by Chris Brind on 23/02/2018.
//  Copyright © 2018 Chris Brind. All rights reserved.
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
        
        struct Commit: Decodable { // "head" or "base"
            
            struct Repo: Decodable {
                
                var name: String
                var ssh_url: String
                var clone_url: String
                
            }
            
            var label: String
            var ref: String
            var sha: String
            
            var repo: Repo
            
        }
        
        var url: String
        var html_url: String
        var title: String
        var state: String
        var user: User
        var requested_reviewers: [User]
        var assignees: [User]

        var head: Commit
        var base: Commit
        
        var hashValue: Int {
            return url.hashValue
        }

        static func ==(lhs: GithubPolling.GithubPullRequest, rhs: GithubPolling.GithubPullRequest) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
        
    }

    var error: String?

    var allPullRequests = Set<GithubPullRequest>()
    
    var reviewsRequested: [GithubPullRequest] {
        let requests = allPullRequests.filter( {
            $0.requested_reviewers.contains(where: { $0.login == settings.username }) &&
            !$0.assignees.contains(where: { $0.login == settings.username })
        } )
        return Array<GithubPullRequest>(requests)
    }
    
    var assigned: [GithubPullRequest] {
        let requests = allPullRequests.filter( { $0.assignees.contains(where: { $0.login == settings.username }) } )
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.timer = Timer.scheduledTimer(withTimeInterval: Double(self.settings.pollingTime) * 60.0, repeats: true) { timer in
                self.pollNow()
            }
        }
    }
    
    func pollNow() {
        print(#function)
        error = nil
        allPullRequests = []
        firePollingStarted()
        
        DispatchQueue.global(qos: .background).async {
            self.loadPullRequests()
        }
    }
    
    func loadPullRequests() {
        
        guard !settings.repos.isEmpty else {
            firePollingFinished()
            return
        }

        for repo in settings.repos {
            let url = URL(string: "https://api.github.com/repos/\(repo)/pulls")!
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10.0)
            request.addValue(settings.basicAuthorization(), forHTTPHeaderField: "Authorization")

            Alamofire.request(request)
                .validate(statusCode: 200..<300)
                .responseData() { response in
                    guard let data = response.data, response.error == nil else {
                        self.error("Failed to retrieve pull requests for \(repo).")
                        return
                    }
                    self.parsePullRequestList(data)
            }
            
            guard error == nil else { return }
            
        }
        
    }
    
    func parsePullRequestList(_ data: Data) {
        
        guard let list = try? JSONDecoder().decode(Array<GithubPullRequest>.self, from: data) else {
            error("Failed to parse pull request list JSON.")
            return
        }
        
        for pullRequest in list {
            if pullRequest.state != "closed" {
                allPullRequests.insert(pullRequest)
                fireReviewsRequested()
            }
        }

        firePollingFinished()
    }

    private func error(_ message: String) {
        guard error == nil else { return }
        print("ERROR: ", error as Any)
        error = message
        firePollingFinished()
    }
    
    private func fireReviewsRequested() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notifications.reviewsRequested, object: nil)
        }
    }

    private func firePollingStarted() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notifications.pollingStarted, object: nil)
        }
    }

    private func firePollingFinished() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notifications.pollingFinished, object: nil)
        }
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
