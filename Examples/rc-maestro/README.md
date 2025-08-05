# App Setup and Usage Guide

This project uses [Tuist](https://tuist.dev/) for managing the Xcode project and [mise](https://mise.jdx.dev/) to handle tool versioning. Follow the steps below to set up and run the app.

---

## 🚀 Requirements

Before getting started, ensure you have the following installed:

1. **[mise](https://mise.jdx.dev/installing-mise.html)** – Tool version manager
2. **[Tuist](https://docs.tuist.dev/es/guides/quick-start/install-tuist)** – Xcode project generator

---

## 🛠 Using the App

1. **Configure local secrets:**
   - Copy the sample config file:
     ```bash
     cp Resources/Local.xcconfig.sample Resources/Local.xcconfig
     ```
   - Open `Resources/Local.xcconfig` and insert your iOS API key.

2. **Install Tuist dependencies:**
   ```bash
   tuist install
   ```

3. **Generate the Xcode project:**
   ```bash
   tuist generate
   ```

4. **Open the project in Xcode and run the app:**
   ```bash
   open App.xcodeproj
   ```

---

## 🔄 Test a Different Commit or Branch of a Local Package

1. Open `Tuist/Package.swift`.

2. Locate the relevant package declaration and update:
   - To test a **different branch**:
     ```swift
     .branch("my-feature-branch")
     ```
   - To test a **specific commit**:
     ```swift
     .revision("abcdef1234567890")
     ```

---