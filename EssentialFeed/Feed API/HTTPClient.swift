//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by soujanya Balusu on 15/10/24.
//

import Foundation

public protocol HTTPClient {
    typealias Result = Swift.Result<(Data,HTTPURLResponse), Error>

    func get(from url: URL, completion: @escaping (Result) -> Void)
}
