import Flutter
import Speech
import AVFoundation

class AppleSttPlugin: NSObject, FlutterStreamHandler {
    private let methodChannel: FlutterMethodChannel
    private let eventChannel: FlutterEventChannel
    private var eventSink: FlutterEventSink?

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?

    private var currentLocale: String = "en-US"
    private var shouldRestart = false

    init(messenger: FlutterBinaryMessenger) {
        methodChannel = FlutterMethodChannel(
            name: "com.myea/apple_stt",
            binaryMessenger: messenger
        )
        eventChannel = FlutterEventChannel(
            name: "com.myea/apple_stt_events",
            binaryMessenger: messenger
        )
        super.init()

        methodChannel.setMethodCallHandler(handle)
        eventChannel.setStreamHandler(self)
    }

    // MARK: - FlutterStreamHandler

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    // MARK: - Method Channel Handler

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            handleInitialize(result: result)
        case "start":
            let args = call.arguments as? [String: Any]
            let locale = args?["locale"] as? String ?? "en-US"
            handleStart(locale: locale, result: result)
        case "stop":
            handleStop(result: result)
        case "dispose":
            handleDispose(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Initialize

    private func handleInitialize(result: @escaping FlutterResult) {
        let status = SFSpeechRecognizer.authorizationStatus()

        switch status {
        case .authorized:
            result(true)
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { [weak self] newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized {
                        result(true)
                    } else {
                        self?.sendEvent(["type": "error", "message": "permission_denied"])
                        result(false)
                    }
                }
            }
        case .denied:
            sendEvent(["type": "error", "message": "permission_denied"])
            result(false)
        case .restricted:
            sendEvent(["type": "error", "message": "permission_restricted"])
            result(false)
        @unknown default:
            result(false)
        }
    }

    // MARK: - Start Listening

    private func handleStart(locale: String, result: @escaping FlutterResult) {
        // Stop any existing session first
        stopRecognition()

        currentLocale = locale
        shouldRestart = true

        // Try specified locale first, fall back to default system recognizer
        let recognizer: SFSpeechRecognizer
        if let localeRecognizer = SFSpeechRecognizer(locale: Locale(identifier: locale)),
           localeRecognizer.isAvailable {
            recognizer = localeRecognizer
        } else if let defaultRecognizer = SFSpeechRecognizer(), defaultRecognizer.isAvailable {
            recognizer = defaultRecognizer
        } else {
            sendEvent(["type": "error", "message": "No speech recognizer available"])
            sendEvent(["type": "status", "state": "unavailable"])
            result(false)
            return
        }


        speechRecognizer = recognizer

        do {
            try startRecognitionTask()
            result(true)
        } catch {
            sendEvent(["type": "error", "message": "Failed to start recognition: \(error.localizedDescription)"])
            sendEvent(["type": "status", "state": "unavailable"])
            result(false)
        }
    }

    private func startRecognitionTask() throws {
        // Cancel previous task if any
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        guard let recognizer = speechRecognizer else { return }

        // Bare minimum: audio session, engine, request, task — nothing extra
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record)
        try audioSession.setActive(true)

        if audioEngine == nil {
            audioEngine = AVAudioEngine()
        }
        guard let audioEngine = audioEngine else { return }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        let hwFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: hwFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            self?.processSoundLevel(buffer: buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] res, err in
            guard let self = self else { return }
            if let res = res {
                self.sendEvent(["type": "transcript", "text": res.bestTranscription.formattedString, "isFinal": res.isFinal])
                if res.isFinal { self.restartIfNeeded() }
            }
            if let err = err as NSError? {
                // 301 = cancelled (normal on stop), 216 = no speech, 1 = task cancelled
                if err.code != 301 && err.code != 216 && err.code != 1 {
                    self.sendEvent(["type": "error", "message": err.localizedDescription])
                }
                self.restartIfNeeded()
            }
        }

        sendEvent(["type": "status", "state": "listening"])
    }

    // MARK: - Auto-Restart (60s limit workaround)

    private func restartIfNeeded() {
        guard shouldRestart else { return }

        // Brief delay to avoid rapid restart loops
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self = self, self.shouldRestart else { return }

            // Cancel previous recognition but keep audio engine running
            self.recognitionTask?.cancel()
            self.recognitionTask = nil
            self.recognitionRequest = nil

            do {
                try self.startRecognitionTask()
            } catch {
                self.sendEvent(["type": "error", "message": "Failed to restart recognition: \(error.localizedDescription)"])
                self.sendEvent(["type": "status", "state": "stopped"])
            }
        }
    }

    // MARK: - Sound Level

    private var soundLevelCounter = 0

    private func processSoundLevel(buffer: AVAudioPCMBuffer) {
        // Throttle to ~10 events/sec (every 5th buffer at ~48 buffers/sec)
        soundLevelCounter += 1
        guard soundLevelCounter % 5 == 0 else { return }

        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }

        var rms: Float = 0

        if let channelData = buffer.floatChannelData?[0] {
            // Float format
            var sum: Float = 0
            for i in 0..<frameLength {
                sum += channelData[i] * channelData[i]
            }
            rms = sqrt(sum / Float(frameLength))
        } else if let channelData = buffer.int16ChannelData?[0] {
            // Int16 format
            var sum: Float = 0
            for i in 0..<frameLength {
                let sample = Float(channelData[i]) / Float(Int16.max)
                sum += sample * sample
            }
            rms = sqrt(sum / Float(frameLength))
        } else {
            return
        }

        // Convert to a 0-1 range
        let normalized = min(max(Double(rms) * 5.0, 0.0), 1.0)

        DispatchQueue.main.async { [weak self] in
            self?.sendEvent(["type": "soundLevel", "level": normalized])
        }
    }

    // MARK: - Stop

    private func handleStop(result: @escaping FlutterResult) {
        stopRecognition()
        result(nil)
    }

    private func stopRecognition() {
        shouldRestart = false

        recognitionTask?.cancel()
        recognitionTask = nil

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()

        sendEvent(["type": "status", "state": "stopped"])
    }

    // MARK: - Dispose

    private func handleDispose(result: @escaping FlutterResult) {
        stopRecognition()
        audioEngine = nil
        speechRecognizer = nil
        result(nil)
    }

    // MARK: - Helpers

    private func sendEvent(_ data: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            self?.eventSink?(data)
        }
    }
}
