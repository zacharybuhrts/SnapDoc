# SnapDoc

SnapDoc is an iPhone document scanner. Open the app, photograph a page (or import one from Photos), straighten the corners, pick a clean document look, and save a multi-page PDF or a set of images. Everything stays on the phone, in the app’s Documents folder.

It is a native SwiftUI app for iOS 17 and later. There are no extra packages to install.

## Install it on your iPhone

You need:

- An Apple Silicon MacBook (M1, M2, M3, M4, or newer)
- A free Apple ID
- An iPhone running iOS 17 or later, and a cable that can carry data
- Xcode from the Mac App Store

The steps below use that free Apple ID. You do not need a paid Apple Developer membership to run SnapDoc on your own phone.

### 1. Install Xcode

1. Open the **App Store** on your Mac.
2. Search for **Xcode** and install it. The download is large, so leave the Mac plugged in.
3. Open Xcode once and let it install the extra iOS components it asks for.
4. If macOS asks about command-line tools, install those too.

Use the Xcode build made for Apple Silicon. The App Store version on an Apple Silicon Mac is the right one.

### 2. Get the project

If you already have this folder, skip ahead. Otherwise, in Terminal:

```bash
git clone https://github.com/zacharybuhrts/SnapDoc.git
cd SnapDoc
open SnapDoc.xcodeproj
```

You can also double-click `SnapDoc.xcodeproj` in Finder. Open that file, not a folder inside it.

