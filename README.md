# 💪 SmartDumbbell - Application Mobile

Application Flutter pour le système SmartDumbbell avec ESP32-C3 Mini + MPU6050.

## 📱 Fonctionnalités

- ✅ Connexion Bluetooth BLE à l'ESP32
- ✅ Détection automatique des répétitions
- ✅ Analyse de la forme en temps réel
- ✅ Comptage des séries et reps
- ✅ Score de qualité (bonne/mauvaise forme)
- ✅ Historique complet des workouts
- ✅ Statistiques et graphiques de progression
- ✅ Base de données SQLite locale

## 🏋️ Exercices supportés

- 🦵 Squats
- 💪 Pompes
- 🏋️ Tractions
- 🔥 Burpees
- 🦿 Fentes
- 💪 Dips
- 🔲 Abdos/Crunchs
- ⏱️ Planches

## 🚀 Installation

### Télécharger l'APK

1. Va dans l'onglet **"Actions"** en haut
2. Clique sur le dernier build réussi (coche verte ✅)
3. Descends jusqu'à **"Artifacts"**
4. Télécharge **"SmartDumbbell-APK"**
5. Extrais le ZIP et installe l'APK sur ton téléphone

### Compiler toi-même

```bash
flutter pub get
flutter build apk --release
```

L'APK sera dans : `build/app/outputs/flutter-apk/app-release.apk`

## 🔌 Connexion à l'ESP32-C3

### UUIDs Bluetooth

```cpp
#define SERVICE_UUID "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define DATA_CHAR_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define CMD_CHAR_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a9"
```

### Format des données

**ESP32 → App :**
```json
{
  "angle": 45.5,
  "reps": 12,
  "isMovingUp": true,
  "status": "Montée"
}
```

**App → ESP32 :**
```json
{
  "cmd": "START",
  "params": {
    "exercise": "squats"
  }
}
```

## 📖 Utilisation

1. **Ouvre l'application**
2. **Connecte ton ESP32** (icône Bluetooth en haut à droite)
3. **Choisis un exercice**
4. **Démarre le workout !**

## 🛠️ Technologies

- Flutter 3.24.3
- Dart 3.5
- SQLite (base de données locale)
- Bluetooth Low Energy (BLE)

## 📝 Dépendances principales

- `flutter_blue_plus` : Bluetooth BLE
- `provider` : State management
- `sqflite` : Base de données
- `fl_chart` : Graphiques
- `google_fonts` : Polices

## 📄 Licence

MIT License - Utilise librement ce projet !

## 💪 Bon entraînement !
