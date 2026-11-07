# Zero (Flutter 3.16 / Dart 3.2)

Port of the HTML game `zero_game.html`. The girl helper was removed: healing comes from
green orbs that spawn on the ground (and sometimes drop from monsters).

## Run
```
flutter create --platforms=android,ios .   # generates the platform folders (keeps lib/ and assets/)
flutter pub get
flutter run
```
Portrait orientation. Controls: on-screen joystick + attack/dash buttons (WASD/arrows, Space, E on desktop).

## CI
`.github/workflows/build.yml` generates the `android/` folder with `flutter create` (the repo doesn't ship it)
and then runs `flutter build apk --release`. If your IDE uses its own workflow, add the same
"Generate Android platform files" step before `flutter build apk`.
