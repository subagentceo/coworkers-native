# CoworkersNative Architecture

iOS 18 + Swift 6 native app connecting to `coworkers-agent` Worker.

## Auth (L2)
- Email login → POST /api/login
- Session cookie stored in iOS Keychain (`kSecAttrAccessibleAfterFirstUnlock`)
- Mirrors Claude iOS app session_key pattern
- Shared via App Group `group.com.managedcoworkers.native` → Widget + Share Extension

## Services
- `AuthService` — Keychain + App Group sync
- `APIClient` — URLSession actor, all API endpoints
- `VoiceInputService` — AVFoundation + Workers AI whisper transcription

## Models
- `AppState.swift` — SwiftData local cache + @Observable ViewModel

## Views (iOS 18)
- `ContentView.swift` — @main + `.tabViewStyle(.sidebarAdaptable)`
- Conversations + Chat + Memory tabs
- iOS 18 ambient backgrounds, Dynamic Island safe area

## Targets
1. `CoworkersNative` — main app
2. `ShareExtension` — share URLs/PDFs into conversations
3. `CoworkersWidget` — WidgetKit small+medium home screen widget

## Backend
- Worker: `coworkers-agent` at agentknowledgeworkers.com
- Model: `@cf/meta/llama-3.1-8b-instruct` (Workers AI free tier)
- No Anthropic API key required
