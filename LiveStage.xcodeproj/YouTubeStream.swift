//
//  YouTubeStream.swift
//  LiveStage
//
//  Created by Michael Chartier on 2025-11-17.
//

import Foundation
import SwiftData

@Model
final class YouTubeStream {
    var id: String
    var title: String
    var streamDescription: String
    var scheduledStartTime: Date
    var streamKey: String?
    var streamURL: String?
    var status: StreamStatus
    var createdAt: Date
    
    enum StreamStatus: String, Codable {
        case draft
        case scheduled
        case live
        case completed
        case cancelled
    }
    
    init(
        id: String = UUID().uuidString,
        title: String,
        streamDescription: String = "",
        scheduledStartTime: Date = Date(),
        streamKey: String? = nil,
        streamURL: String? = nil,
        status: StreamStatus = .draft,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.streamDescription = streamDescription
        self.scheduledStartTime = scheduledStartTime
        self.streamKey = streamKey
        self.streamURL = streamURL
        self.status = status
        self.createdAt = createdAt
    }
}
