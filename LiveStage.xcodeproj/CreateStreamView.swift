//
//  CreateStreamView.swift
//  LiveStage
//
//  Created by Michael Chartier on 2025-11-17.
//

import SwiftUI
import SwiftData

struct CreateStreamView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var youtubeService = YouTubeAPIService()
    
    @State private var streamTitle = ""
    @State private var streamDescription = ""
    @State private var scheduledStartTime = Date()
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Informations de diffusion") {
                    TextField("Titre du stream", text: $streamTitle)
                    
                    TextField("Description", text: $streamDescription, axis: .vertical)
                        .lineLimit(3...6)
                    
                    DatePicker(
                        "Heure de début",
                        selection: $scheduledStartTime,
                        in: Date()...
                    )
                }
                
                Section("Authentification YouTube") {
                    if youtubeService.isAuthenticated {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("Connecté à YouTube")
                        }
                    } else {
                        Button("Se connecter à YouTube") {
                            Task {
                                do {
                                    try await youtubeService.authenticate()
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showError = true
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: createStream) {
                        if isCreating {
                            ProgressView()
                        } else {
                            Label("Créer le flux", systemImage: "video.fill")
                        }
                    }
                    .disabled(!canCreate || isCreating)
                }
            }
            .navigationTitle("Nouveau Stream YouTube")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .alert("Erreur", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                youtubeService.loadTokenFromKeychain()
            }
        }
    }
    
    private var canCreate: Bool {
        !streamTitle.isEmpty && youtubeService.isAuthenticated
    }
    
    private func createStream() {
        Task {
            isCreating = true
            defer { isCreating = false }
            
            do {
                // 1. Créer le broadcast
                let broadcast = try await youtubeService.createLiveStream(
                    title: streamTitle,
                    description: streamDescription,
                    scheduledStartTime: scheduledStartTime
                )
                
                // 2. Créer le stream technique
                let stream = try await youtubeService.createStream(title: streamTitle)
                
                // 3. Lier le broadcast au stream
                try await youtubeService.bindBroadcastToStream(
                    broadcastId: broadcast.id,
                    streamId: stream.id
                )
                
                // 4. Sauvegarder dans SwiftData
                let newStream = YouTubeStream(
                    id: broadcast.id,
                    title: streamTitle,
                    streamDescription: streamDescription,
                    scheduledStartTime: scheduledStartTime,
                    streamKey: stream.cdn.ingestionInfo.streamName,
                    streamURL: stream.cdn.ingestionInfo.ingestionAddress,
                    status: .scheduled
                )
                
                modelContext.insert(newStream)
                try modelContext.save()
                
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    CreateStreamView()
        .modelContainer(for: YouTubeStream.self, inMemory: true)
}
