//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by soujanya Balusu on 28/10/24.
//

import Foundation

public typealias CachedFeed  = (feed: [LocalFeedImage], timestamp: Date)

public protocol FeedStore {
    typealias DeleteResult = Error?
    typealias DeletionCompletion = (Error?) -> (Void)

    typealias InsertResult = Error?
    typealias InsertionCompletion = (Error?) -> (Void)

    typealias RetrievalResult  = Result<CachedFeed?, Error>
    typealias RetrievalCompletion = (RetrievalResult) -> (Void)

    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    func deleteCachedFeed(completion: @escaping DeletionCompletion)

    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    func insert (_ Feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)

    /// The completion handler can be invoked in any thread.
    /// Clients are responsible to dispatch to appropriate threads, if needed.
    func retrieve(completion: @escaping RetrievalCompletion)
}
