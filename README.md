# Dhebe AI Lead Agent

## Project overview

Dhebe AI Lead Agent is an MVP Android lead follow-up app for small businesses. It uses a Flutter mobile app for the client experience and a plain PHP + MySQL backend for authentication, lead management, reminders, business profile data, feedback collection, and Gemini-powered reply drafting.

The app is designed around a safe WhatsApp workflow:

- The app generates a suggested reply.
- The user reviews it.
- The user manually opens WhatsApp with the drafted message.
- The app never sends messages automatically.

## Features

- JWT-based register and login flow
- Secure token storage in Flutter
- Dashboard with lead and reminder summaries
- Leads list, create flow, details view, update flow, and delete flow
- AI reply generator with Gemini as the primary provider
- Manual WhatsApp open/copy flow
- Follow-up reminder creation and today reminders list
- Business profile and FAQ setup for safer AI prompting
- Feedback submission screen
- Light and dark theme support

## Tech stack

- Mobile: Flutter, Provider, `http`, `flutter_secure_storage`, `intl`, `url_launcher`
- Backend: Plain PHP, PDO, JWT helper, cURL-based Gemini integration
- Database: MySQL
- Hosting target: Hostinger shared hosting

## Folder structure

```text
.
|-- backend
|   |-- ai
|   |-- auth
|   |-- business-profile
|   |-- config
|   |-- feedback
|   |-- helpers
|   |-- leads
|   |-- middleware
|   |-- reminders
|   |-- services
|   |-- .env.example
|   |-- .htaccess
|   `-- index.php
|-- database
|   |-- setup.sql
|   `-- seed.sql
|-- docs
|   |-- flutter-setup.md
|   `-- hostinger-deployment.md
`-- mobile
```

## Flutter setup commands

```powershell
cd mobile
F:\apps\android\flutter\bin\flutter.bat pub get
F:\apps\android\flutter\bin\flutter.bat run
```

Release build:

```powershell
cd mobile
F:\apps\android\flutter\bin\flutter.bat build apk --release
```

## Backend setup steps

1. Copy `backend/.env.example` to `backend/.env`.
2. Fill in your Hostinger MySQL credentials.
3. Set `DB_NAME=u942725982_ai_lead_agent` unless you intentionally created a different database.
4. Generate a long `JWT_SECRET`.
5. Add your Gemini API key to `GEMINI_API_KEY`.
6. Keep `CORS_ALLOWED_ORIGIN=*` for this mobile MVP unless you later add a browser-based admin panel.

## Hostinger deployment steps

Full guide: [docs/hostinger-deployment.md](/f:/apps/android/dhebe-ai-lead-agent/docs/hostinger-deployment.md)

Short version:

1. Create or confirm the MySQL database in Hostinger.
2. Import [database/setup.sql](/f:/apps/android/dhebe-ai-lead-agent/database/setup.sql) in phpMyAdmin.
3. Copy `backend/.env.example` to `backend/.env` and update it.
4. Upload the contents of [backend](/f:/apps/android/dhebe-ai-lead-agent/backend) into `public_html/api`.
5. Confirm these live paths exist:
   - `public_html/api/index.php`
   - `public_html/api/auth/login.php`
   - `public_html/api/leads/list.php`
   - `public_html/api/config/bootstrap.php`
6. Keep the mobile API base URL set to `https://dhebe.com/api`.

## MySQL setup steps

1. Create a database named `u942725982_ai_lead_agent` in Hostinger, or update `.env` if you use a different name.
2. Open phpMyAdmin for that database.
3. Import [database/setup.sql](/f:/apps/android/dhebe-ai-lead-agent/database/setup.sql).
4. Optionally import [database/seed.sql](/f:/apps/android/dhebe-ai-lead-agent/database/seed.sql) after registering a real user.

## Gemini API key setup

1. Create a Gemini API key in your Google AI project.
2. Put the key in `backend/.env` as `GEMINI_API_KEY`.
3. Keep the key only on the backend.
4. Do not expose the key in Flutter, APK assets, or client-side code.

## API base URL

The app is configured for:

```text
https://dhebe.com/api
```

Your existing `aileadagent.dhebe.com` subdomain is optional. It can be used later for a landing page, admin panel, or staging area, but it is not required for the Android app to work.

## Google Play privacy and safety notes

- The app stores login tokens securely on-device.
- Customer leads, reminder data, feedback, and generated replies are stored on your backend database.
- AI output is a draft only and must be reviewed by the business user before sending.
- The app does not automate or auto-send WhatsApp messages.
- API keys and database credentials stay on the server.

## Next version roadmap

- Add optional OpenAI adapter behind the same backend AI service
- Add richer lead notes timeline and reminder completion flow
- Add CSV import/export for leads
- Add push notifications for reminders
- Add an admin web dashboard on `aileadagent.dhebe.com`
- Add analytics, audit logs, and role-based access
