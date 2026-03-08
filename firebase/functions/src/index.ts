import * as admin from "firebase-admin";

admin.initializeApp();

export { processTranscript } from "./ai/process-session";
export { chat } from "./ai/chat";
export { analyzeImage } from "./ai/vision";
export { generateSummary } from "./ai/summary";
export { deepgramProxy } from "./transcription/deepgram-proxy";
export { elevenLabsTts } from "./integrations/elevenlabs-tts";