The Xcode project is already generated, so you do not need extra tools to open it. `project.yml` is there if you later want to regenerate the project with [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`, then `xcodegen generate` in this folder).

### 3. Sign in with your Apple ID

1. In Xcode, choose **Xcode > Settings…** (or **Preferences…** on older Xcode).
2. Open the **Accounts** tab.
3. Click **+**, choose **Apple ID**, and sign in with the Apple ID you use for the App Store.

That account’s **Personal Team** is what signs the app onto your phone.

### 4. Choose your Personal Team

The project is set to automatic signing, and the team is left blank on purpose so it is not locked to someone else’s Apple ID.

1. In the project navigator, click the blue **SnapDoc** project icon.
2. Select the **SnapDoc** target (the app, not SnapDocTests).
3. Open **Signing & Capabilities**.
4. Check **Automatically manage signing**.
5. In the **Team** menu, choose the team that shows your name and **(Personal Team)**.

Do the same for the **SnapDocTests** target if Xcode complains about that target’s signing.

The bundle identifier is `com.zacharybuhrts.SnapDoc`. The test bundle is `com.zacharybuhrts.SnapDoc.tests`. If Xcode says the identifier is already in use by another account, change the app’s bundle identifier to something unique, such as `com.zacharybuhrts.SnapDoc.mine`, and let the test identifier follow it.

### 5. Turn on Developer Mode on the iPhone

Apple hides this switch until a development app tries to install.

1. Plug the iPhone into the Mac. Unlock the phone.
2. If the phone asks you to **Trust This Computer**, tap Trust and enter the passcode.
3. In Xcode’s toolbar, click the device menu (next to the SnapDoc scheme) and choose your iPhone. Do not choose **My Mac** or an Apple Watch. SnapDoc is iPhone-only.
4. Press the **Run** button (the play triangle), or press **Command-R**.

The first build takes a few minutes. The phone may say that Developer Mode is required.

5. On the iPhone, open **Settings > Privacy & Security > Developer Mode**.
6. Turn **Developer Mode** on. The phone restarts.
7. After it boots, confirm that you want to turn Developer Mode on.
8. Unlock the phone, go back to Xcode, and press **Run** again.

### 6. Trust the developer certificate

The first time the signed app is installed, iOS will not open it until you trust your own certificate.

1. On the iPhone, open **Settings > General > VPN & Device Management**.
2. Under **Developer App**, tap the certificate that shows your Apple ID email.
3. Tap **Trust**, then confirm.

Go back to the home screen and open **SnapDoc**. When iOS asks to use the camera, tap **Allow**.

### 7. What happens after 7 days

A free Apple ID certificate lasts **7 days**. After that, SnapDoc stays on the home screen but will not open. iOS shows a message that the developer is no longer trusted or that the app needs to be verified again.

To reinstall:

1. Plug in the iPhone and unlock it.
2. Open `SnapDoc.xcodeproj` in Xcode.
3. Choose your iPhone as the run destination.
4. Press **Run**.

Xcode signs a fresh copy and installs it. You get another 7 days. If Run fails or the icon still will not open, delete SnapDoc from the home screen (long-press the icon, Remove App) and press **Run** again. If Settings asks you to trust the developer, do that step once more.

A paid Apple Developer membership ($99 a year) removes the 7-day limit. You do not need it to try the app.

## Camera, simulator, and Photos

The document camera uses the real iPhone camera. **The iOS Simulator has no camera**, so `VNDocumentCameraViewController` is unavailable there. On a simulator, SnapDoc stays on the capture screen and tells you to import a photo instead. The **Scan Document** button explains the same thing.

**Import from Photos works in the Simulator:**

1. In Xcode, choose an iPhone simulator as the run destination and press Run.
2. Drag a few pictures of documents from your Mac onto the Simulator window. They land in the Simulator’s Photos library. You can also open the Photos app in the Simulator and check that the pictures are there.
3. In SnapDoc, tap **Import from Photos**, select one or more pictures, and continue through crop, filters, and save.

Import uses the system photo picker. SnapDoc does not ask for broad photo-library access, so there is no photo-library usage string in Info.plist. The camera usage string is `NSCameraUsageDescription`. Saving and sending files goes through the share sheet, which includes **Save to Files**.

## Using SnapDoc

On a real iPhone the app opens straight into the document camera. You can capture several pages, then tap Save in the camera UI. If you cancel, you land on the home screen, where you can scan again, import from Photos, or open the library.

For each page you can:

- **Crop** — drag the four corners if the detected page is wrong. **Detect** runs rectangle detection again. **Full Page** uses the whole image.
- **Rotate** — turn the page clockwise.
- Choose **Original**, **Color**, **Grayscale**, or **Black & White**. Color is the default document look (stronger contrast and a little sharpening). Black & White is a high-contrast monochrome page.

**Save** writes the scan into the library as a PDF, JPEG, or PNG. A PDF is one multi-page file. JPEG and PNG keep one image per page. After saving, share it from the confirmation, or later from the library.

The library shows a thumbnail, the name, and the date. Open a scan to flip through pages. Rename, delete, or share it from the page menu or by long-pressing a thumbnail. Search is at the top of the library.

Saved scans live in the app’s Documents directory, under `Scans`. Because file sharing is turned on, you can also browse them in the **Files** app: **On My iPhone > SnapDoc > Scans**. Each scan is a folder. PDF scans include `document.pdf`. Sharing from inside SnapDoc is the simpler way to send a file.

## Run the tests

The tests cover enhancement settings, corner and crop math, PDF generation, and gallery storage. They do not use the camera.

1. In Xcode’s device menu, choose any **iPhone simulator**.
2. Choose **Product > Test**, or press **Command-U**.

## Project settings

| Setting | Value |
| --- | --- |
| Display name | SnapDoc |
| Bundle identifier | `com.zacharybuhrts.SnapDoc` |
| Tests bundle identifier | `com.zacharybuhrts.SnapDoc.tests` |
| Devices | iPhone only (target device family 1) |
| Deployment target | iOS 17.0 |
| `LSRequiresIPhoneOS` | Yes |
| Mac Catalyst | Off |
| Designed for iPhone on Mac | Off |
| Signing | Automatic, development team left empty |
| Launch screen | Generated from the `LaunchBackground` color |
| Privacy manifest | `SnapDoc/PrivacyInfo.xcprivacy` |

## If something goes wrong

- **“Signing for SnapDoc requires a development team.”** Select your Personal Team under Signing & Capabilities for both targets.
- **The iPhone never appears in the device menu.** Unlock the phone, trust the computer, try another cable, and look in **Window > Devices and Simulators**.
- **The app installs but closes immediately, or iOS says it cannot be verified.** Trust the developer under **Settings > General > VPN & Device Management**, or the 7-day certificate expired and you need to Run again from Xcode.
- **Developer Mode is missing.** Press Run once with the phone connected, then look again under **Settings > Privacy & Security**.
- **The camera screen never appears.** You are probably in the Simulator. Use a real iPhone, or tap **Import from Photos**.
