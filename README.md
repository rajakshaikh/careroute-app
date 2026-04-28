# CareRoute — AI-Powered ASHA Worker App

CareRoute is a mobile-first healthcare support system designed for ASHA (community health) workers.  
It enables real-time patient tracking, AI-assisted reporting, and seamless coordination with a monitoring dashboard.

---

## Project Status

The mobile application is currently in development and has not been deployed as a standalone app.  
However, the web-based dashboard is fully deployed and demonstrates the real-time data synchronization and core system functionality.

---

## Features

### Mobile Application (Flutter)
- Simple login using Name and Region ID  
- View patients assigned by region  
- Risk-based prioritization (High / Medium / Low)  
- Voice-to-text visit recording  
- AI-generated medical reports (via Gemini)  
- AI-powered smart checklist for visits  
- Mark visits as completed  
- Real-time synchronization with dashboard  

---

## AI Capabilities (Gemini)

- Converts spoken notes into structured medical reports  
- Generates:
  - Summary  
  - Symptoms  
  - Actions taken  
  - Recommendations  
- Suggests smart checklists based on patient condition  

---

## Backend (Firebase)

- Firestore database for patients and reports  
- Real-time data synchronization  
- Scalable cloud backend  

---

## Dashboard (Web Admin Panel)

**Repository:**  
https://github.com/WhiteFurr/CareRoute-Dashboard.git

### Features
- Monitor ASHA worker activity  
- Track high-risk patients  
- View visit completion statistics  
- Analyze healthcare coverage  

---
## Architecture Overview

```
ASHA App (Flutter)
        ↓
Firebase (Firestore)
        ↓
Gemini AI (Report Generation)
        ↓
Firebase (Updated Data)
        ↓
Web Dashboard (Monitoring)
```

---

## Tech Stack

- Frontend (App): Flutter  
- Backend: Firebase (Firestore)  
- AI: Gemini API  
- Speech-to-Text: Flutter Speech Plugin  
- Dashboard: Web Application  

---

## Live Prototype

https://care-route-dashboard-git-main-blackfurrs-projects.vercel.app/

---

## Demo Video

https://youtu.be/LhKwrg40Is8

---

# Setup Instructions

```bash
git clone [https://github.com/rajakshaikh/careroute-app.git](https://github.com/rajakshaikh/careroute-app.git)
cd your_project

flutter pub get
flutter run
