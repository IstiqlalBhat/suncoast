# myEA

**my Executive Assistant** — a voice-first mobile AI agent. Capture observations, analyze media, and generate structured session summaries through natural voice interaction.

Built with Flutter, Supabase, Firebase Cloud Functions, OpenAI (Whisper + Realtime + TTS), Google Gemini, and ElevenLabs.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CLIENTS                                      │
│  ┌──────────────┐   ┌──────────────┐                                │
│  │ Flutter App   │   │ Next.js Web  │                                │
│  │ (iOS/Android) │   │ (web-app/)   │                                │
│  └──────┬───────┘   └──────┬───────┘                                │
└─────────┼──────────────────┼────────────────────────────────────────┘
          │                  │
          ▼                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     SUPABASE                                        │
│  ┌────────────┐  ┌──────────────┐  ┌────────────────┐               │
│  │  Auth       │  │  PostgreSQL  │  │  Storage       │               │
│  │  (JWT)      │  │  + RLS       │  │  (media-       │               │
│  │             │  │              │  │   attachments)  │               │
│  └────────────┘  └──────────────┘  └────────────────┘               │
└─────────────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────────┐
│                  FIREBASE CLOUD FUNCTIONS                           │
│                                                                     │
│  Callable (onCall)              HTTP (onRequest)                    │
│  ├─ chat                        ├─ whisperProxy                    │
│  ├─ processTranscript           ├─ getSignedConversationUrl        │
│  ├─ analyzeImage                ├─ agentCreateObservation          │
│  ├─ createRealtimeMediaSession  ├─ agentCreateAction               │
│  ├─ extractPdfText              └─ agentLookupInfo                 │
│  ├─ generateSummary                                                │
│  ├─ syncActivityStatus                                             │
│  └─ openaiTts                                                      │
└────────────┬───────────────────────────┬────────────────────────────┘
             │                           │
             ▼                           ▼
┌────────────────────┐    ┌──────────────────────────┐
│  Google Gemini     │    │  OpenAI                   │
│  ├─ Chat analysis  │    │  ├─ Whisper (STT)         │
│  ├─ Vision         │    │  ├─ Realtime API (voice)  │
│  └─ Summaries      │    │  └─ TTS (text-to-speech)  │
└────────────────────┘    └──────────────────────────┘
                                     │
                          ┌──────────┘
                          ▼
                ┌──────────────────┐
                │  ElevenLabs      │
                │  Conversational  │
                │  AI Agent        │
                └──────────────────┘
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter 3.11+, Dart, Riverpod |
| Web | Next.js (App Router), TypeScript, Tailwind CSS |
| Database | Supabase PostgreSQL with Row-Level Security |
| Auth | Supabase Auth (email/password) + device biometrics |
| Storage | Supabase Storage (private `media-attachments`, public `avatars`) |
| Backend | Firebase Cloud Functions (Node.js 20, TypeScript) |
| AI - Text | Google Gemini (`gemini-3.1-pro-preview`, `gemini-3-flash-preview`) |
| AI - Voice | OpenAI Realtime API (`gpt-4o-realtime-preview`), OpenAI Whisper |
| AI - TTS | OpenAI TTS (`tts-1`), ElevenLabs (premium), device flutter_tts |
| AI - Conversation | ElevenLabs Conversational AI Agent (WebSocket) |

## Project Structure

