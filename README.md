# Zero (Flutter 3.16 / Dart 3.2)

Port of the HTML game `zero_game.html`. The girl helper was removed: healing comes from
green orbs that spawn on the ground (and sometimes drop from monsters).

## Run
```
flutter pub get
flutter run
```
Portrait orientation. Controls: on-screen joystick + attack/dash buttons (WASD/arrows, Space, E on desktop).

## Android
The `android/` folder is included (Gradle Kotlin DSL: AGP 8.11.1, Gradle 8.14, Kotlin 2.2.20), so `flutter build apk --release` works directly.
