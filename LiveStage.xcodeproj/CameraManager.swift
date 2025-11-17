//
//  CameraManager.swift
//  LiveStage
//
//  Created by Michael Chartier on 2025-11-17.
//

import AVFoundation
import SwiftUI

/// Gestionnaire de caméra et d'encodage vidéo pour le streaming
@MainActor
class CameraManager: NSObject, ObservableObject {
    @Published var isReady = false
    @Published var isMicrophoneMuted = false
    @Published var currentCamera: AVCaptureDevice.Position = .back
    
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var audioOutput: AVCaptureAudioDataOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    // MARK: - Permissions
    
    func requestPermissions() async {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        if cameraStatus == .notDetermined {
            await AVCaptureDevice.requestAccess(for: .video)
        }
        
        if micStatus == .notDetermined {
            await AVCaptureDevice.requestAccess(for: .audio)
        }
    }
    
    // MARK: - Session Setup
    
    func setupSession() async {
        guard captureSession == nil else { return }
        
        let session = AVCaptureSession()
        session.beginConfiguration()
        
        // Configuration de la qualité
        if session.canSetSessionPreset(.hd1920x1080) {
            session.sessionPreset = .hd1920x1080
        } else {
            session.sessionPreset = .high
        }
        
        // Ajout de la caméra
        if let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCamera),
           let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
           session.canAddInput(videoInput) {
            session.addInput(videoInput)
        }
        
        // Ajout du microphone
        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }
        
        // Configuration de la sortie vidéo
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        self.videoOutput = videoOutput
        
        // Configuration de la sortie audio
        let audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "audioQueue"))
        if session.canAddOutput(audioOutput) {
            session.addOutput(audioOutput)
        }
        self.audioOutput = audioOutput
        
        session.commitConfiguration()
        
        self.captureSession = session
        
        // Démarrer la session
        Task.detached { [weak self] in
            self?.captureSession?.startRunning()
            await MainActor.run {
                self?.isReady = true
            }
        }
    }
    
    // MARK: - Preview Layer
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        guard let session = captureSession else { return nil }
        
        if previewLayer == nil {
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            previewLayer = layer
        }
        
        return previewLayer
    }
    
    // MARK: - Controls
    
    func toggleCamera() {
        currentCamera = currentCamera == .back ? .front : .back
        
        Task {
            // Reconfigurer la session avec la nouvelle caméra
            captureSession?.beginConfiguration()
            
            // Retirer l'ancienne entrée vidéo
            if let currentInput = captureSession?.inputs.first(where: { ($0 as? AVCaptureDeviceInput)?.device.hasMediaType(.video) == true }) {
                captureSession?.removeInput(currentInput)
            }
            
            // Ajouter la nouvelle entrée
            if let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCamera),
               let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
               captureSession?.canAddInput(videoInput) == true {
                captureSession?.addInput(videoInput)
            }
            
            captureSession?.commitConfiguration()
        }
    }
    
    func toggleMicrophone() {
        isMicrophoneMuted.toggle()
        // TODO: Implémenter le mute réel de l'audio
    }
    
    // MARK: - Streaming
    
    func startStreaming(to url: String, key: String) async {
        // TODO: Implémenter l'encodage et l'envoi RTMP
        // Cela nécessite une bibliothèque tierce comme HaishinKit ou un encodeur personnalisé
        print("Démarrage du streaming vers: \(url) avec la clé: \(key)")
        
        /*
         Pour implémenter le streaming RTMP réel, vous aurez besoin de:
         1. Une bibliothèque RTMP comme HaishinKit (https://github.com/shogo4405/HaishinKit.swift)
         2. Un encodeur H.264 pour la vidéo
         3. Un encodeur AAC pour l'audio
         4. Une gestion de la connexion réseau
         
         Exemple avec HaishinKit:
         
         import HaishinKit
         
         let rtmpConnection = RTMPConnection()
         let rtmpStream = RTMPStream(connection: rtmpConnection)
         
         rtmpStream.attachCamera(DeviceUtil.device(withPosition: currentCamera))
         rtmpStream.attachAudio(AVCaptureDevice.default(for: .audio))
         
         rtmpConnection.connect(url)
         rtmpStream.publish(key)
         */
    }
    
    func stopStreaming() async {
        print("Arrêt du streaming")
        // TODO: Arrêter l'encodage et fermer la connexion RTMP
    }
    
    deinit {
        captureSession?.stopRunning()
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Ici, vous recevez les frames vidéo et audio
        // Ces frames doivent être encodés et envoyés au serveur RTMP
        
        if output == videoOutput {
            // Traitement vidéo
        } else if output == audioOutput {
            // Traitement audio
        }
    }
}
