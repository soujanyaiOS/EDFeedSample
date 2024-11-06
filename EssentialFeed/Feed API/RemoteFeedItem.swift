//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by soujanya Balusu on 28/10/24.
//

import Foundation

internal struct RemoteFeedItem: Decodable {
    internal let id: UUID
    internal let description: String?
    internal let location: String?
    internal let image: URL
}
