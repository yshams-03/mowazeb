# Android permissions — merge into android/app/src/main/AndroidManifest.xml
# inside the <manifest> tag (before <application>):

# <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
# <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
# <uses-permission android:name="android.permission.INTERNET" />
# <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

# iOS — merge into ios/Runner/Info.plist:

# <key>NSLocationWhenInUseUsageDescription</key>
# <string>UmmahPulse needs your location to calculate accurate prayer times.</string>
# <key>NSLocationAlwaysUsageDescription</key>
# <string>UmmahPulse needs your location to calculate accurate prayer times.</string>

# Google Sign-In (Android): add SHA-1 fingerprint in Firebase Console.
# iOS: add reversed client ID URL scheme from GoogleService-Info.plist.
