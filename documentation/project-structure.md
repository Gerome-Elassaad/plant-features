# 📁 Arco Project Structure

## 🎯 Overview
Production-ready Flutter + Node.js application for plant diagnosis and virtual cultivation assistance.

```
arco/
├── 📱 Flutter Frontend (lib/)
├── 🖥️ Node.js Backend (src/)
├── 🐳 Deployment (Docker, configs)
├── 📚 Documentation
└── 🔧 Configuration Files
```

---

## 📱 Flutter Frontend Structure

```
lib/
├── main.dart                           # App entry point
├── core/                              # Core application modules
│   ├── constants/
│   │   └── api_constants.dart         # API endpoints and configs
│   ├── exceptions/
│   │   └── app_exceptions.dart        # Custom exception classes
│   ├── providers/
│   │   └── theme_provider.dart        # Theme state management
│   ├── services/
│   │   ├── api_service.dart           # HTTP client wrapper
│   │   ├── storage_service.dart       # Local storage service
│   │   └── connectivity_service.dart  # Network connectivity
│   ├── theme/
│   │   └── app_theme.dart             # App theming (light/dark)
│   └── widgets/
│       └── loading_overlay.dart       # Reusable loading widget
├── features/
│   ├── assistant/                     # Virtual assistant feature
│   │   ├── models/
│   │   │   └── chat_model.dart        # Chat data models
│   │   ├── providers/
│   │   │   └── chat_provider.dart     # Chat state management
│   │   ├── screens/
│   │   │   └── chat_screen.dart       # Chat interface
│   │   └── widgets/
│   │       ├── chat_input_field.dart  # Message input widget
│   │       ├── chat_message_bubble.dart # Message bubble widget
│   │       ├── suggestion_chips.dart  # Suggestion chips
│   │       └── typing_indicator.dart  # Typing animation
│   ├── diagnosis/                     # Plant diagnosis feature
│   │   ├── models/
│   │   │   └── diagnosis_model.dart   # Diagnosis data models
│   │   ├── providers/
│   │   │   └── diagnosis_provider.dart # Diagnosis state management
│   │   ├── screens/
│   │   │   └── diagnosis_screen.dart  # Camera/upload interface
│   │   ├── services/
│   │   │   └── image_service.dart     # Image handling service
│   │   └── widgets/
│   │       ├── diagnosis_result_view.dart # Results display
│   │       ├── image_selection_card.dart  # Image picker cards
│   │       └── loading_overlay.dart   # Feature-specific loading
│   └── home/                          # Home/dashboard feature
│       └── screens/
│           └── home_screen.dart       # Main navigation screen
```

---

## 🖥️ Node.js Backend Structure

```
src/
├── server.js                         # Express server entry point
├── controllers/                      # Request handlers
│   ├── assistantController.js        # Chat endpoint logic
│   └── diagnosisController.js        # Diagnosis endpoint logic
├── middleware/                       # Custom middleware
│   ├── errorHandler.js              # Global error handling
│   └── validateRequest.js           # Input validation
├── routes/                          # API route definitions
│   ├── assistantRoutes.js           # Chat API routes
│   └── diagnosisRoutes.js           # Diagnosis API routes
├── services/                        # External service integrations
│   ├── geminiService.js             # Google Gemini API client
│   └── plantIdService.js            # Plant.id API client
└── utils/                           # Utility functions
    ├── imageProcessor.js            # Image processing utilities
    └── logger.js                    # Winston logging setup
```

---

## 🐳 Deployment & Configuration

```
Root Directory/
├── .env.example                     # Environment variables template
├── .gitignore                       # Git ignore patterns
├── Dockerfile                       # Container build instructions
├── docker-compose.yml              # Multi-service orchestration
├── ecosystem.config.js             # PM2 process management
├── nginx.conf                      # Reverse proxy configuration
├── package.json                    # Node.js dependencies
├── pubspec.yaml                    # Flutter dependencies
├── setup.sh                        # Automated setup script
└── README.md                       # Project documentation
```

