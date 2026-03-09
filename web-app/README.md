# FieldFlow Web

Next.js web frontend for the existing FieldFlow backend.

## Stack

- Next.js App Router
- TypeScript
- Tailwind CSS
- Supabase SSR + browser clients
- Existing Firebase Functions deployment

## Environment

Copy `web-app/.env.example` to `web-app/.env.local` and fill in:

```bash
cp .env.example .env.local
```

Required values:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `NEXT_PUBLIC_FIREBASE_FUNCTIONS_URL`

The web app reuses the existing Supabase project and Firebase Functions backend. No separate backend directory is created inside `web-app/`.

## Commands

```bash
npm run dev
npm run lint
npm run typecheck
npm run test:run
npm run build
```

## Features

- Email/password auth with Supabase
- Dashboard with activity creation, search, and filtering
- Session history with delete + summary access
- Shared settings backed by `user_settings`
- Browser-native passive listen flow through `whisperProxy`
- Browser-native ElevenLabs chat flow through `getSignedConversationUrl`
- Media upload + analysis flow through `analyzeImage`
- Shared summary screen backed by `session_summaries`