```
voice-mobile/
├── lib/                              # Flutter mobile app
│   ├── core/
│   │   ├── config/app_config.dart        # Runtime env vars (dart-define)
│   │   ├── constants/
│   │   │   ├── api_endpoints.dart        # API paths, table names
│   │   │   └── app_colors.dart           # Color constants
│   │   ├── network/api_client.dart       # Firebase callable + Whisper proxy
│   │   ├── router/app_router.dart        # GoRouter with auth redirect
│   │   ├── theme/app_theme.dart          # Material 3 dark theme (Inter font)
│   │   ├── errors/exceptions.dart        # Custom exception types
│   │   └── utils/result.dart             # Result<T> sealed class
│   │
│   ├── features/
│   │   ├── auth/                         # Email/password + Face ID login
│   │   ├── dashboard/                    # Activity CRUD, search, filters
│   │   ├── session/                      # Core: passive/chat/media sessions
│   │   ├── summary/                      # AI summaries, edit, PDF/MD export
│   │   ├── settings/                     # User preferences (TTS, biometrics)
│   │   ├── history/                      # Past sessions list
│   │   └── home/                         # Bottom nav shell
│   │
│   ├── services/
│   │   ├── audio/
│   │   │   ├── audio_recording_service.dart   # PCM16 @ 16kHz mic recording
│   │   │   └── audio_playback_service.dart     # Device TTS + OpenAI TTS
│   │   ├── voice/
│   │   │   └── openai_realtime_voice_service.dart  # WebSocket to OpenAI Realtime
│   │   ├── conversation/
│   │   │   └── elevenlabs_conversation_service.dart # WebSocket to ElevenLabs
│   │   ├── media/
│   │   │   ├── camera_service.dart            # Photo/gallery/PDF/file picker
│   │   │   ├── media_upload_service.dart      # Upload to Supabase Storage
│   │   │   └── openai_realtime_media_service.dart  # Real-time media analysis
│   │   ├── biometric/biometric_service.dart   # Face ID / fingerprint
│   │   └── storage/secure_storage_service.dart # Keychain token storage
│   │
│   ├── shared/
│   │   ├── models/                       # Freezed data classes
│   │   ├── providers/                    # Global Riverpod providers
│   │   └── widgets/                      # Reusable UI components
│   │
│   ├── main.dart                         # Entry point, Firebase init
│   └── app.dart                          # MaterialApp.router
│
├── firebase/functions/               # Backend Cloud Functions
│   └── src/
│       ├── index.ts                      # Exports all functions
│       ├── ai/
│       │   ├── chat.ts                   # Gemini chat with event extraction
│       │   ├── process-session.ts        # Transcript → structured events
│       │   ├── vision.ts                 # Image analysis (Gemini Flash)
│       │   ├── extract-pdf-text.ts       # PDF text extraction (pdf-parse)
│       │   ├── openai-realtime-session.ts # Create Realtime API session
│       │   └── summary.ts               # Session → structured summary
│       ├── agent-tools/
│       │   ├── create-observation.ts     # ElevenLabs webhook: log observation
│       │   ├── create-action.ts          # ElevenLabs webhook: log action
│       │   ├── lookup-info.ts            # ElevenLabs webhook: query history
│       │   └── get-signed-url.ts         # ElevenLabs signed WebSocket URL
│       ├── transcription/
│       │   └── whisper-proxy.ts          # OpenAI Whisper proxy (audio → text)
│       ├── integrations/
│       │   └── openai-tts.ts             # OpenAI TTS proxy (text → audio)
│       ├── activities/
│       │   └── sync-status.ts            # Sync activity status from session
│       └── utils/
│           ├── auth.ts                   # Auth helpers, session ownership
│           └── logging.ts                # Structured error logging
│
├── supabase/
│   ├── migrations/                   # 16 sequential SQL migrations
│   │   └── all_migrations.sql            # Compiled full schema
│   └── scripts/                      # Backfill and cleanup utilities
│
├── web-app/                          # Next.js web dashboard
│   └── src/
│       ├── app/                          # App Router pages
│       ├── components/                   # React components
│       └── lib/                          # Supabase clients, types, data
│
├── pubspec.yaml                      # Flutter dependencies
└── .env.example                      # Runtime config template
```

## Session Modes

myEA supports three session modes:

### Passive Listen

One-way audio monitoring. The app records the user's speech, transcribes it via Whisper, and feeds the transcript to Gemini for real-time event extraction (observations, actions, lookups). The AI operates silently — no voice responses.

**Flow:** Mic → PCM16 → Whisper proxy → Gemini `processTranscript` → `ai_events` table

### Two-Way Voice Chat

Bidirectional voice conversation using the ElevenLabs Conversational AI Agent. The agent can call server-side tools (`create-observation`, `create-action`, `lookup-info`) as webhooks during conversation to record events and query session history.

