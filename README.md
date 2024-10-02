iOS Toolkit for Sign Language Recognition integration

# Installation Guide
1. Make sure your phone is in development mode: https://docs.expo.dev/guides/ios-developer-mode/. 
2. Make sure you have an account tied in Xcode using your apple_id or phone number along with the password. Press Command + , and go to accounts. 
3. Come to this view in the app and configure the Team and Bundle Indentifier. 
4. If needed, download brew like so: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
5. Ff needed, download cocoa pods like so: `brew install cocoapods`
6. In the terminal, cd until you get to root directory of your Xcode project. If you see the file with the .xcodeproj extension, you’re in the right place. 
7. Run the following to get the dependency: `pod install`. This could take a while just be patient! It’ll give you a clear success message after its done
8. Open the project in Xcode with the following command: `open <filename>.xcworkspace`. 
9. Click build with your phone connected your laptop. Keep your phone unlocked. Enter your computer password if prompted. You’ll get an error if the phone doesn’t trust the app. In that case, on your phone, go to settings > VPN & Device management > click on your developer app and click trust.
10. The app should be up and running on your phone now!

Designed and Maintained by
- Ananay Gupta (ananay@gatech.edu)
- Shriviniyak Eshwa
- and the Fall 2024 VIP team
