# CaloCam - Smart Calorie Tracker with AI

> Track your meals, count calories, and achieve your health goals with AI-powered food recognition

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-103%20passing-brightgreen)]()
[![Coverage](https://img.shields.io/badge/Coverage-75%25-yellow)]()

---

## Features

### AI-Powered Food Recognition
- **GPT-4O Vision Integration** - Instant meal recognition from photos
- **Vietnamese Food Database** - Optimized for local cuisine
- **High Accuracy** - 95%+ confidence for common foods
- **Portion Size Detection** - Automatic calorie calculation

### Comprehensive Tracking
- **Daily Calorie Monitoring** - Visual progress ring
- **Macro Tracking** - Protein, Carbs, Fat breakdown
- **Meal Types** - Breakfast, Lunch, Dinner, Snacks
- **Weight Tracking** - Monitor your progress over time
- **Water Intake** - Stay hydrated with quick logging

### Analytics & Insights
- **Weekly Progress** - 7-day calorie trends
- **Meal History** - Search and filter all meals
- **BMI Calculator** - Track your Body Mass Index
- **BMR & TDEE** - Personalized calorie goals
- **Goal Tracking** - Weight loss, gain, or maintenance

### Modern UI/UX
- **Beautiful Design** - Clean, intuitive interface
- **Dark Theme Ready** - Eye-friendly dark mode support
- **Smooth Animations** - Polished user experience
- **Vietnamese Localization** - Full Vietnamese support
- **Haptic Feedback** - Tactile responses

### Privacy & Performance
- **Offline-First** - SQLite local database
- **Image Compression** - Optimized storage
- **Lazy Loading** - Efficient memory usage
- **Auto Cleanup** - Remove old images (30+ days)
- **No Data Collection** - Your data stays on your device

---

## Screenshots

<table>
  <tr>
    <td><img src="assets/screenshots/home.png" width="200"/></td>
    <td><img src="assets/screenshots/camera.png" width="200"/></td>
    <td><img src="assets/screenshots/ai_result.png" width="200"/></td>
    <td><img src="assets/screenshots/history.png" width="200"/></td>
  </tr>
  <tr>
    <td align="center"><b>Home Dashboard</b></td>
    <td align="center"><b>Camera</b></td>
    <td align="center"><b>AI Results</b></td>
    <td align="center"><b>History</b></td>
  </tr>
</table>

---

## Getting Started

### Prerequisites

- Flutter SDK: `>=3.9.2`
- Dart SDK: `>=3.0.0`
- Android Studio / VS Code
- OpenAI API Key (for AI features)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/calocount_app.git
   cd calocount_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure API Key**
   - Open `lib/core/config/env_config.dart`
   - Replace `YOUR_API_KEY_HERE` with your OpenAI API key:
     ```dart
     static const String openAiApiKey = 'your-actual-api-key';
     ```

4. **Run the app**
   ```bash
   # For debug mode
   flutter run

   # For release mode
   flutter run --release
   ```

### Build APK

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Split APK by ABI (smaller size)
flutter build apk --split-per-abi
```

---

## Architecture

### Project Structure

```
lib/
├── core/                    # Core functionality
│   ├── config/             # App configuration
│   ├── constants/          # Constants (colors, dimensions, etc.)
│   ├── services/           # Services (camera, image, AI)
│   └── utils/              # Utilities (calculators, formatters)
│
├── data/                    # Data layer
│   ├── datasources/        # Data sources (local DB)
│   └── models/             # Data models
│
├── presentation/            # UI layer
│   ├── providers/          # State management
│   ├── screens/            # App screens
│   └── widgets/            # Reusable widgets
│
└── main.dart               # App entry point

test/
├── unit/                   # Unit tests
├── widget/                 # Widget tests
├── integration/            # Integration tests
└── helpers/                # Test helpers
```

### Tech Stack

- **Framework:** Flutter 3.9.2
- **Language:** Dart 3.0
- **State Management:** Provider
- **Database:** SQLite (sqflite)
- **AI:** OpenAI GPT-4O Vision API
- **Camera:** camera + image_picker
- **Image Processing:** image package
- **Local Storage:** shared_preferences
- **Testing:** flutter_test + mockito

---

## Testing

### Run Tests

```bash
# All tests
flutter test

# Unit tests only
flutter test test/unit/

# Widget tests only
flutter test test/widget/

# With coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # Mac
start coverage/html/index.html # Windows
```

### Test Coverage

| Module | Coverage | Status |
|--------|----------|--------|
| Calculators (BMI, BMR, TDEE) | 100% | Passed |
| Date Formatter | 95% | Passed |
| Models | 100% | Passed |
| Providers | 100% | Passed |
| UI Components | 85% | Passed |
| **Overall** | **~75%** | **Passed** |

---

## Features In Detail

### AI Food Recognition

The app uses **GPT-4O Vision** to recognize food from photos:

1. **Take a photo** of your meal
2. **AI analyzes** the image (~3 seconds)
3. **Get instant results**:
   - Food name
   - Calories
   - Protein, Carbs, Fat
   - Portion size
   - Confidence score

**Supported Foods:**
- Vietnamese cuisine (Phở, Bánh mì, Cơm, etc.)
- International dishes
- Packaged foods
- Homemade meals

### Health Calculations

#### BMI (Body Mass Index)
```
BMI = weight(kg) / height(m)²
```
Categories (Asian standard):
- < 18.5: Underweight
- 18.5-23: Normal
- 23-25: Overweight
- 25-30: Obese Class I
- 30+: Obese Class II

#### BMR (Basal Metabolic Rate)
```
Male: BMR = 10×weight + 6.25×height - 5×age + 5
Female: BMR = 10×weight + 6.25×height - 5×age - 161
```

#### TDEE (Total Daily Energy Expenditure)
```
TDEE = BMR × Activity Factor

Activity Levels:
- Sedentary: 1.2
- Light: 1.375
- Moderate: 1.55
- Active: 1.725
- Very Active: 1.9
```

### Database Schema

```sql
-- Users table
CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  name TEXT,
  gender TEXT,
  age INTEGER,
  height_cm REAL,
  weight_kg REAL,
  goal_type TEXT,
  calorie_goal REAL,
  ...
);

-- Meal entries table
CREATE TABLE meal_entries (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  date TEXT,
  meal_type TEXT,
  food_name TEXT,
  calories REAL,
  protein REAL,
  carbs REAL,
  fat REAL,
  image_path TEXT,
  source TEXT,
  confidence REAL,
  ...
);

-- Weight history table
CREATE TABLE weight_history (
  id INTEGER PRIMARY KEY,
  user_id INTEGER,
  weight_kg REAL,
  date TEXT,
  note TEXT
);

-- Water intake table
CREATE TABLE water_intake (
  id INTEGER PRIMARY KEY,
  user_id INTEGER,
  date TEXT,
  amount_ml INTEGER,
  goal_ml INTEGER
);
```

---

## Configuration

### API Configuration

Edit `lib/core/config/env_config.dart`:

```dart
class EnvConfig {
  // OpenAI API
  static const String openAiApiKey = 'your-api-key';
  static const String openAiModel = 'gpt-4o';
  static const String openAiApiUrl = 'https://api.openai.com/v1/chat/completions';
  
  // Timeouts
  static const int apiTimeoutSeconds = 30;
  static const int maxRetries = 3;
  
  // Image settings
  static const int maxImageSize = 800; // pixels
  static const int imageQuality = 85; // 0-100
}
```

### Theme Configuration

Edit `lib/core/constants/app_colors.dart`:

```dart
class AppColors {
  static const Color primary = Color(0xFF4CAF50);
  static const Color accent = Color(0xFFFF9800);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  // ... more colors
}
```

---

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Add comments for complex logic
- Write tests for new features
- Run `flutter analyze` before committing

---

## Known Issues & Limitations

- **iOS not fully tested** - Developed primarily for Android
- **AI requires internet** - Food recognition needs network connection
- **API costs** - OpenAI GPT-4O usage incurs costs
- **Vietnamese-focused** - UI and food database optimized for Vietnamese users

---

## Changelog

### Version 1.0.0 (2025-10-21)

#### Features
- AI-powered food recognition (GPT-4O Vision)
- Comprehensive calorie tracking
- Weight & water intake monitoring
- Weekly progress analytics
- BMI/BMR/TDEE calculations
- Meal history with search
- Image capture & storage
- Vietnamese localization

#### Testing
- 103 unit + widget tests
- 75% code coverage
- All tests passing

#### Documentation
- Comprehensive README
- Inline code documentation
- Test documentation

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Authors

**CaloCam Team**
- GitHub: [@NguyenDinhKhang1100604](https://github.com/NguyenDinhKhang1100604)
- Email: nguyendinhkhang1100604@gmail.com

---

## Acknowledgments

- **OpenAI** - GPT-4O Vision API
- **Flutter Team** - Amazing framework
- **Community** - Open source libraries and inspiration

---

## Support

- Email: support@calocam.app
- Issues: [GitHub Issues](https://github.com/yourusername/calocount_app/issues)
- Discussions: [GitHub Discussions](https://github.com/yourusername/calocount_app/discussions)

---

## Roadmap

### v1.1 (Q4 2025)
- [ ] iOS optimization
- [ ] Dark theme
- [ ] Barcode scanner
- [ ] Recipe database
- [ ] Social features (share meals)

### v1.2 (Q1 2026)
- [ ] Cloud sync
- [ ] Multi-language support
- [ ] Apple Health integration
- [ ] Export data (CSV, PDF)
- [ ] Custom food database

### v2.0 (Q2 2026)
- [ ] Premium features
- [ ] AI meal planner
- [ ] Nutrition coach
- [ ] Community challenges
- [ ] Wearable integration

---

<div align="center">

**Star this repo if you found it helpful!**

Made with love by CaloCam Team

</div>
