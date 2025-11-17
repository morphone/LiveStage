//
//  ContentView.swift
//  LiveStage
//
//  Created by Michael Chartier on 2025-11-17.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            StreamListView()
                .tabItem {
                    Label("Streams", systemImage: "video.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Réglages", systemImage: "gear")
                }
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Form {
                Section("À propos") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Application", value: "LiveStage")
                }
                
                Section("YouTube") {
                    NavigationLink("Configuration API") {
                        Text("Configuration des clés API YouTube")
                    }
                }
                
                Section("Streaming") {
                    NavigationLink("Paramètres vidéo") {
                        Text("Résolution, bitrate, etc.")
                    }
                }
            }
            .navigationTitle("Réglages")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: YouTubeStream.self, inMemory: true)
}
