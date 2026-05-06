# 🏥 Chifaae (شفاء)
> **Status: Technical Prototype / MVP** > *Note: This is an initial proof-of-concept. The full-scale production solution is currently under development.*

**The Intelligent Bridge to Moroccan Healthcare**

Chifaae is a conversational, AI-driven healthcare MVP designed to streamline the patient journey in Morocco. By leveraging Large Language Models (LLMs), Chifaae acts as a digital triage assistant, connecting users' symptoms to real-world medical resources including local pharmacies, specialists, and laboratories.

---

## 🚀 Key Features

### 1. AI-Powered Symptom Triage
* **Interactive Questionnaire:** A dynamic 10-question diagnostic flow that assesses symptom severity.
* **Probability Analysis:** Utilizes LLMs (**Llama 3.3-70B via Groq**) to provide potential health insights and medical disclaimers.
* **Specialist Routing:** Automatically suggests the correct specialist (e.g., Cardiologist vs. Pediatrician) based on the AI's analysis.

### 2. Localized Logistics Bridge
* **Pharmacy Integration:** Real-time stock checking and location-based sorting for pharmacies in the **Kénitra/Rabat** region.
* **Service Mapping:** Direct links to nearby specialists and laboratories to reduce unnecessary travel and "medical tourism."

### 3. Dual-Portal Ecosystem
* **Patient Dashboard:** Quick access to AI triage, pharmacy search, and personal medical history.
* **Professional Portal:** A dedicated interface for medical professionals to manage localized health data and patient routing.

---

## 🛠️ Tech Stack

* **Frontend:** Flutter (Web)
* **AI Engine:** Groq API (Llama 3.3-70B)
* **Backend Reasoning:** Gemini API
* **Deployment:** GitHub Pages (via `gh-pages` branch)
* **Methodology:** "Vibe Coding" / MVP-first approach

---

## 🚧 Prototype Disclaimer
This repository contains a **prototype**. 
* Data regarding pharmacy stock in this version may be simulated for demonstration purposes.
* AI outputs are for informational purposes and **not** a substitute for professional medical advice.

---

## 📥 Getting Started

1.  **Clone the repo:** `git clone https://github.com/AverageGuy001/chiffae.app.git`
2.  **Install dependencies:** `flutter pub get`
3.  **Run locally:** `flutter run -d chrome`

---
Developed with 💚 for the Moroccan Healthcare Community.
