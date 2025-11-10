
# 🎨 Bisi-SketchPad Flutter App

### Author
**Olubisi Ayantoye**  
Brigham Young University–Idaho  

---

## 📘 Overview

**Bisi-SketchPad Flutter App** is a simple and creative mobile drawing application built with **Flutter**.  
It allows users to draw, paint, change brush colors, adjust stroke size, clear the canvas, and save their artwork directly to their device’s gallery.  

The app demonstrates the use of:
- Custom painting in Flutter (`CustomPainter`)
- Touch gesture detection (`GestureDetector`)
- File system access and image saving
- State management within a `StatefulWidget`

---

## ✨ Features

✅ Draw freehand lines on the canvas using touch  
✅ Choose brush colors dynamically  
✅ Adjust brush thickness with a slider  
✅ Clear the canvas instantly  
✅ Save drawings as PNG images to local storage/gallery  
✅ Simple, minimal, and responsive design  

✏️ Undo/Redo feature

🖼️ Add background color or image import

💾 Internal gallery viewer

📤 Share drawings (e.g., WhatsApp, Email)

🧭 Save drawing progress automatically

🎨 Toolbar redesign with color palette wheel

---

## 🧰 System Requirements

| Requirement | Minimum Version |
|--------------|------------------|
| **Flutter SDK** | 3.0 or higher |
| **Dart** | 3.0 or higher |
| **Operating System** | Windows, macOS, or Linux |
| **Editor** | Visual Studio Code / Android Studio |
| **Device** | Android phone (tested), iOS supported with minor setup |

---

## ⚙️ Installation & Setup

### 1️⃣ Clone or Create Project
```bash
git clone https://github.com/<yourusername>/bisi-sketchpad.git
cd bisi-sketchpad


🖌️ Usage Guide

Draw: Use your finger to draw freely on the screen.

Change Brush Color: Tap the 🎨 icon to select a new color.

Adjust Brush Size: Use the bottom slider to make your brush thicker or thinner.

Clear Canvas: Tap 🗑️ to erase everything.

Save Artwork: Tap 💾 to save your current drawing to your gallery.

All drawings are saved automatically in your device’s internal storage and gallery folder.

🧠 Technical Architecture

Main Components:

DrawingCanvas – Handles user drawing gestures.

DrawingPainter – Custom painter that renders strokes to the canvas.

_DrawingCanvasState – Manages color, stroke width, and user input.

RepaintBoundary – Captures widget output as an image for saving.

Key Flutter Concepts Used:

GestureDetector → captures touch interactions

CustomPaint → draws paths dynamically

RenderRepaintBoundary → converts widget tree to image

ImageGallerySaver → saves artwork locally



# 🎨 Bisi-SketchPad Flutter App

A fun, simple, and educational **Flutter drawing app** that lets you paint with your finger, change brush colors, adjust stroke size, clear the canvas, and save your artwork into your phone gallery.

---

## 🧑‍🎨 Author

**Olubisi Ayantoye**  
Brigham Young University–Idaho  

📧 Email 1: [oayantoye@byupathway.edu](mailto:oayantoye@byupathway.edu)  
📧 Email 2: [olubisiolatundetoye@gmail.com](mailto:olubisiolatundetoye@gmail.com)  

---

## 📱 App Features

| Feature | Description |
|----------|--------------|
| ✍️ **Draw Freely** | Use your finger or stylus to draw directly on the screen. |
| 🎨 **Change Color** | Choose any color for your brush. |
| ⚙️ **Adjust Brush Size** | Make your lines thinner or thicker with a slider. |
| 🧹 **Clear Canvas** | Start fresh anytime with one tap. |
| 💾 **Save Art** | Save your creation to your device gallery. |

---

## 🚀 Requirements

- Flutter SDK **3.0+**
- Dart **3.0+**
- Android Studio or VS Code
- Android phone with **Developer Mode** enabled
- At least **8 GB RAM** recommended

---

## 🛠️ Installation Steps

### 1️⃣ Create or Clone the Project
```bash
flutter create bisi_sketchpad_app
cd bisi_sketchpad_app
