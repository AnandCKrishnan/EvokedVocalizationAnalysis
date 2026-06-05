
# Evoked Vocalization Analysis

<br>

## Overview
MATLAB tools for detecting stimulation bursts from Intan recordings and visualizing evoked vocalizations using trial-by-trial and averaged spectrogram analyses.
<br>

## Scripts

### 1. EvokedVocalizationPlots

**Description:**
This function launches a graphical user interface (GUI) for selecting
experiment metadata and data directories required for evoked vocalization
analysis.

The GUI allows the user to:
- Enter bird/subject name
- Enter stimulation current (µA)
- Enter stimulation frequency (Hz)
- Enter pulse duration (ms)
- Select a folder containing Intan (.rhd) files
- Select a folder containing aligned audio (.wav) files

After all inputs are provided, the user can choose between:
- "All Spectrograms"      -> Runs PlotEvokedVocalizationAllSpectrogram
- "Average Spectrograms"  -> Runs PlotEvokedVocalizationAvgSpectrogram

Prior to running either analysis, the GUI validates:
- Bird name is not empty
- Numeric parameters are valid
- Numeric parameters are non-negative
- Selected folders exist
- At least one .rhd file is present in the Intan folder
- At least one .wav file is present in the audio folder

Workflow:
1. Display GUI for metadata entry and folder selection
2. User selects analysis type
3. Inputs are validated
4. Selected plotting function is executed

Dependencies:
  Required user functions:
    - PlotEvokedVocalizationAllSpectrogram.m
    - PlotEvokedVocalizationAvgSpectrogram.m

  Required data:
    - Folder containing Intan .rhd files
    - Folder containing aligned .wav files

  MATLAB requirements:
    - Built-in GUI functions (dialog, uicontrol, uigetdir)
    - No additional toolboxes required by this GUI

Notes:
- This function serves as the main graphical entry point for evoked
  vocalization spectrogram analysis.
- The plotting functions are called directly from the GUI callbacks.
- Output arguments are generated internally during validation and passed
  to the plotting functions; the function is not intended to return
  values to the workspace.

---
<br>

### 2. PlotEvokedVocalizationAllSpectrogram

**Description:**
This function detects stimulation bursts from Intan digital input signals,
aligns them with corresponding audio recordings, and plots spectrograms
for individual evoked vocalization trials.

Inputs:
  BirdName      : Bird/subject identifier
  Current       : Stimulation current (µA)
  Frequency     : Stimulation frequency (Hz)
  Duration      : Pulse duration (ms)
  IntanFilePath : Directory containing Intan (.rhd) files
  WavFilePath   : Directory containing aligned audio (.wav) files

Workflow:
1. Load and concatenate all Intan (.rhd) files:
   - Extract ADC timestamps and digital input signals
2. Clean digital input:
   - Remove short events (<0.3 ms)
   - Detect stimulation pulse onsets
3. Detect stimulation bursts:
   - Group pulses into bursts
   - Separate bursts using an inter-pulse gap threshold of 0.9 s
4. Load and concatenate aligned audio recordings
5. Prompt the user for the number of trials to display
6. For each selected burst:
   - Extract audio surrounding the burst
   - Bandpass filter the audio (300–10000 Hz)
   - Compute a spectrogram
   - Display the spectrogram in a vertically aligned trial layout
7. Add common time axis and experiment metadata

Outputs:
  None
  A figure containing spectrograms from individual stimulation trials.

Dependencies:
  - read_Intan_RHD2000_file_M.m
  - scale_spect.m
  - disp_idx_spect.m

MATLAB functions/toolboxes:
  - audioread
  - spectrogram
  - bandpass
  - bwareaopen
  - waitbar

Usage:
  PlotEvokedVocalizationAllSpectrograms( ...
      BirdName, Current, Frequency, Duration, ...
      IntanFilePath, WavFilePath)

---
<br>

### 3. PlotEvokedVocalizationAvgSpectrogram

**Description:**
This function detects stimulation bursts from Intan digital input
signals, aligns them with corresponding audio recordings, and computes
trial-averaged measures of evoked vocalizations.

The analysis includes:
  - Average spectrogram
  - Average amplitude envelope (± SEM)
  - Average respiration/pressure trace (± SEM, if available)

Inputs:
  BirdName      : Bird/subject identifier
  Current       : Stimulation current (µA)
  Frequency     : Stimulation frequency (Hz)
  Duration      : Pulse duration (ms)
  IntanFilePath : Directory containing Intan (.rhd) files
  WavFilePath   : Directory containing aligned audio (.wav) files

Workflow:
1. Load and concatenate Intan (.rhd) files:
   - ADC timestamps
   - Digital input signals
   - Pressure signal (ADC channel 2, if present)
2. Clean digital input:
   - Remove events shorter than 0.3 ms
   - Detect pulse onsets
3. Detect stimulation bursts:
   - Group pulses into bursts
   - Separate bursts using a 0.9 s inter-pulse gap threshold
4. Load and concatenate aligned audio recordings
5. Define analysis windows around each burst
6. Normalize all trials to a common duration
7. For each burst:
   - Extract audio and pressure segments
   - Bandpass filter audio (300–10000 Hz)
   - Compute amplitude envelope using the Hilbert transform
   - Compute spectrogram
8. Compute trial-averaged measures:
   - Mean spectrogram
   - Mean amplitude profile and SEM
   - Mean pressure trace and SEM (if available)
9. Plot averaged results

Outputs:
  None
  A figure containing:
    - Average spectrogram
    - Average amplitude profile (± SEM)
    - Average pressure trace (± SEM, if available)

Dependencies:
  - read_Intan_RHD2000_file_M.m
  - scale_spect.m
  - disp_idx_spect.m

MATLAB functions/toolboxes:
  - audioread
  - spectrogram
  - bandpass
  - hilbert
  - smooth
  - bwareaopen
  - waitbar

Usage:
  PlotEvokedVocalizationAvgSpectrograms( ...
      BirdName, Current, Frequency, Duration, ...
      IntanFilePath, WavFilePath)

  
---
<br>


### Written by Anand C Krishnan (2026)


These MATLAB scripts are intended for research use within Rajan Lab, IISER Pune.<br>
Please acknowledge the author if this code contributes to your work.
