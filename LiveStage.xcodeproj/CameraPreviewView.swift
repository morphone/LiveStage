//
//  CameraPreviewView.swift
//  LiveStage
//
//  Created by Michael Chartier on 2025-11-17.
//

import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        return CameraPreviewUIView(cameraManager: cameraManager)
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // Mise à jour si nécessaire
    }
}

class CameraPreviewUIView: UIView {
    private let cameraManager: CameraManager
    
    init(cameraManager: CameraManager) {
        self.cameraManager = cameraManager
        super.init(frame: .zero)
        setupPreview()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPreview() {
        backgroundColor = .black
        
        Task { @MainActor in
            if let previewLayer = cameraManager.getPreviewLayer() {
                previewLayer.frame = bounds
                layer.addSublayer(previewLayer)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.sublayers?.first?.frame = bounds
    }
}
