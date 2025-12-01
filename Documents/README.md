# 🎓 School Dashboard – Cleveland's Learning Hub

Privacy-first school management with Eve-powered scheduling, CalDAV sync, and local AI helpers tailored for ADHD/ASD learning preferences.

## Overview
- **Assignments**: Track, upload documents, and sync with Apple Reminders/Calendar.
- **Calendar**: Natural-language planning, highlight conflicts, and break tasks into 90‑minute sessions with 15‑minute breaks.
- **Training**: Ingest GPX/FIT workouts, compute TSS/CTL/ATL/TSB, and render aggregated insights.
- **Research**: Index your Obsidian vault, search quickly, and surface notes in context.
- **Privacy**: All AI work happens locally (LM Studio, Ollama, or any HTTP-based LLM on `LOCAL_AI_URL`).

## Quick Start
1. **Configure credentials** in `.env`:
   ```bash
   APPLE_ID=you@icloud.com
   APPLE_APP_PASSWORD=xxxx-yyyy-zzzz
   LOCAL_AI_URL=http://127.0.0.1:1234
   LOCAL_API_TOKEN=replace-this-with-a-strong-secret
   CALDAV_URL=https://caldav.icloud.com/
   WORKOUT_SOURCE_DIR=~/Library/Mobile Documents/iCloud~com~altifondo~HealthFit
   ```
   - Optional: define `LOCAL_API_TOKENS=token1,token2` when you want to rotate keys without restarting the server.
2. **Start the dashboard**:
   ```bash
   ./start.sh
   ```
3. **Browse the workspaces**:
   - **/school** – Main dashboard with status, assignments, and Eve chat.
   - **/calendar** – Calendar view with natural-language scheduling helpers.
   - **/assignments** – Spreadsheet-like tracker with sync toggles.
   - **/training** – Workout analytics with aggregated TSS/CTL/ATL series.
   - **/research** – Obsidian vault insights.

> **API access**: all `/api/*`, `/ai/*`, and `/school` routes now require `Authorization: Bearer <LOCAL_API_TOKEN>` (or a token listed via `LOCAL_API_TOKENS`). Include that header in scripts and tools that call the protected endpoints.

## Architecture Highlights
- All heavy summaries (workout aggregates, assignment stats) are persisted under `data/` (`workout_aggregates.json`, `assignments_summary.json`) and only recomputed when source files change.
- `/api/events` and `/api/reminders` use short-TTL caches with background refresh threads so the UI always sees fast responses while CalDAV/Reminders syncs run in the background.
- Preload routines run at import time (`preload_data()`) to warm the caches before the first HTTP request hits the server.
- Eve chat runs on every page via `static/chat.js`, sending the current page path/title/time so responses stay contextual.

## Apple Reminders Integration
- Uses CalDAV (same credentials as Calendar) to create `VTODO` objects when assignments are saved.
- Priority map: `high → 1`, `normal → 5`, `low → 9`.
- Dashboard displays up to five active reminders with due dates, priority, and days until due.
- Endpoints:
  - `GET /api/reminders?include_completed=false` – returns cached reminders (refresh with `refresh=1`).
  - `POST /api/reminders` – creates a reminder from the dashboard (title, due date, priority, notes).
- Recommended workflow:
  1. Add assignment from `/assignments`, leave “Sync with Apple Reminders” checked.
  2. Work remains visible in the dashboard and Apple Reminders app (iCloud sync takes ~1-2 min).
  3. For high-priority tasks, turn on Calendar sync to generate Eve-created study sessions.

## Intelligent Scheduling & Optimization
- Eve automatically applies scheduling windows: homework ≤14 days out, quizzes ≤21, exams ≤30.
- Auto-rearrangement steps in when a new high-priority task needs time; it temporarily shifts lower-priority study blocks to preserve focus.
- Workout ingestion now re-parses only modified FIT/GPX files and persists computed aggregates to accelerate `/training` metrics.
- The Eve chat prompt includes the current workspace, time, and contextual counts so responses stay anchored to what you’re viewing.
- Optional environment tweaks:
  ```bash
  STUDY_SESSION_DURATION=90
  INCLUDE_BREAKS=true
  BREAK_DURATION=15
  FTP_RUNNING_SPEED=3.8
  WORKOUT_CACHE_TTL=300
  ```

## Documents & Commands
- `start.sh` – Single entry point that creates `.venv`, installs dependencies, and boots the Flask app.
- `app_web/web_app.py` – All HTTP routes, workout parsing, caching, and reminders API.
- `app_web/eve_ai.py` – Determines session plans for assignments.
- `app_web/local_ai.py` – Legacy helpers and AI client wrappers.
- `app_web/obsidian_index.py` – Vault indexing utilities.
- `static/chat.js` – Always-on Eve chat launcher/modal.

## Troubleshooting
- **No calendars/reminders found**: Double-check `.env` credentials and ensure the app-specific password has CalDAV permissions.
- **Workouts not appearing**: Ensure `WORKOUT_SOURCE_DIR` points to your HealthFit export (default: `~/Library/Mobile Documents/iCloud~com~altifondo~HealthFit`).
- **Eve offline**: Start LM Studio/Ollama on `LOCAL_AI_URL`. The chat still works with cached fallback replies.
- **Assignments summary stale**: Delete `data/assignments_summary.json` and the next request recomputes the cached stats.
- **Events/reminders lag**: `/api/events` and `/api/reminders` cache results for ~45-60s; add `?refresh=1` to force a background rebuild.

## What’s Removed
- Duplicate markdowns, shells, and legacy scripts were consolidated into this README and `start.sh` per the optimization report. The new structure keeps just the essential documentation, script, and data files.