**Flow:** Mic → ElevenLabs WebSocket ↔ Agent ↔ Webhook tools → `ai_events` table

### Media Capture

Voice conversation with photo and PDF analysis. Uses the OpenAI Realtime API (`gpt-4o-realtime-preview`) with function calling. The agent can request images (`request_image` tool) or documents (`request_pdf` tool), triggering the app to show capture UI.

**Flow:**
```
Mic → OpenAI Realtime WebSocket ↔ Voice + Function Calls
                                      │
                        ┌──────────────┼──────────────┐
                        ▼              ▼              ▼
                   request_image   request_pdf    Voice response
                        │              │
                        ▼              ▼
                Camera/Gallery    File Picker
                        │              │
                        ▼              ▼
              Supabase Storage    extractPdfText
                        │              │
                        ▼              ▼
               analyzeImage      Text sent back
              (Gemini Flash)     to Realtime API
                        │
                        ▼
                  ai_events +
                media_attachments
```

## Firebase Cloud Functions

### Callable Functions (onCall)

These are invoked from the mobile/web clients via Firebase SDK. All validate Supabase JWT tokens and enforce session ownership.

| Function | AI Model | Purpose |
|----------|----------|---------|
| `chat` | Gemini Pro | Conversational AI with structured event + reference card extraction |
| `processTranscript` | Gemini Pro | Analyze transcript text, extract observation/lookup/action events |
| `analyzeImage` | Gemini Flash | Image analysis, updates `media_attachments` record |
| `extractPdfText` | — | Extract text from PDF (pdf-parse), max 30KB output |
| `createRealtimeMediaSession` | — | Provision OpenAI Realtime API session, return `clientSecret` |
| `generateSummary` | Gemini Flash | Generate structured session summary from transcript + events + media |
| `syncActivityStatus` | — | Update activity status (pending/in_progress/completed/cancelled) |
| `openaiTts` | OpenAI TTS-1 | Convert text to speech, return base64 MP3 |

### HTTP Functions (onRequest)

These are standard Express-style endpoints. The webhook endpoints are called by the ElevenLabs agent during conversation.

| Function | Auth | Purpose |
|----------|------|---------|
| `whisperProxy` | Bearer token | Proxy audio to OpenAI Whisper, return transcript |
| `getSignedConversationUrl` | Bearer token | Fetch ElevenLabs signed WebSocket URL for agent |
| `agentCreateObservation` | Session ID | ElevenLabs webhook: insert observation into `ai_events` |
| `agentCreateAction` | Session ID | ElevenLabs webhook: insert action into `ai_events` |
| `agentLookupInfo` | Session ID | ElevenLabs webhook: query current + historical events |

### AI System Prompts

**chat.ts** — Gemini acts as "myEA (my Executive Assistant)." Returns JSON with `message` (spoken response), `events[]` (observation/lookup/action), and `referenceCards[]` (info/contact/task/suggestion cards).

**process-session.ts** — Gemini analyzes raw transcripts and extracts structured events. Categorizes each as observation, lookup, or action with status.

**vision.ts** — Gemini Flash reviews images. Returns description, context relation, and an extracted event.

**openai-realtime-session.ts** — OpenAI Realtime agent is configured as "myEA (my Executive Assistant), a voice-first realtime media assistant." Has `request_image` and `request_pdf` tool definitions. Uses server-side VAD (threshold 0.5, 300ms prefix, 500ms silence).

**summary.ts** — Gemini Flash generates a structured summary from the full session transcript, AI events, and media attachments. Outputs observation summary, key observations, actions taken with statuses, follow-ups with priority/due dates, and external record links.

## Database Schema (Supabase PostgreSQL)

All tables enforce Row-Level Security. Users can only access their own data.

### Tables

