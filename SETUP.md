# myEA - Setup Guide

Complete guide to set up, configure, and install the myEA mobile app.

## Prerequisites

- **Flutter** >= 3.11.0 (`flutter --version`)
- **Node.js** 20 (`node --version`)
- **Xcode** (for iOS builds)
- **CocoaPods** (`sudo gem install cocoapods`)
- **Firebase CLI** (`npm install -g firebase-tools`)
- **Supabase CLI** (`brew install supabase/tap/supabase`)
- **Git**

## 1. Clone and Install Dependencies

```bash
git clone <repo-url>
cd voice-mobile

# Flutter dependencies
flutter pub get

# iOS pods
cd ios && pod install && cd ..

# Firebase functions dependencies
cd firebase/functions && npm install && cd ../..
```

## 2. Create a Supabase Project

1. Go to [supabase.com/dashboard](https://supabase.com/dashboard) and create a new project
2. Note down:
   - **Project URL** (Settings > API) e.g. `https://xxxxx.supabase.co`
   - **Anon Key** (Settings > API > `anon` `public`)
   - **Service Role Key** (Settings > API > `service_role` `secret`)

### Run Database Migrations

Link the CLI to your project and push all migrations:

```bash
supabase login
supabase link --project-ref <your-project-ref>
supabase db push
```

This creates all tables (`profiles`, `organizations`, `activities`, `sessions`, `ai_events`, `media_attachments`, `session_summaries`, `user_settings`), RLS policies, triggers, and storage buckets.

### Enable Realtime

In the Supabase Dashboard:
1. Go to **Database > Replication**
2. Enable realtime for the `ai_events` table

## 3. Create a Firebase Project

1. Go to [console.firebase.google.com](https://console.firebase.google.com) and create a new project
2. Enable **Cloud Functions** (requires Blaze plan)
3. Link the project locally:

```bash
firebase login
firebase use --add
# Select your project and give it an alias (e.g. "default")
```

### Generate Firebase Options for Flutter

```bash
flutterfire configure
```

This generates `lib/firebase_options.dart` with your project's API keys. Select iOS (bundle ID: `com.myea.app`) and Android when prompted.

### Set Firebase Secrets

These secrets are used by Cloud Functions at runtime:

```bash
firebase functions:secrets:set GEMINI_API_KEY
firebase functions:secrets:set OPENAI_API_KEY
firebase functions:secrets:set SUPABASE_URL
firebase functions:secrets:set SUPABASE_SERVICE_KEY
firebase functions:secrets:set ELEVENLABS_API_KEY
firebase functions:secrets:set ELEVENLABS_AGENT_ID
```

| Secret | Source |
|---|---|
| `GEMINI_API_KEY` | [Google AI Studio](https://aistudio.google.com) |
| `OPENAI_API_KEY` | [OpenAI Platform](https://platform.openai.com) |
| `SUPABASE_URL` | Supabase Dashboard > Settings > API |
| `SUPABASE_SERVICE_KEY` | Supabase Dashboard > Settings > API > `service_role` key |
| `ELEVENLABS_API_KEY` | [ElevenLabs](https://elevenlabs.io) |
| `ELEVENLABS_AGENT_ID` | ElevenLabs > Conversational AI > Your Agent |

### Deploy Cloud Functions

```bash
cd firebase/functions
npm run build
cd ../..
firebase deploy --only functions
```

After deploying, note the **Functions URL** from the Firebase Console (e.g. `https://us-central1-your-project.cloudfunctions.net`).

## 4. Configure Environment Variables

```bash
cp .env.example .env
```

Edit `.env` with your values:

```env
APP_ENV=development

# Supabase (Dashboard > Settings > API)
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key

# Firebase Cloud Functions (Firebase Console > Functions)
FIREBASE_FUNCTIONS_URL=https://us-central1-your-project-id.cloudfunctions.net

# Whisper proxy URL
WHISPER_PROXY_URL=https://us-central1-your-project-id.cloudfunctions.net/whisperProxy
```

### Local Firebase Development (Optional)

For running Firebase functions locally with the emulator:

```bash
cp firebase/functions/.env.example firebase/functions/.env.local
```

Edit `firebase/functions/.env.local` with API keys for local testing.

## 5. iOS Setup

### Signing

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the **Runner** target
3. Go to **Signing & Capabilities**
4. Select your **Team** and set the **Bundle Identifier** to `com.myea.app`

### Permissions

The app requires these permissions (already configured in `Info.plist`):
- **Microphone** - audio recording during sessions
- **Camera** - photo/video capture
- **Face ID** - biometric authentication

## 6. Run on iPhone

### Via USB

```bash
# Plug in your iPhone, then:
flutter run --release --dart-define-from-file=.env
```

### Via Wi-Fi (Wireless)

1. Ensure your iPhone and Mac are on the **same Wi-Fi network**
2. iPhone must have **Developer Mode** enabled (Settings > Privacy & Security > Developer Mode)
3. iPhone must be **unlocked**

```bash
# Find your device ID
flutter devices

# Run on your iPhone
flutter run --release --dart-define-from-file=.env -d <device-id>
```

### Build IPA (for distribution)

```bash
flutter build ipa --release --dart-define-from-file=.env
```

The IPA will be at `build/ios/ipa/`.

## 7. Run on Android

```bash
# Debug
flutter run --dart-define-from-file=.env

# Release APK
flutter build apk --release --dart-define-from-file=.env

# Release App Bundle (for Play Store)
flutter build appbundle --release --dart-define-from-file=.env
```

## Architecture Overview

```
Flutter App (mobile)
  ├── Supabase Auth (email/password + Face ID)
  ├── Supabase Database (activities, sessions, events)
  ├── Supabase Storage (media attachments, avatars)
  └── Firebase Cloud Functions
        ├── OpenAI Whisper (transcription)
        ├── OpenAI Realtime (voice conversations)
        ├── OpenAI TTS (text-to-speech)
        ├── Google Gemini (chat, vision, summaries)
        └── ElevenLabs (conversational AI agent)
```

## Troubleshooting

### "Missing required runtime config" error
You forgot `--dart-define-from-file=.env`. Always run with:
```bash
flutter run --dart-define-from-file=.env
```

### iPhone not detected wirelessly
- Unlock the phone
- Enable Developer Mode (Settings > Privacy & Security > Developer Mode)
- Same Wi-Fi network as your Mac
- Try `flutter devices --device-timeout 15`

### Firebase functions deploy fails
```bash
cd firebase/functions
npm run build   # Fix TypeScript errors first
firebase deploy --only functions
```

### Supabase signup fails with "Database error saving new user"
Re-run the migrations:
```bash
supabase db push
```

### Pod install fails
```bash
cd ios
pod deintegrate
pod install
cd ..
```
