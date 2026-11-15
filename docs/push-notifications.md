# Phone push notifications: setup

Notifications already reach people in the app and by email. This turns on **phone push**, so a notification also arrives when the app is closed. It uses Firebase Cloud Messaging (free). The code is finished and does nothing until you do the steps below, so nothing breaks in the meantime.

How it fits together: the API sends each new notification to the person's registered phones through Firebase; the app gives the server its phone's token when someone signs in; tapping a push opens the right screen.

## What only you can do (about 20 minutes)

### 1. Create the Firebase project
1. Go to https://console.firebase.google.com and **Add project** (for example "FCU Student Community"). Google Analytics is not needed.
2. **Project settings > General > Your apps > Add app**:
   - **Android**: package name `com.example.focus_1` (that is what the app uses today; see the note at the end).
   - **iOS**: bundle id `com.example.focus1`.
   You do **not** need to download `google-services.json` or `GoogleService-Info.plist`: the app is given the identifiers at build time.
3. Write down these values (Project settings > General > Your apps):
   - Project ID, and **Project number** (this is the sender id)
   - Android: **App ID** (`1:...:android:...`) and the **Web/Android API key**
   - iOS: **App ID** (`1:...:ios:...`) and its API key

### 2. Let the server send (the one secret)
1. **Project settings > Service accounts > Generate new private key.** This downloads a `.json` file. Treat it like a password.
2. On the server, put the file's contents in `api/.env` as one line, or save the file and point to it:
   ```
   FCM_SERVICE_ACCOUNT_FILE=/srv/secrets/fcu-firebase.json
   ```
   (or `FCM_SERVICE_ACCOUNT_JSON={"type":"service_account",...}`). Then restart the API: `pm2 restart focus-api --update-env`.
3. In Google Cloud, make sure the **Firebase Cloud Messaging API** is enabled for the project (Firebase does this for new projects).

### 3. iPhones only
Apple delivers iPhone pushes. You need an Apple Developer account, then:
1. In the Apple Developer site create an **APNs Authentication Key** (Keys > + > Apple Push Notifications service) and download the `.p8`.
2. In Firebase: **Project settings > Cloud Messaging > Apple app configuration > Upload** the `.p8` with its Key ID and your Team ID.
3. In Xcode, for the Runner target, add the **Push Notifications** capability and the **Background Modes > Remote notifications** capability.
Android needs none of this.

### 4. Give the app the identifiers
In GitHub: **Settings > Secrets and variables > Actions > Variables**, add (these are public identifiers, not secrets):

| Variable | Value |
|---|---|
| `FCM_PROJECT_ID` | Project ID |
| `FCM_SENDER_ID` | Project number |
| `FCM_API_KEY_ANDROID` | Android API key |
| `FCM_APP_ID_ANDROID` | Android App ID |
| `FCM_API_KEY_IOS` | iOS API key |
| `FCM_APP_ID_IOS` | iOS App ID |
| `FCM_IOS_BUNDLE_ID` | `com.example.focus1` |

Then build a new app version (push a `mobile-v*` tag, or run the workflow). For a local build add the same values as `--dart-define=NAME=value`.

### 5. Check it works
1. Install the new app, sign in with a **system admin** account, and allow notifications.
2. In the back office open **Settings > Phone push notifications**. It should say "Connected" and show 1 phone registered.
3. Press **Send a test to my phone**. If anything is wrong, the message names the cause (for example a missing key, or no phone registered).
4. Close the app and ask someone to reply to one of your posts: a push should arrive, and tapping it opens that screen.

## How it behaves
- A push is sent for every notification that lands in a person's inbox. If they muted that kind, or staff switched it off in **Notifications**, no push is sent either.
- While the app is open the notification appears from the live connection as before; Firebase delivers only when the app is in the background or closed, so nobody gets two.
- Phones that were uninstalled or signed out are removed automatically.
- `PUSH_ENABLED=false` on the server switches push off without removing the key.

## Good to know
- **The app id is still the template default** (`com.example.focus_1` / `com.example.focus1`). Whatever you register in Firebase must match what the app is built with. Changing an app id later means people have to reinstall (updates will not install over it), so decide on the permanent ids (for example `org.focusuganda.fcu`) **before** the first real release, then register those in Firebase.
- Push messages only carry the title, text and where to open; the full notification is still fetched from the API after sign-in.
- Not yet verified on a real phone: the Android and iPhone builds with the new Firebase packages have not been run on a device here. The first build and the test in step 5 are the check.
