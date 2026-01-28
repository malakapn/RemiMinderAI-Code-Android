# RemiMinder Phase 2 Architecture

## Overview

RemiMinder Phase 2 is a mobile-first healthcare companion that connects patients and caregivers through AI-powered visit recording and intelligent medication management.

## System Components

### Mobile App (Flutter)
- **Framework**: Flutter for iOS and Android
- **State Management**: Riverpod (reactive state management)
- **Offline Sync**: PowerSync (local SQLite + real-time sync)
- **HTTP Client**: Dio (network requests)
- **ML Kit**: Google ML Kit for on-device OCR processing
- **Core Features**:
  - Audio visit recording with AI transcription
  - Smart medication reminders with snooze/skip
  - RemiScan: AI-powered scanner for prescriptions, pill bottles, and lab reports
  - Patient dashboard with health tracking
  - Caregiver multi-patient monitoring
  - Offline-first capabilities with sync

### Backend (FastAPI + GCP)
- **API Framework**: FastAPI for high-performance REST APIs
- **Database**: Google Cloud SQL (PostgreSQL)
- **Authentication**: Firebase Auth (JWT-based)
- **Deployment**: Google Cloud Run (serverless)
- **AI Services**: Vertex AI with Gemini models

### Supporting Services
- **File Storage**: Google Cloud Storage (audio, images)
- **Push Notifications**: Firebase Cloud Messaging + AWS SES (email)
- **AI Processing**: Gemini 2.5 Flash, Gemini 1.5 Pro (multimodal)
- **OCR/Vision**: Google ML Kit + Google Vision API + Gemini multimodal reasoning
- **CI/CD**: GitHub Actions for automated deployment

## Data Flow

```
Flutter App → FastAPI Backend → Cloud SQL Database
     ↓              ↓              ↓
Firebase Auth   Cloud Storage   Real-time Sync
```

## Key Capabilities

### Patient Experience
- **Audio Visit Recording**: Record doctor-patient conversations with high-quality audio
- **AI Transcription**: Automatic conversion to text with intelligent summarization
- **Smart Medication Reminders**: Intelligent scheduling with snooze and skip options
- **RemiScan**: AI-powered scanning of prescriptions, pill bottles, and lab reports
- **Health Dashboard**: Comprehensive view of medications, visits, and adherence
- **Visit History**: Archive of past visits with summaries and recordings

### Caregiver Experience
- **Multi-Patient Monitoring**: Manage multiple patients with real-time oversight
- **Adherence Alerts**: Receive notifications for missed medications or issues
- **Visit Access**: View patient visit recordings and AI-generated summaries
- **Emergency Connections**: Quick access to healthcare providers
- **Progress Tracking**: Monitor medication compliance and health trends

### AI-Powered Features
- **Intelligent Transcription**: Google Gemini-powered visit audio processing
- **Smart Reminder Generation**: AI extracts time-based tasks from conversations and scanned documents
- **RemiScan AI Analysis**: AI processes scanned prescriptions, pill bottles, and lab reports for insights
- **Natural Language Processing**: Friendly, jargon-free communication
- **Adherence Analytics**: Pattern recognition in medication compliance
- **Personalized Messaging**: AI-generated reminder texts, visit summaries, and health insights
- **Medical Content Analysis**: AI identifies trends, abnormalities, and health indicators from scans

### RemiScan Capabilities (AI-Powered)
- **Multi-Document Scanning**: Prescriptions, pill bottles, and lab reports
- **OCR + AI Processing**: Google ML Kit extracts text + AI analyzes content for insights
- **Intelligent Data Extraction**: Identifies medicine name, dosage, frequency, timing, and medical parameters
- **Smart Summaries**: AI generates plain-language summaries of lab results and prescriptions
- **Automated Reminders**: Creates medication and follow-up reminders based on scanned content
- **Content Analysis**: AI identifies trends, abnormalities, and important health indicators
- **Auto-Cleaning & Validation**: Removes noise, handles blurry scans, validates medical data
- **Pre-Filled Health Plans**: Creates ready-to-confirm medication and care schedules

### User Experience Features
- **Intuitive UI**: Clean, accessible interface for all ages
- **Voice Commands**: Voice-activated features for accessibility
- **Multi-language**: Support for multiple languages
- **Offline Mode**: Full functionality without internet connectivity
- **Background Processing**: Notifications and sync work continuously

### Integration Features
- Healthcare provider connections and data sharing capabilities

## Technology Choices

### Why This Stack?
- **Flutter + Riverpod + PowerSync**: Modern reactive state management with offline-first sync
- **FastAPI + Cloud SQL**: High-performance APIs with reliable PostgreSQL
- **Firebase + GCP Ecosystem**: Integrated services, scalability, and compliance
- **Vertex AI + Gemini**: Advanced multimodal AI with LangChain orchestration
- **ML Kit + Vision API**: Comprehensive OCR and computer vision capabilities

### Security & Compliance
- Firebase Auth for secure user management
- Cloud SQL with encryption and backups
- HIPAA-ready architecture
- Secure API communication

## Deployment & Scaling

- **Mobile Apps**: App Store and Google Play Store
- **Backend**: Google Cloud Run with automatic scaling
- **Database**: Cloud SQL with read replicas
- **CI/CD**: GitHub Actions for automated testing and deployment
- **Global CDN**: Fast content delivery worldwide