```
profiles
├── id (UUID, PK, FK → auth.users)
├── email, name, avatar_url
├── role (default: 'field_worker')
├── org_id (FK → organizations)
└── created_at, updated_at

organizations
├── id (UUID, PK)
├── name, settings (JSONB)
└── created_at
    ↑ Auto-created for each new profile

activities
├── id (UUID, PK)
├── org_id (FK → organizations)
├── title, description
├── type ('passive' | 'twoway' | 'media')
├── status ('pending' | 'in_progress' | 'completed' | 'cancelled')
├── location, scheduled_at
├── assigned_to (FK → profiles)
├── metadata (JSONB)
└── created_at, updated_at

sessions
├── id (UUID, PK)
├── activity_id (FK → activities)
├── user_id (FK → profiles)
├── mode ('passive' | 'chat' | 'media')
├── status ('active' | 'ended' | 'processing' | 'failed')
├── started_at, ended_at
├── ended_reason, processing_error
├── transcript (TEXT)
└── created_at, updated_at

ai_events
├── id (UUID, PK)
├── session_id (FK → sessions)
├── type ('observation' | 'lookup' | 'action')
├── content (TEXT)
├── source ('ai' | 'system' | 'user' | 'integration')
├── status ('pending' | 'completed' | 'skipped' | 'failed')
├── requires_confirmation (BOOLEAN)
├── action_label, external_record_id, external_record_url
├── metadata (JSONB), confidence (FLOAT)
└── created_at
    ↑ Enabled for Supabase Realtime

media_attachments
├── id (UUID, PK)
├── session_id (FK → sessions)
├── type ('photo' | 'video' | 'file')
├── storage_path, thumbnail_path
├── ai_analysis (TEXT)
├── mime_type, file_size_bytes
├── analysis_status ('pending' | 'completed' | 'failed' | 'skipped')
├── metadata (JSONB)
└── uploaded_at, created_at

session_summaries
├── id (UUID, PK)
├── session_id (FK → sessions, UNIQUE)
├── observation_summary (TEXT)
├── key_observations (JSONB array)
├── actions_taken (JSONB array)
├── action_statuses (JSONB array)
├── follow_ups (JSONB array)
├── external_records (JSONB array)
├── duration_seconds (INT)
├── confirmed_at
└── created_at

user_settings
├── id (UUID, PK)
├── user_id (FK → profiles, UNIQUE)
├── face_id_enabled, voice_output_enabled
├── voice_id, voice_speed (0.5–2.0)
├── confirmation_mode ('always' | 'smart' | 'off')
├── language, use_premium_tts
└── created_at, updated_at
    ↑ Auto-created for each new profile
```

### Triggers

| Trigger | On | Effect |
|---------|-----|--------|
| `handle_new_user` | `auth.users` INSERT | Auto-creates `profiles` row |
| `handle_new_profile_organization` | `profiles` INSERT | Auto-creates personal `organizations` row |
| `handle_new_profile_settings` | `profiles` INSERT | Auto-creates `user_settings` row |
| `sync_activity_status_from_session` | `sessions` INSERT/UPDATE | Syncs activity status (active → in_progress, ended → completed) |

### Storage Buckets

| Bucket | Public | Max Size | Allowed Types |
|--------|--------|----------|---------------|
| `media-attachments` | No | 52 MB | JPEG, PNG, WebP, MP4, PDF, DOCX |
| `avatars` | Yes | 5 MB | JPEG, PNG, WebP |

Storage paths use session IDs as folder names, enforced by RLS so users can only access files belonging to their own sessions.

## Flutter App

### State Management

Riverpod with the datasource → repository → provider pattern:

```
Screen (ref.watch)
    ↑
Provider / AsyncNotifier
    ↑
Repository (returns Result<T>)
    ↑
RemoteDatasource (Supabase queries / Firebase callable)
```

Provider types used: `Provider`, `FutureProvider`, `StateProvider`, `StateNotifierProvider`, `AsyncNotifierProvider`, `StreamProvider`.

### Routing

GoRouter with `StatefulShellRoute` for bottom navigation and auth redirect:

