//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by soujanya Balusu on 30/10/24.
//

import Foundation

func  anyNSError() -> NSError {
    return NSError(domain: "any Error", code: 1)
}


func anyURL() -> URL {
    return  URL(string: "http://any-url.com")!
}
