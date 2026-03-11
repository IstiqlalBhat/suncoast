import * as admin from "firebase-admin";

admin.initializeApp();

export { processTranscript } from "./ai/process-session";
export { chat } from "./ai/chat";
export { analyzeImage } from "./ai/vision";
export { createRealtimeMediaSession } from "./ai/openai-realtime-session";
export { extractPdfText } from "./ai/extract-pdf-text";
export { generateSummary } from "./ai/summary";
export { syncActivityStatus } from "./activities/sync-status";
export { whisperProxy } from "./transcription/whisper-proxy";
export { openaiTts } from "./integrations/openai-tts";

// ElevenLabs Conversational AI
export { getSignedConversationUrl } from "./agent-tools/get-signed-url";
export { agentCreateObservation } from "./agent-tools/create-observation";
export { agentCreateAction } from "./agent-tools/create-action";
export { agentLookupInfo } from "./agent-tools/lookup-info";
