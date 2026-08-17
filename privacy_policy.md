# Privacy Policy for Sakinah

**Last updated:** 16 August 2026

Sakinah Team operates the Sakinah mobile application (the "App"). This Privacy Policy explains what information the App collects, how it is used, and the choices you have.

By using Sakinah, you agree to the practices described in this policy.

---

## 1. Our Approach to Privacy

Sakinah is designed to work fully as a **guest**, with no account required. Authentication exists solely to let your preferences follow you across devices — it is never required to use any feature of the app.

If you use Sakinah as a guest, **no personal data leaves your device.** All preferences are stored locally only.

---

## 2. Information We Collect

### 2.1 Account Information (only if you choose to sign up)
If you create an account, we collect:
- Email address
- Display name
- Basic authentication metadata (account creation date, last sign-in)

Authentication is handled by **Supabase**, our backend provider. We do not receive or store your password directly.

### 2.2 Preferences
Whether or not you're signed in, the app stores your preferences, including:
- Quran font family and font size
- App language (Arabic/English) and theme (light/dark)
- Prayer time calculation method
- Location (GPS coordinates or a manually selected city)
- Notification settings (which prayers you've enabled reminders for)

**As a guest**, these are stored only in local storage on your device.
**If signed in**, these preferences are additionally synced to our database so they're available if you log in on another device.

### 2.3 Location Data
Location (from GPS or a manually entered city) is used exclusively to:
- Calculate accurate prayer times for your area
- Calculate the Qibla direction from your location

We do not use location data for advertising, tracking, or any purpose beyond these two calculations.

### 2.4 Notifications
If you enable prayer reminders, we use this information to schedule local notifications on your device and, where needed, to deliver push notifications via **Firebase Cloud Messaging** so reminders still arrive when the app is closed.

---

## 3. Third-Party Services We Use

Sakinah relies on a small number of third-party services to function. Here is exactly what each one does and what data it may receive:

| Service | Purpose | What it receives |
|---|---|---|
| **Supabase** | Authentication and syncing your preferences across devices | Email, display name, and preference data — only if you're signed in |
| **Firebase Cloud Messaging (Google)** | Delivering prayer reminder notifications when the app is closed | A device push token, used only to route notifications to your device |
| **AlAdhan API** | Verifying prayer time calculations and Hijri date conversion | Your location coordinates, sent per request to compute times — not stored by us on their servers beyond the request |
| **Quran text/translation API** (Al Quran Cloud / fawazahmed0) | Fetching the "Ayah of Today" verse | No personal or location data — only a request for verse content |

We do not sell your data to any third party, and we do not use it for advertising.

---

## 4. Guest Mode

If you use Sakinah without an account:
- No personal data is transmitted off your device for storage purposes
- All preferences remain in local device storage (SharedPreferences)
- You retain full access to every feature of the app

---

## 5. Data Storage and Security

- Preference data synced to our servers is stored in a Supabase-managed Postgres database, protected by row-level security so that each user can only access their own records.
- Authentication tokens are stored using your device's secure/platform-native storage.
- We do not store payment information — Sakinah does not currently process payments.

---

## 6. Data Retention and Deletion

- Preferences remain stored for as long as your account exists, or until you delete the app (for local/guest data).
- You may request deletion of your account and all associated data at any time by contacting us at mohamed.elhelbawy.ac@gmail.com. We will delete your data within 7 days of a verified request.

---

## 7. Your Rights

Depending on your location, you may have rights to:
- Access the personal data we hold about you
- Correct inaccurate data
- Request deletion of your data
- Withdraw consent (e.g., by logging out or revoking location/notification permissions)

To exercise any of these rights, contact us at mohamed.elhelbawy.ac@gmail.com.

---

## 8. Children's Privacy

Sakinah is not directed at children under 13 (or the relevant minimum age in your jurisdiction), and we do not knowingly collect personal information from children. If you believe a child has provided us with personal data, please contact us so we can remove it.

---

## 9. Changes to This Policy

We may update this Privacy Policy from time to time. Material changes will be reflected by an updated "Last updated" date at the top of this document.

---

## 10. Contact Us

If you have questions about this Privacy Policy or how your data is handled, contact us at:

**Sakinah Team**
mohamed.elhelbawy.ac@gmail.com