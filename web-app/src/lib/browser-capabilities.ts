export function supportsBrowserRecording() {
  return typeof window !== "undefined" &&
    typeof navigator !== "undefined" &&
    typeof navigator.mediaDevices?.getUserMedia === "function" &&
    typeof window.AudioContext !== "undefined";
}

export function supportsLiveVoiceChat() {
  return supportsBrowserRecording() &&
    typeof window !== "undefined" &&
    typeof window.WebSocket !== "undefined";
}
