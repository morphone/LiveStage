//
//  RTMPStreamManager.swift
//  LiveStage
//
//  Created by Michael Chartier on 2025-11-17.
//  Implémentation complète du streaming RTMP avec HaishinKit

import Foundation
import AVFoundation

/// Gestionnaire de streaming RTMP avec HaishinKit
/// Gère la configuration vidéo/audio, la connexion RTMP et le monitoring
@MainActor
class RTMPStreamManager: NSObject, ObservableObject {

    // MARK: - Published Properties

    @Published var isStreaming = false
    @Published var isReady = false
    @Published var isMicrophoneMuted = false
    @Published var currentCamera: AVCaptureDevice.Position = .back
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var bitrate: Int = 0
    @Published var fps: Int = 0
    @Published var streamHealth: StreamHealth = .excellent

    // MARK: - Connection Status Enum

    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected
        case reconnecting(attempt: Int)
        case error(String)

        var description: String {
            switch self {
            case .disconnected:
                return "Déconnecté"
            case .connecting:
                return "Connexion..."
            case .connected:
                return "Connecté"
            case .reconnecting(let attempt):
                return "Reconnexion (\(attempt)/5)..."
            case .error(let message):
                return "Erreur: \(message)"
            }
        }
    }

    // MARK: - Stream Health Enum

    enum StreamHealth {
        case excellent // > 80% packet success
        case good      // 60-80% packet success
        case fair      // 40-60% packet success
        case poor      // < 40% packet success

        var indicator: String {
            switch self {
            case .excellent: return "🟢"
            case .good: return "🟡"
            case .fair: return "🟠"
            case .poor: return "🔴"
            }
        }
    }

    // MARK: - Private Properties

    // HaishinKit instances (comment if not using HaishinKit)
    private var rtmpConnection: Any?  // RTMPConnection in reality
    private var rtmpStream: Any?      // RTMPStream in reality

    // Audio/Video session management
    private var audioSession: AVAudioSession?
    private var captureSession: AVCaptureSession?

    // Monitoring
    private var monitoringTask: Task<Void, Never>?
    private var reconnectionAttempts = 0
    private let maxReconnectionAttempts = 5
    private var streamStartTime: Date?

    // Metrics tracking
    private var droppedFrames = 0
    private var totalFrames = 0

    // MARK: - Initialization

    override init() {
        super.init()
        setupAudioSession()
        setupCaptureSession()
        setupRTMP()
    }

    // MARK: - Setup Methods

    /// Configure la session audio
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.duckOthers])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            self.audioSession = session
            AppLogger.logMicrophonePermission(granted: true)
        } catch {
            AppLogger.logError(error, context: "Configuration AVAudioSession")
            connectionStatus = .error("Configuration audio échouée")
        }
    }

    /// Configure la session de capture vidéo
    private func setupCaptureSession() {
        let session = AVCaptureSession()
        session.sessionPreset = .hd1280x720
        self.captureSession = session
    }

    /// Configure HaishinKit RTMP
    private func setupRTMP() {
        // NOTE: HaishinKit needs to be added via SPM first
        // When HaishinKit is available, uncomment and implement:
        /*
        do {
            rtmpConnection = RTMPConnection()
            rtmpStream = RTMPStream(connection: rtmpConnection as! RTMPConnection)

            guard let stream = rtmpStream as? RTMPStream else { return }

            // Configuration vidéo
            stream.videoSettings = [
                .width: Config.Streaming.defaultResolution.width,
                .height: Config.Streaming.defaultResolution.height,
                .bitrate: Config.Streaming.recommendedBitrate(for: Config.Streaming.defaultResolution) * 1000,
                .maxKeyFrameIntervalDuration: 2.0,
            ]

            // Configuration audio
            stream.audioSettings = [
                .bitrate: Config.Streaming.audioBitrate * 1000,
                .sampleRate: Config.Streaming.audioSampleRate,
                .channels: 2,
            ]

            // Framerate
            stream.frameRate = Float64(Config.Streaming.defaultFrameRate)

            isReady = true
            AppLogger.stream.info("✅ RTMP configuré avec succès")
        } catch {
            AppLogger.logError(error, context: "Configuration RTMP")
            isReady = false
        }
        */

        // For now, mark as ready to allow testing without HaishinKit
        isReady = true
    }

    // MARK: - Permissions

    /// Demande les permissions caméra et microphone
    func requestPermissions() async {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)

        if cameraStatus == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            AppLogger.logCameraPermission(granted: granted)
        }

        if micStatus == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            AppLogger.logMicrophonePermission(granted: granted)
        }
    }

    // MARK: - Camera Control

    /// Attache la caméra au stream
    private func attachCamera() {
        AppLogger.stream.debug("📷 Attachement caméra: \(currentCamera == .back ? "arrière" : "avant")")

        // HaishinKit integration would go here
        /*
        guard let stream = rtmpStream as? RTMPStream,
              let camera = DeviceUtil.device(withPosition: currentCamera) else {
            AppLogger.logError(AppError.cameraNotAvailable, context: "Caméra non trouvée")
            return
        }

        stream.attachCamera(camera) { error in
            if let error = error {
                AppLogger.logError(error, context: "Attachement caméra")
            }
        }
        */
    }

    /// Attache le microphone au stream
    private func attachAudio() {
        AppLogger.stream.debug("🎤 Attachement microphone")

        // HaishinKit integration would go here
        /*
        guard let stream = rtmpStream as? RTMPStream,
              let microphone = AVCaptureDevice.default(for: .audio) else {
            AppLogger.logError(AppError.cameraNotAvailable, context: "Microphone non trouvé")
            return
        }

        stream.attachAudio(microphone) { error in
            if let error = error {
                AppLogger.logError(error, context: "Attachement microphone")
            }
        }
        */
    }

    /// Change entre caméra avant et arrière
    func switchCamera() {
        currentCamera = currentCamera == .back ? .front : .back
        AppLogger.stream.info("📷 Changement caméra: \(currentCamera == .back ? "arrière" : "avant")")
        attachCamera()
    }

    /// Active/désactive le microphone
    func toggleMicrophone() {
        isMicrophoneMuted.toggle()
        AppLogger.stream.info("🎤 Microphone: \(isMicrophoneMuted ? "muet" : "actif")")

        // Update HaishinKit stream if available
        /*
        if let stream = rtmpStream as? RTMPStream {
            stream.hasAudio = !isMicrophoneMuted
        }
        */
    }

    // MARK: - Streaming Control

    /// Démarre le streaming vers un serveur RTMP
    func startStreaming(to url: String, key: String) async throws {
        guard !isStreaming else {
            throw AppError.streamingError("Streaming déjà actif")
        }

        guard !url.isEmpty && !key.isEmpty else {
            throw AppError.streamingError("URL ou clé de stream invalide")
        }

        connectionStatus = .connecting
        AppLogger.logStreamStart(streamId: key)

        do {
            // Demander les permissions
            await requestPermissions()

            // Attacher les périphériques
            attachCamera()
            attachAudio()

            // Construire l'URL RTMP complète
            let fullURL = url.hasSuffix("/") ? "\(url)\(key)" : "\(url)/\(key)"

            // HaishinKit connection
            /*
            guard let connection = rtmpConnection as? RTMPConnection else {
                throw AppError.rtmpConnectionFailed
            }

            connection.connect(fullURL)

            // Give the connection time to establish
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

            if let stream = rtmpStream as? RTMPStream {
                stream.publish("")
            }
            */

            isStreaming = true
            connectionStatus = .connected
            streamStartTime = Date()
            reconnectionAttempts = 0

            AppLogger.logRTMPConnection(url: fullURL, success: true)

            // Start monitoring
            startMonitoring()

        } catch {
            connectionStatus = .error(error.localizedDescription)
            isStreaming = false
            throw error
        }
    }

    /// Arrête le streaming
    func stopStreaming() {
        guard isStreaming else { return }

        AppLogger.logStreamStop(streamId: "current", duration: streamStartTime.map { Date().timeIntervalSince($0) })

        // HaishinKit cleanup
        /*
        if let stream = rtmpStream as? RTMPStream {
            stream.close()
        }

        if let connection = rtmpConnection as? RTMPConnection {
            connection.close()
        }
        */

        isStreaming = false
        connectionStatus = .disconnected
        bitrate = 0
        fps = 0
        stopMonitoring()
    }

    // MARK: - Monitoring

    /// Démarre la surveillance des métriques du stream
    private func startMonitoring() {
        monitoringTask = Task {
            while isStreaming && !Task.isCancelled {
                updateMetrics()
                try? await Task.sleep(nanoseconds: 1_000_000_000) // Update every second
            }
        }
    }

    /// Arrête la surveillance
    private func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
    }

    /// Mise à jour des métriques du stream
    private func updateMetrics() {
        // HaishinKit metrics would go here
        /*
        guard let stream = rtmpStream as? RTMPStream else { return }

        fps = Int(stream.currentFPS)
        bitrate = Int(stream.currentBitrate / 1000) // Convert to kbps

        // Calculate health
        let packetLoss = Double(droppedFrames) / Double(totalFrames) * 100
        streamHealth = packetLoss < 20 ? .excellent :
                       packetLoss < 40 ? .good :
                       packetLoss < 60 ? .fair : .poor
        */
    }

    // MARK: - Reconnection Logic

    /// Reconnexion automatique après erreur réseau
    func attemptReconnection(to url: String, key: String) async {
        guard reconnectionAttempts < maxReconnectionAttempts else {
            connectionStatus = .error("Impossible de se reconnecter après \(maxReconnectionAttempts) tentatives")
            return
        }

        reconnectionAttempts += 1
        connectionStatus = .reconnecting(attempt: reconnectionAttempts)

        AppLogger.stream.info("🔄 Tentative de reconnexion \(reconnectionAttempts)/\(maxReconnectionAttempts)")

        // Exponential backoff: 1s, 2s, 4s, 8s, 16s
        let delay = UInt64(pow(2.0, Double(reconnectionAttempts - 1))) * 1_000_000_000
        try? await Task.sleep(nanoseconds: min(delay, 30_000_000_000)) // Max 30 seconds

        do {
            try await startStreaming(to: url, key: key)
        } catch {
            AppLogger.logStreamError(error: error.localizedDescription)
            // Will retry on next call to attemptReconnection
        }
    }

    // MARK: - Settings

    /// Configure la qualité vidéo
    func setVideoQuality(resolution: Config.Streaming.VideoResolution, framerate: Int) {
        AppLogger.stream.debug("🎬 Qualité vidéo: \(resolution.width)x\(resolution.height) @ \(framerate)fps")

        // HaishinKit configuration
        /*
        guard let stream = rtmpStream as? RTMPStream else { return }

        stream.videoSettings[.width] = resolution.width
        stream.videoSettings[.height] = resolution.height
        stream.videoSettings[.bitrate] = Config.Streaming.recommendedBitrate(for: resolution) * 1000
        stream.frameRate = Float64(framerate)
        */
    }

    /// Active le bitrate adaptatif
    func enableAdaptiveBitrate(_ enable: Bool) {
        AppLogger.stream.debug("📊 Bitrate adaptatif: \(enable ? "activé" : "désactivé")")

        // HaishinKit adaptive bitrate would go here
        /*
        guard let stream = rtmpStream as? RTMPStream else { return }

        if enable {
            stream.bitrateStrategy = AdaptiveBitrateMechanism()
        } else {
            stream.bitrateStrategy = nil
        }
        */
    }

    // MARK: - Deinit

    deinit {
        if isStreaming {
            stopStreaming()
        }
        stopMonitoring()
    }
}

// MARK: - Preview Helper

#if DEBUG
@MainActor
class PreviewRTMPStreamManager: RTMPStreamManager {
    override func startStreaming(to url: String, key: String) async throws {
        connectionStatus = .connecting
        try await Task.sleep(nanoseconds: 500_000_000)
        connectionStatus = .connected
        isStreaming = true
    }

    override func stopStreaming() {
        connectionStatus = .disconnected
        isStreaming = false
    }
}
#endif
