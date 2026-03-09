# FieldFlow

Voice-first mobile AI agent for field workers using Flutter, Supabase, Firebase Functions, OpenAI Whisper, and Gemini.

## Web App

A separate Next.js frontend now lives in `web-app/`.

- Setup: `cd web-app && cp .env.example .env.local`
- Dev server: `cd web-app && npm run dev`
- Verification: `cd web-app && npm run lint && npm run typecheck && npm run test:run && npm run build`

The web app reuses the existing Supabase project and Firebase Functions deployment. No additional backend copy is required.

## App Setup

1. Copy `.env.example` to `.env`.
2. Fill in the public runtime values for Supabase and Firebase Functions.
3. Start the app with `flutter run --dart-define-from-file=.env`.

The Flutter app reads runtime config from Dart defines, not hardcoded constants.

## Firebase Functions Setup

Functions use Firebase-managed secrets in production and `.env.local` for the emulator.

- Local emulator: `cd firebase/functions && npm run serve`
- Build only: `cd firebase/functions && npm run build`
- Production secrets: `firebase functions:secrets:set GEMINI_API_KEY` and the other required keys

Required function secrets:

- `GEMINI_API_KEY`
- `SUPABASE_URL`
- `SUPABASE_SERVICE_KEY`
- `OPENAI_API_KEY`
- `ELEVENLABS_API_KEY` for premium TTS only
- `ELEVENLABS_AGENT_ID` for conversational voice

## Supabase Notes

- `media-attachments` should remain a private bucket
- `avatars` can remain public
- Apply the SQL migrations before running the full app flow