| Route | Screen | Purpose |
|-------|--------|---------|
| `/login` | LoginScreen | Email/password + Face ID |
| `/dashboard` | DashboardScreen | Activity list, create, search, filter |
| `/history` | HistoryScreen | Past sessions |
| `/settings` | SettingsScreen | TTS, biometrics, preferences |
| `/session/:activityId/passive` | PassiveListenScreen | One-way recording |
| `/session/:activityId/chat` | VoiceChatScreen | Two-way voice conversation |
| `/session/:activityId/media` | MediaCaptureScreen | Voice + photo/PDF analysis |
| `/session/:activityId/summary` | SummaryScreen | View/edit/export summary |

### Audio Pipeline

**Recording:** `record` package → PCM16 mono @ 16kHz → streaming `List<int>` chunks or file output.

**OpenAI Realtime voice:** PCM16 @ 16kHz input → base64 encode → WebSocket → OpenAI processes → base64 PCM16 @ 24kHz output → decode → accumulate → WAV wrap → `ConcatenatingAudioSource` → gapless playback via `just_audio`.

**ElevenLabs voice:** PCM16 @ 16kHz bidirectional WebSocket streaming. Signed URL obtained via Firebase Function. Dynamic variables (session_id, activity_context) passed at connection init.

### Key Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `go_router` | Declarative routing |
| `supabase_flutter` | Database, auth, storage |
| `cloud_functions` | Firebase callable functions |
| `dio` | HTTP client |
| `web_socket_channel` | WebSocket connections |
| `record` | Microphone recording |
| `just_audio` | Audio playback |
| `flutter_tts` | Device text-to-speech |
| `camera` | Camera capture |
| `image_picker` | Photo/gallery picker |
| `file_picker` | PDF/file selection |
| `local_auth` | Face ID / fingerprint |
| `flutter_secure_storage` | Encrypted credential storage |
| `freezed_annotation` | Immutable data classes |
| `pdf` | PDF generation for summary export |
| `share_plus` | Share via system sheet |

## Web App

A separate Next.js frontend in `web-app/` that reuses the same Supabase project and Firebase Functions deployment.

```bash
cd web-app && cp .env.example .env.local
cd web-app && npm run dev
cd web-app && npm run lint && npm run typecheck && npm run test:run && npm run build
```

**Required env vars:** `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `NEXT_PUBLIC_FIREBASE_FUNCTIONS_URL`

## Setup

### Flutter App

```bash
cp .env.example .env
# Fill in: SUPABASE_URL, SUPABASE_ANON_KEY, FIREBASE_FUNCTIONS_URL, WHISPER_PROXY_URL
flutter run --dart-define-from-file=.env
```

### Firebase Functions

```bash
cd firebase/functions
cp .env.example .env        # For local emulator
npm install
npm run serve               # Local emulator
npm run build               # Build only
```

**Production secrets (set via Firebase CLI):**

```bash
firebase functions:secrets:set GEMINI_API_KEY
firebase functions:secrets:set SUPABASE_URL
firebase functions:secrets:set SUPABASE_SERVICE_KEY
firebase functions:secrets:set OPENAI_API_KEY
firebase functions:secrets:set ELEVENLABS_API_KEY
firebase functions:secrets:set ELEVENLABS_AGENT_ID
```

### Supabase

Apply the SQL migrations before running the full app flow. The `media-attachments` bucket must remain private; `avatars` can remain public.

## Data Flow: End-to-End Session

```
1. User creates Activity (type: passive/twoway/media)
       │
2. User starts Session from Activity
       │
3. Session runs in selected mode:
       │
       ├─ Passive:  Audio → Whisper → Transcript → Gemini → ai_events
       ├─ Chat:     Audio ↔ ElevenLabs Agent ↔ Webhooks → ai_events
       └─ Media:    Audio ↔ OpenAI Realtime ↔ Tool calls → Camera/PDF
                                                    │
                                              analyzeImage / extractPdfText
                                                    │
                                              ai_events + media_attachments
       │
4. User ends Session
       │
5. generateSummary (Gemini Flash)
       ├─ Reads: transcript, ai_events, media_attachments
       └─ Writes: session_summaries (observation summary, key observations,
                  actions taken, follow-ups, external records)
       │
6. User reviews, edits, confirms, and exports summary (PDF / Markdown)
```
