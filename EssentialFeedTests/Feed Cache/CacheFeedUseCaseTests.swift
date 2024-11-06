//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by soujanya Balusu on 27/10/24.
//

import XCTest
import EssentialFeed

 class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotStoreUponCreation() {
        let (_ ,store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

     func test_save_requestsCacheDeletion() {
         let (sut,store) = makeSUT()

         sut.save(uniqueImageFeed().models) { _ in } //give a default closure for now
         XCTAssertEqual(store.receivedMessages,[.deleteCachedFeed])
     }

     func test_save_doesNotRequestCacheInsertionOnDeletionError() {
         let (sut,store) = makeSUT()
         let deletionError = anyNSError()

         sut.save(uniqueImageFeed().models) { _ in }

         store.completionDeletion(with: deletionError)
         XCTAssertEqual(store.receivedMessages,[.deleteCachedFeed])
     }

     func test_save_requestsNewcacheInsertionWithTimeStampOnSuccessfullDeletion() {
         let timeStamp = Date()

         let items = uniqueImageFeed()

         let (sut,store) = makeSUT {
             timeStamp
         }

         sut.save(items.models) { _ in }
         store.completionDeletionSuccessfully()

         XCTAssertEqual(store.receivedMessages,[.deleteCachedFeed, .insert(items.local, timeStamp)])
     }

     func test_save_failsOnDeletionError() {
         let (sut,store) = makeSUT()
         let deletionError = anyNSError()

         expect(sut, toCompletWithError: deletionError) {
             store.completionDeletion(with: deletionError)
         }
     }

     func test_save_failsOnInsertionError() {
         let (sut,store) = makeSUT()
         let insertionError = anyNSError()

         expect(sut, toCompletWithError: insertionError) {
             store.completionDeletionSuccessfully()
             store.completeInsertion(with: insertionError)
         }
     }

     func test_save_succeedsOnSuccessfulCacheInsertionError() {
         let (sut,store) = makeSUT()

         expect(sut, toCompletWithError: nil) {
             store.completionDeletionSuccessfully()
             store.completeInsertionSuccessfully()
         }
     }

     func test_save_doesNotDeliverDeletionErrorAfterSUTInstanceHasBeenDeallocated() {
         let store = FeedStoreSpy()
         var sut: LocalFeedLoader? = LocalFeedLoader(store: store,
                                                     currentDate: Date.init)
         var receivedResults = [LocalFeedLoader.SaveResult]()

         sut?.save([uniqueImage()], completion: { receivedResults.append($0)  })
         sut = nil

         store.completionDeletion(with: anyNSError())
         XCTAssertTrue(receivedResults.isEmpty)
     }

     func test_save_doesNotDeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated() {
         let store = FeedStoreSpy()
         var sut: LocalFeedLoader? = LocalFeedLoader(store: store,
                                                     currentDate: Date.init)
         var receivedResults = [LocalFeedLoader.SaveResult]()//optional array
         sut?.save([uniqueImage()]) { receivedResults.append($0) }

         store.completionDeletionSuccessfully()
         sut = nil
         store.completeInsertion(with: anyNSError())

         XCTAssertTrue(receivedResults.isEmpty)
     }


     //MARK: - HELPERS

     private func makeSUT(currentDate: @escaping () -> Date = Date.init,  file: StaticString = #file, line: UInt = #line) -> (sut:LocalFeedLoader ,store: FeedStoreSpy) {
         let store = FeedStoreSpy()
         let sut = LocalFeedLoader(store: store, currentDate: currentDate)
         trackForMemoryLeaks(store, file: file, line: line)
         trackForMemoryLeaks(sut, file: file, line: line)
         return(sut, store)
     }

     private func expect(_ sut: LocalFeedLoader, toCompletWithError expectedError: NSError?, when action: () -> Void,  file: StaticString = #file, line: UInt = #line) {
         let exp = expectation(description: "Wait for save completion")
         var receivedError: Error?

         sut.save(uniqueImageFeed().models) { error in
             receivedError = error
             exp.fulfill()
         }
         action()
         wait(for: [exp], timeout: 1.0)
         XCTAssertEqual(receivedError as? NSError, expectedError, file: file, line: line)
     }
}
