# 🌱 Aspargo Project: Plant Diagnosis & Virtual Cultivation Assistant

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-18+-339933?style=for-the-badge&logo=node.js&logoColor=white)
![Express](https://img.shields.io/badge/Express-4.0+-000000?style=for-the-badge&logo=express&logoColor=white)
![Plant.id API](https://img.shields.io/badge/Plant.id-API-4CAF50?style=for-the-badge&logo=leaf&logoColor=white)
![Google Gemini](https://img.shields.io/badge/Gemini-API-4285F4?style=for-the-badge&logo=google&logoColor=white)

![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)
![Version](https://img.shields.io/badge/Version-1.0.0-blue?style=flat-square)
![Status](https://img.shields.io/badge/Status-Production_Ready-green?style=flat-square)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey?style=flat-square)

[Features](#-introduction) • [Tech Stack](#-tech-stack-selection) • [Installation](#-installation) • [API Docs](#-api-documentation) • [Read Full Docs](/documentation)

</div>

---

## 📑 Table of Contents

- [🌱 Aspargo Project: Plant Diagnosis \& Virtual Cultivation Assistant](#-aspargo-project-plant-diagnosis--virtual-cultivation-assistant)
  - [📑 Table of Contents](#-table-of-contents)
  - [📋 Introduction](#-introduction)
  - [🚀 Tech Stack Selection](#-tech-stack-selection)
  - [🌱 Feature 1: Plant Diagnosis](#-feature-1-plant-diagnosis--full-flow--architecture)
    - [📸 High-Level Flow](#-high-level-flow)
    - [💡 Key Design Choices](#-key-design-choices)
    - [🔒 Trade-offs](#-trade-offs)
    - [📐 Backend Route Example](#-backend-route-example)
    - [🖼️ UI Considerations](#️-ui-considerations)
  - [🤖 Feature 2: Virtual Cultivation Assistant](#-feature-2-virtual-cultivation-assistant--full-flow--architecture)
    - [💬 High-Level Flow](#-high-level-flow-1)
    - [💡 Key Design Choices](#-key-design-choices-1)
    - [🔄 Example API Endpoint](#-example-api-endpoint)
    - [🤔 Trade-offs](#-trade-offs-1)
    - [📐 Backend Considerations](#-backend-considerations)
  - [🗂️ Folder Structure](#️-folder-structure)
    - [Flutter Structure](#flutter)
    - [Node.js Structure](#nodejs)
  - [🔐 Security & Performance Practices](#-security--performance-practices)
  - [🌟 Why This Approach Works](#-why-this-approach-works)
  - [📚 Overview](#-overview)
  - [🚀 Installation](#-installation)
  - [📖 Full Documentation](/documentation)

---

## 📋 Introduction

The purpose of this document is to **clearly explain my solution design, technology choices, and reasoning** for building the two core features requested:

## Plant Identification - Example How it works
![plant.id](https://github.com/user-attachments/assets/a3c378ba-dd6e-4eff-a902-9a8cbc164a0b)

---

## Virtual Cultivation Assistant - Example How it works
![download (4)](https://github.com/user-attachments/assets/6a36d16c-06a5-4764-9da2-8f946734de38)


I will walk you through:

* My **tech stack choices**
* **How I would build** each feature from app to backend
* Key **trade-offs and justifications**
* **Diagrams and API flows**
* My thinking around **scalability, security, and maintainability**

---

## 🚀 Tech Stack Selection

| Layer               | Technology                               | Justification                                                                                                       |
| ------------------- | ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Mobile Frontend     | Flutter.dev                              | Cross-platform, production-grade, fast UI updates, native feel, built-in image handling, scalable to web if needed. |
| State Management    | Provider (or Bloc if scaling is complex) | Lightweight, predictable, and battle-tested for Flutter apps.                                                       |
| Image Compression   | flutter\_image\_compress                 | Reduces payload size for faster, more efficient uploads.                                                            |
| Backend API         | Node.js + Express                        | Lightweight, scalable, simple file handling (via `multer`), fast response times for mobile.                         |
| Plant Diagnosis API | Plant.id API                             | Proven plant recognition and disease detection API with excellent documentation and scalable pricing.               |
| AI Chatbot API      | Google Gemini API                        | Advanced AI with reliable conversational capabilities and broad knowledge base, perfect for virtual assistant.      |

---

## 🌱 Feature 1: Plant Diagnosis – Full Flow & Architecture

### 📸 High-Level Flow:

```plaintext
User captures/chooses plant image (Flutter)
    ↓
Image compressed (Flutter)
    ↓
POST image to Node.js backend (multipart/form-data)
    ↓
Node.js securely calls Plant.id API
    ↓
Receives plant name, disease, care tips
    ↓
Maps API response to simplified Flutter-friendly JSON
    ↓
Flutter displays detailed diagnosis result
```

---

### 💡 Key Design Choices:

* **Image Compression on Device:**
  Reduces upload time and mobile bandwidth usage, important for fast user feedback.

* **Backend as API Gateway:**
  Protects Plant.id API keys, centralizes API management, and future-proofs multi-service expansion.

* **Data Mapping at Backend:**
  Translates complex Plant.id responses into clean, lightweight JSON optimized for Flutter rendering.

---

### 🔒 Trade-offs:

| Option                  | Pros                                  | Cons                             |
| ----------------------- | ------------------------------------- | -------------------------------- |
| Direct API from Flutter | Less server load                      | Exposes API keys – security risk |
| Backend Intermediary    | API key security, centralized control | Slightly increased latency       |

✅ **Chosen:** Backend intermediary for security and maintainability.

---

### 📐 Backend Route Example:

**Endpoint:** `POST /api/plant/diagnose`

* Receives image via `multer`
* Validates image size, type
* Calls Plant.id API
* Returns clean JSON:

```json
{
  "plantName": "Basil",
  "disease": "Fungal leaf spot",
  "confidence": 96.3,
  "treatment": "Remove infected leaves and apply organic fungicide.",
  "moreInfoUrl": "https://plant.id/basil"
}
```

---

### 🖼️ UI Considerations:

* Show **loading indicators** while diagnosis is processing.
* Display **confidence score visually** (e.g., progress bar).
* Support **error handling UI** for timeout, unsupported images, or API failure.

---

## 🤖 Feature 2: Virtual Cultivation Assistant – Full Flow & Architecture

### 💬 High-Level Flow:

```plaintext
User types plant care question (Flutter)
    ↓
POST message to Node.js backend
    ↓
Backend formats prompt and securely calls Google Gemini API
    ↓
Receives AI response and maps to Flutter-friendly JSON
    ↓
Flutter displays chatbot reply with multi-turn conversation
```

---

### 💡 Key Design Choices:

* **Node.js as Chat Gateway:**
  Protects Gemini API key, allows future support for multiple AI models (e.g. Gemini + custom knowledge base).

* **Chat UI built in Flutter:**
  ListView-based conversation bubbles with loading indicators and error handling.

* **Stateless Backend:**
  No session storage required. Each request contains full context, scalable without state persistence.

---

### 🔄 Example API Endpoint:

**Endpoint:** `POST /api/chat/message`

* Accepts:

```json
{ "message": "How often should I water lavender?" }
```

* Node.js calls Gemini API:

```json
{
  "contents": [
    { "role": "user", "parts": [{ "text": "How often should I water lavender?" }] }
  ]
}
```

* Returns:

```json
{ "response": "Water lavender once every two weeks, ensuring the soil is dry between waterings." }
```

---

### 🤔 Trade-offs:

| Option                        | Pros                                            | Cons                                           |
| ----------------------------- | ----------------------------------------------- | ---------------------------------------------- |
| Gemini API (via backend)      | Easy to scale, fast responses, secured API keys | Monthly API cost, less domain-specific control |
| Custom Model (optional later) | Fully customizable knowledge base               | Requires additional infrastructure             |

✅ **Chosen:** Gemini API for speed to market, reliability, and conversational flexibility.

---

### 📐 Backend Considerations:

* Support request throttling to prevent API abuse.
* Validate message length and input format.
* Provide graceful error messages for timeout or service unavailability.

---

## 🗂️ Folder Structure

### Flutter:

```plaintext
/lib
  /features
    /plant_diagnosis
      diagnosis_screen.dart
      diagnosis_provider.dart
      diagnosis_service.dart
      diagnosis_model.dart
    /chatbot
      chat_screen.dart
      chat_provider.dart
      chat_service.dart
      chat_model.dart
```

### Node.js:

```plaintext
/backend
  /routes
    plantDiagnosis.js
    chatbot.js
  /controllers
    plantDiagnosisController.js
    chatbotController.js
  /services
    plantIdService.js
    geminiService.js
```

---

## 🔐 Security & Performance Practices

* All API keys secured on the backend.
* Input validation on both mobile and server side.
* Backend designed for fast, lightweight API responses (< 1s target).
* Prepared to scale backend using Node.js clustering if needed.

---

## 🌟 Why This Approach Works

- ✅ **Production-Ready:** Every tool and design decision is optimized for deployment, not demos.
- ✅ **Secure:** API keys are never exposed. Inputs are validated. Rate-limiting is possible.
- ✅ **Scalable:** The architecture supports adding more AI models, plant databases, or offline caching.
- ✅ **User-Centric:** The UI prioritizes fast feedback, clean results, and full theme support.

---

## 📚 Overview 

* **Clear, practical engineering decisions.**
* A deep understanding of **end-to-end mobile architecture.**
* A strong focus on **security, scalability, and production-readiness.**
* The ability to design **modular, maintainable, real-world features.**
* Implement these features in Flutter + Node.js.
* Expand the system to handle more advanced plant data, chatbot knowledge bases, and user preference tracking.
* Integrate fully into a larger, evolving app ecosystem.

---

## 🚀 Installation

<details>
<summary><b>Prerequisites</b></summary>

- Flutter SDK (3.0+)
- Node.js (18+)
- npm or yarn
- Plant.id API key
- Google Gemini API key

</details>

<details>
<summary><b>Backend Setup</b></summary>

```bash
# Clone the repository
git clone https://github.com/Gerome-Elassaad/plant-features.git
cd aspargo/backend

# Install dependencies
npm install

# Create .env file
cp .env.example .env

# Add your API keys to .env
# PLANT_ID_API_KEY=your_plant_id_key
# GEMINI_API_KEY=your_gemini_key

# Start the server
npm run dev
```

</details>

<details>
<summary><b>Flutter Setup</b></summary>

```bash
# Example Navigate to Flutter app
cd aspargo/flutter_app

# Get dependencies
flutter pub get

# Update backend URL in lib/config/api_config.dart

# Run the app
flutter run
```

</details>

---

## 📖 API Documentation

[Read Full Docs](/documentation)

### Quick Reference:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/plant/diagnose` | POST | Upload plant image for diagnosis |
| `/api/chat/message` | POST | Send message to cultivation assistant |
| `/api/health` | GET | Check API status |

---