---

## 📚 Documentation Structure

```
docs/
├── API.md                          # API endpoint documentation
├── DEPLOYMENT.md                   # Production deployment guide
├── DEVELOPMENT.md                  # Development setup guide
└── ARCHITECTURE.md                 # System architecture overview
```

---

## 🔧 Key Configuration Files

### Flutter Configuration (`pubspec.yaml`)
```yaml
dependencies:
  flutter: sdk: flutter
  # State Management
  provider: ^6.1.1
  # Networking
  dio: ^5.4.0
  dio_cache_interceptor: ^3.5.0
  # Image Handling
  image_picker: ^1.0.5
  flutter_image_compress: ^2.1.0
  # UI Components
  google_fonts: ^6.1.0
  animate_do: ^3.1.2
  flutter_markdown: ^0.6.18
```

### Backend Configuration (`package.json`)
```json
{
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "multer": "^1.4.5-lts.1",
    "axios": "^1.6.2",
    "helmet": "^7.1.0",
    "express-rate-limit": "^7.1.5",
    "winston": "^3.11.0",
    "sharp": "^0.33.1",
    "@google/generative-ai": "^0.1.3"
  }
}
```

---

## 🚀 Quick Start Commands

### Development Setup
```bash
# Setup everything
chmod +x setup.sh
./setup.sh

# Backend only
npm install && npm run dev

# Flutter only  
flutter pub get && flutter run
```

### Production Deployment
```bash
# Docker deployment
docker-compose --profile production up -d

# Manual deployment
npm install --production
npm start
```

### Testing
```bash
# Backend tests
npm test

# Flutter tests
flutter test
```

---

## 🔗 API Integration Flow

```
Flutter App ──┐
              │
              ├─► Node.js API ──┐
              │                 │
              │                 ├─► Plant.id API (Diagnosis)
              │                 │
              │                 └─► Google Gemini API (Chat)
              │
              └─► Local Storage (Settings/Cache)
```

---

## 📊 Feature Modules

### 1. Plant Diagnosis Module
- **Purpose:** Identify plants and detect diseases from photos
- **Components:** Camera/Gallery picker, Image compression, API integration
- **External Service:** Plant.id API
- **Key Files:** `diagnosis_provider.dart`, `diagnosisController.js`

### 2. Virtual Assistant Module  
- **Purpose:** Provide plant care advice through conversational AI
- **Components:** Chat interface, Message history, Suggestion system
- **External Service:** Google Gemini API
- **Key Files:** `chat_provider.dart`, `assistantController.js`

### 3. Core Infrastructure
- **Purpose:** Shared utilities, theming, state management
- **Components:** API client, Theme system, Storage service
- **Key Files:** `api_service.dart`, `app_theme.dart`, `main.dart`

---

## 🔐 Security Features

- ✅ **API Key Protection:** All sensitive keys stored backend-only
- ✅ **Input Validation:** Server-side validation with express-validator
- ✅ **Rate Limiting:** Configurable rate limits per endpoint
- ✅ **File Upload Security:** Type validation, size limits, virus scanning ready
- ✅ **CORS Configuration:** Restricted origins for production
- ✅ **Error Handling:** No sensitive data exposed in error responses

---

## 📈 Scalability Features

- **Horizontal Scaling:** PM2 cluster mode, Docker Swarm ready
- **Caching:** Dio cache interceptor, Redis integration ready
- **Load Balancing:** Nginx configuration included
- **Monitoring:** Winston logging, health check endpoints
- **Database Ready:** Models structured for easy database integration

---

## 🛠️ Development Tools

- **Code Quality:** ESLint (Backend), Flutter Lints (Frontend)
- **Testing:** Jest (Backend), Flutter Test (Frontend)
- **Documentation:** API docs, inline code comments
- **Version Control:** Git with comprehensive .gitignore
- **CI/CD Ready:** GitHub Actions templates included

---

*This structure ensures a maintainable, scalable, and production-ready application following industry best practices.*