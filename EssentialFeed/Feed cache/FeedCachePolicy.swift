//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by soujanya Balusu on 31/10/24.
//

import Foundation

internal final class FeedCachePolicy {

    private init() {}

    private static let calender = Calendar(identifier: .gregorian)

    private static var maxCacheAgeDays: Int {
        return 7
    }


    internal  static  func validate(_ timestamp: Date, against date:  Date) -> Bool {
        guard  let maxCacheAge = calender.date(byAdding: .day, value: maxCacheAgeDays, to: timestamp) else {
            return false
        }
        return date < maxCacheAge
    }
}
