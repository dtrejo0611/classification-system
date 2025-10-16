# Shape, Signature and Color Inspection (MATLAB)

This repository contains a MATLAB-based visual inspection prototype for classifying simple industrial parts using shape (Hu moments), contour/signature matching, and color classification. The application captures images from a webcam, segments the object, identifies its shape, extracts an edge/contour signature, compares it against stored signatures, classifies color by sampling the object's center, communicates a pass/fail result to an Arduino, and logs results to an Excel report.

Note: the main script file was renamed from `SVAPF.m` to `main.m`. Run `main.m` to start the inspection loop.

---

## Overview

The program inspects individual products in a camera frame and for each candidate object:

1. Crops to a centered inspection region.
2. Converts the crop to grayscale and binarizes to obtain the object mask.
3. Computes Hu moments to identify object shape (circle, square, rectangle, ...).
4. Extracts a contour "signature" from thinned edges (chain-like radial distances).
5. Compares the signature with a stored signature database for variant identification.
6. Samples HSV near the object centroid to classify color.
7. Decides PASS/FAIL according to thresholds and business rules.
8. Sends a sorting command to Arduino via serial.
9. Logs the inspection result to an Excel file.

---

## Features

- Shape recognition via Hu invariant moments.
- Contour signature extraction (boundary traversal) and signature matching.
- Simple HSV color classification using a center-window average.
- Arduino integration (serial) to actuate sorting (Good/Bad).
- Excel logging (`informe.xlsx`) with per-product metadata.
- Live webcam processing loop.

---

## Project structure

- main.m
  - Main entry point (previously `SVAPF.m`). Live capture and inspection loop.
- Encadenado.m
  - Extracts a contour/chain signature from a thinned edge image.
- Firmado.m
  - Compares an extracted signature to stored signatures (.mat) and returns best match and score.
- IdentificarFiguraHu.m
  - Compares Hu moments against a Hu-database (.mat files) to determine the object shape.
- CalcularMomentosHu.m
  - Computes Hu invariant moments from a binary image (calls moment helpers).
- MomentoInicial.m, MomentoCentral.m, MomentoNormalizado.m
  - Low-level raw/central/normalized moment calculations.
- BDF\ (example path)
  - Expected folder with stored signature `.mat` files for `Firmado`.
- BDHU\ (example path)
  - Expected folder with stored Hu moment `.mat` files for `IdentificarFiguraHu`.
- informe.xlsx
  - Excel log created/updated by the script.

---

## Requirements

- MATLAB (R2019a or later recommended)
- Image Processing Toolbox (for rgb2gray, edge, bwmorph, imcrop, insertText, etc.)
- MATLAB Support Package for USB Webcams (for `webcam` function) or equivalent
- Serial port support (recommended MATLAB R2019b+ for `serialport`)
- Excel write support (`writecell`/`writematrix`) — adjust to `xlswrite` if using older MATLAB versions
- A USB webcam accessible to MATLAB
- Arduino (optional) connected on a known serial port if actuation is required

No external Python packages are needed.

---

## Setup & run

1. Place the repository files in a MATLAB project folder.
2. Prepare the databases:
   - Create a signatures folder (example: `BDF\`) and add `.mat` files containing stored signatures.
   - Create a Hu moments folder (example: `BDHU\`) and add `.mat` files with Hu moments matrices (rows = objects, columns = 7 Hu moments).
3. Edit `main.m` (top of file) to configure:
   - `RUTA_FIRMAS` (signatures path)
   - `RUTA_HU` (Hu moments path)
   - `cam = webcam(index)` — select the correct camera index
   - `umbral` — binarization threshold (0–255)
   - `recorteAncho`, `recorteAlto` — crop area size
   - `arduinoPort` — serial port for Arduino (e.g., `'COM4'` or `'/dev/ttyUSB0'`)
4. Run the main script:
   ```matlab
   main
   ```
   The script will open a live loop, display processed frames, annotate results, send serial codes to Arduino, and append rows to `informe.xlsx`.

To stop the loop, interrupt execution (Ctrl+C) or close the display window.

---

## Configurable parameters (in `main.m`)

- RUTA_FIRMAS — root path for signature database (folder containing signature `.mat` files or subfolders).
- RUTA_HU — path to folder with Hu moment `.mat` files.
- cam (webcam index) — select index for your system; use `webcamlist` to enumerate devices.
- umbral — binarization threshold (e.g., 130).
- recorteAncho / recorteAlto — crop (inspection) width and height, tuned to object size.
- arduinoPort — serial port string for Arduino (baud set to 9600 in example).
- Excel filename/path — modify if you want different logging location or filename.
- Thresholds used in decision logic:
  - Hu-confidence threshold (example: > 40 to accept shape)
  - Signature confidence checks (per `Firmado` logic)
  - Business rules for determining "Good" vs "Bad" (adjust inside main logic)

---

## Pipeline (high level)

1. Capture frame and crop centered ROI.
2. Convert to grayscale and binarize to get a binary mask.
3. Calculate centroid from mask and sample a small HSV window at center for color classification.
4. Compute Hu moments from the binary mask and query the Hu moments DB to identify shape.
5. Detect edges, thin them, and extract contour signature via `Encadenado`.
6. Match the signature against the signatures DB with `Firmado`.
7. Apply decision rules (shape + signature confidences) to mark part as Good/Bad.
8. Send "1" (Good) or "2" (Bad) over serial to Arduino.
9. Insert text overlay on the image and save a row in Excel with results and confidences.

---

## Function descriptions

- main.m
  - Configures parameters, camera, serial, Excel header; runs the infinite inspection loop.
- Encadenado(f2)
  - Traverses a thinned edge image and returns a radial-distance signature vector plus centroid coordinates.
- Firmado(firma, RUTARaiz, dhu)
  - Loads saved signature `.mat` files from a selected subfolder of `RUTARaiz`, interpolates vectors when needed, computes correlation and returns the best match label and a percentage score.
- IdentificarFiguraHu(imagen_binaria, rutaBD)
  - Computes Hu moments for the binary mask and compares against the stored Hu matrices in `rutaBD` to find the best matching shape and a heuristic confidence score.
- CalcularMomentosHu.m, MomentoInicial.m, MomentoCentral.m, MomentoNormalizado.m
  - Helpers to compute raw/central/normalized moments and the 7 Hu invariants.

---

## Output & logging

- Excel (`informe.xlsx`) stores inspection rows including:
  - product index, date/time, batch number, detected signature name, shape, color, state (Good/Bad), signature and Hu confidences.
- Arduino commands:
  - `"1"` → Good part
  - `"2"` → Bad part
- Visual feedback:
  - Edges/contours drawn in green and an inserted text box at the top-left with the detection results.

---
