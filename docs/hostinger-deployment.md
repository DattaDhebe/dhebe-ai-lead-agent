# Hostinger deployment

## Recommended production URLs

- Main API URL: `https://dhebe.com/api`
- Optional subdomain for landing page or future admin panel: `https://aileadagent.dhebe.com`

You already have `aileadagent.dhebe.com`, so there is no need to create another subdomain unless you want a separate staging host.

## 1. Create or confirm the MySQL database

In Hostinger:

1. Open `Websites`.
2. Select `dhebe.com`.
3. Open `Databases`.
4. Open `MySQL Databases`.
5. Confirm or create the database `u942725982_ai_lead_agent`.
6. Note the database host, username, password, and port.

## 2. Import the schema

1. Open phpMyAdmin for `u942725982_ai_lead_agent`.
2. Click `Import`.
3. Upload [setup.sql](/f:/apps/android/dhebe-ai-lead-agent/database/setup.sql).
4. Run the import.
5. Optionally import [seed.sql](/f:/apps/android/dhebe-ai-lead-agent/database/seed.sql) after a real user exists.

## 3. Configure the backend environment

1. Copy `backend/.env.example` to `backend/.env`.
2. Set:
   - `DB_HOST`
   - `DB_PORT`
   - `DB_NAME=u942725982_ai_lead_agent`
   - `DB_USER`
   - `DB_PASS`
   - `JWT_SECRET`
   - `GEMINI_API_KEY`
3. Leave `OPENAI_API_KEY` empty for now unless you add that adapter later.

## 4. Upload backend files to `public_html/api`

In Hostinger File Manager:

1. Open `public_html`.
2. Create a folder named `api` if it does not exist.
3. Upload the contents of [backend](/f:/apps/android/dhebe-ai-lead-agent/backend) into `public_html/api`.

The final server structure should look like this:

```text
public_html/
`-- api/
    |-- index.php
    |-- .env
    |-- .htaccess
    |-- auth/
    |-- leads/
    |-- reminders/
    |-- business-profile/
    |-- feedback/
    |-- ai/
    |-- config/
    |-- helpers/
    |-- middleware/
    `-- services/
```

## 5. Confirm live endpoints

After upload, these should resolve:

- `https://dhebe.com/api/index.php`
- `https://dhebe.com/api/auth/register.php`
- `https://dhebe.com/api/auth/login.php`
- `https://dhebe.com/api/leads/list.php`
- `https://dhebe.com/api/ai/generate-reply.php`

## 6. Flutter API base URL

The app currently uses:

```text
https://dhebe.com/api
```

If you intentionally deploy the API somewhere else, update:

- [app_constants.dart](/f:/apps/android/dhebe-ai-lead-agent/mobile/lib/core/constants/app_constants.dart)

## 7. Optional use of the existing subdomain

`aileadagent.dhebe.com` is useful for:

- A landing page for the Android app
- A future admin dashboard
- A staging copy of the backend or docs

For this MVP, it is optional. The mobile app can ship with the API hosted at `https://dhebe.com/api`.
