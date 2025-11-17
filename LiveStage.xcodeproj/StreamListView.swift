//
//  StreamListView.swift
//  LiveStage
//
//  Created by Michael Chartier on 2025-11-17.
//

import SwiftUI
import SwiftData

struct StreamListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \YouTubeStream.createdAt, order: .reverse) private var streams: [YouTubeStream]
    
    @State private var showingCreateStream = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(streams) { stream in
                    NavigationLink {
                        StreamDetailView(stream: stream)
                    } label: {
                        StreamRowView(stream: stream)
                    }
                }
                .onDelete(perform: deleteStreams)
            }
            .navigationTitle("Mes Streams YouTube")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateStream = true
                    } label: {
                        Label("Nouveau Stream", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateStream) {
                CreateStreamView()
            }
            .overlay {
                if streams.isEmpty {
                    ContentUnavailableView(
                        "Aucun stream",
                        systemImage: "video.slash",
                        description: Text("Créez votre premier flux de diffusion YouTube")
                    )
                }
            }
        }
    }
    
    private func deleteStreams(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(streams[index])
            }
        }
    }
}

struct StreamRowView: View {
    let stream: YouTubeStream
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(stream.title)
                .font(.headline)
            
            HStack {
                StatusBadge(status: stream.status)
                
                Text(stream.scheduledStartTime, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(stream.scheduledStartTime, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: YouTubeStream.StreamStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.2), in: Capsule())
    }
    
    private var statusColor: Color {
        switch status {
        case .draft: return .gray
        case .scheduled: return .blue
        case .live: return .red
        case .completed: return .green
        case .cancelled: return .orange
        }
    }
    
    private var statusText: String {
        switch status {
        case .draft: return "Brouillon"
        case .scheduled: return "Planifié"
        case .live: return "En direct"
        case .completed: return "Terminé"
        case .cancelled: return "Annulé"
        }
    }
}

#Preview {
    StreamListView()
        .modelContainer(for: YouTubeStream.self, inMemory: true)
}
