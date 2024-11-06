//
//  XCTestcase+MemoryLeaktrackingHElper.swift
//  EssentialFeedTests
//
//  Created by soujanya Balusu on 19/10/24.
//

import XCTest

extension XCTestCase {
    func trackForMemoryLeaks (_ instance: AnyObject, file: StaticString = #file, line: UInt = #line ) {
        addTeardownBlock { [weak instance] in

        XCTAssertNil(instance, "Instance should have been deallocated. Poptential Memory leak.",
                         file: file,
                         line: line)
        }
    }
}
