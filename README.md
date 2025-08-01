# 🌱 FocusTree App

A green, aesthetic Flutter productivity app that helps you stay focused and grow a virtual tree as you work.  
It’s a blend of task management and Pomodoro-style timers — with gamification built in.

Author: Maha Ibrahim
Email: Maha.Ibrahim@stud.srh-campus-berlin.de 
       mahasherif2604@gmail.com

---

##  Features

-  **Task Manager**
  - Add daily tasks
  - Set priority (Low, Medium, High) via dropdown
  - Priority color gradient (green → orange → red)
  - Tasks saved locally and persist on restart

-  **Custom Timer**
  - Choose your focus duration
  - Timer visual with countdown
  - Seeds grow into a full tree (seed1 → seed5.png) based on your focus time

-  **Design**
  - Aesthetic green color theme
  - Animated seed growth using Flutter animation
  - Custom font (`PlayfairDisplay`)

---

##  Folder Structure
lib/
main.dart # Single main file that contains all widgets
assets/
images/ # seed1.png → seed5.png, logo.png
fonts/ # PlayfairDisplay-Black.ttf
---

### 1. Clone the repo

git clone https://github.com/mahaibrahim26/FocusApp.git

cd practice

2. Install dependencies
flutter pub get

3. Run the app
flutter run

For iOS: Open ios/Runner.xcworkspace in Xcode, select your team, connect your iPhone, and run it.

### Font & Assets Setup

In pubspec.yaml:
flutter:
    fonts:
    - family: Playfair
      fonts:
        - asset: lib/fonts/PlayfairDisplay-Black.ttf
    assets:
        - assets/images/logo.png
        - assets/images/seed1.png
        - assets/images/seed2.png
        - assets/images/seed3.png
        - assets/images/seed4.png
        - assets/images/seed5.png

### Future Ideas
Focus streak tracking

Notifications when timer ends

Sync with Google Calendar

Made with Flutter
By @mahaibrahim26

![FocusTree Logo](assets/images/logo.PNG) 
