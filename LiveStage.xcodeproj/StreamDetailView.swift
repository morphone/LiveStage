//
//  StreamDetailView.swift
//  LiveStage
//
//  Created by Michael Chartier on 2025-11-17.
//

import SwiftUI
import AVFoundation

struct StreamDetailView: View {
    @Bindable var stream: YouTubeStream
    @StateObject private var cameraManager = CameraManager()
    @State private var isStreaming = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Aperçu de la caméra
                CameraPreviewView(cameraManager: cameraManager)
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(alignment: .topTrailing) {
                        if isStreaming {
                            LiveIndicator()
                                .padding()
                        }
                    }
                
                // Informations du stream
                VStack(alignment: .leading, spacing: 12) {
                    Text(stream.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if !stream.streamDescription.isEmpty {
                        Text(stream.streamDescription)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    
                    Divider()
                    
                    InfoRow(label: "Statut", value: stream.status.rawValue.capitalized)
                    InfoRow(label: "Date prévue", value: stream.scheduledStartTime.formatted())
                    
                    if let streamURL = stream.streamURL {
                        InfoRow(label: "URL RTMP", value: streamURL)
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = streamURL
                                } label: {
                                    Label("Copier", systemImage: "doc.on.doc")
                                }
                            }
                    }
                    
                    if let streamKey = stream.streamKey {
                        InfoRow(label: "Clé de stream", value: "•••••••••")
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = streamKey
                                } label: {
                                    Label("Copier la clé", systemImage: "key")
                                }
                            }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                
                // Contrôles de streaming
                VStack(spacing: 12) {
                    if !isStreaming {
                        Button(action: startStreaming) {
                            Label("Démarrer la diffusion", systemImage: "play.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                        }
                        .disabled(!cameraManager.isReady)
                    } else {
                        Button(action: stopStreaming) {
                            Label("Arrêter la diffusion", systemImage: "stop.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                        }
                    }
                    
                    HStack(spacing: 16) {
                        Button {
                            cameraManager.toggleCamera()
                        } label: {
                            Label("Changer caméra", systemImage: "arrow.triangle.2.circlepath.camera")
                                .labelStyle(.iconOnly)
                                .font(.title2)
                        }
                        
                        Button {
                            cameraManager.toggleMicrophone()
                        } label: {
                            Label(
                                cameraManager.isMicrophoneMuted ? "Activer micro" : "Désactiver micro",
                                systemImage: cameraManager.isMicrophoneMuted ? "mic.slash" : "mic"
                            )
                            .labelStyle(.iconOnly)
                            .font(.title2)
                        }
                        .foregroundStyle(cameraManager.isMicrophoneMuted ? .red : .primary)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .navigationTitle("Détails du stream")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await cameraManager.requestPermissions()
            await cameraManager.setupSession()
        }
    }
    
    private func startStreaming() {
        guard let streamURL = stream.streamURL,
              let streamKey = stream.streamKey else { return }
        
        Task {
            await cameraManager.startStreaming(to: streamURL, key: streamKey)
            isStreaming = true
            stream.status = .live
        }
    }
    
    private func stopStreaming() {
        Task {
            await cameraManager.stopStreaming()
            isStreaming = false
            stream.status = .completed
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct LiveIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
                .opacity(isAnimating ? 1 : 0.3)
            
            Text("EN DIRECT")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.red, in: Capsule())
        .shadow(radius: 4)
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever()) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        StreamDetailView(stream: YouTubeStream(
            title: "Test Stream",
            streamDescription: "Ceci est une description de test",
            streamKey: "test-key-123",
            streamURL: "rtmp://example.com/live"
        ))
    }
}
