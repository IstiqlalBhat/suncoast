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
            SFSpeechRecognizer.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    result(newStatus == .authorized)
                }
            }
        case .denied, .restricted:
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

        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: locale)) else {
            sendEvent(["type": "error", "message": "Speech recognizer unavailable for locale: \(locale)"])
            sendEvent(["type": "status", "state": "unavailable"])
            result(false)
            return
        }

        guard recognizer.isAvailable else {
            sendEvent(["type": "error", "message": "Speech recognizer not available"])
            sendEvent(["type": "status", "state": "unavailable"])
            result(false)
            return
        }

        // Log whether on-device is reported as supported, but don't hard-fail —
        // supportsOnDeviceRecognition can return false on some iOS versions even
        // when on-device recognition actually works. We set requiresOnDeviceRecognition
        // on the request and let the recognition task itself fail if truly unavailable.
        if !recognizer.supportsOnDeviceRecognition {
            sendEvent(["type": "status", "state": "on_device_not_reported"])
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

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = true

        recognitionRequest = request

        // Set up audio engine
        if audioEngine == nil {
            audioEngine = AVAudioEngine()
        }

        guard let audioEngine = audioEngine else {
            throw NSError(domain: "AppleSttPlugin", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to create audio engine"])
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Only set up audio engine tap if not already running (first start).
        // On restart (60s limit), the engine stays running — just create a new request.
        if !audioEngine.isRunning {
            inputNode.removeTap(onBus: 0)

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
                self?.recognitionRequest?.append(buffer)
                self?.processSoundLevel(buffer: buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
        }

        // Start recognition
        guard let recognizer = speechRecognizer else { return }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] taskResult, error in
            guard let self = self else { return }

            if let taskResult = taskResult {
                let text = taskResult.bestTranscription.formattedString
                let isFinal = taskResult.isFinal

                self.sendEvent([
                    "type": "transcript",
                    "text": text,
                    "isFinal": isFinal,
                ])

                // Auto-restart when task completes (60s limit)
                if isFinal {
                    self.restartIfNeeded()
                }
            }

            if let error = error as NSError? {
                // Code 216 = no speech detected, 1 = task cancelled — both are non-fatal
                if error.code != 216 && error.code != 1 {
                    self.sendEvent(["type": "error", "message": error.localizedDescription])
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

    private func processSoundLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }

        var sum: Float = 0
        for i in 0..<frameLength {
            sum += channelData[i] * channelData[i]
        }
        let rms = sqrt(sum / Float(frameLength))

        // Convert to a 0-1 range (RMS of speech is typically 0.01-0.3)
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
