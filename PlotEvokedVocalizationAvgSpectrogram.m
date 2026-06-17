function PlotEvokedVocalizationAvgSpectrogram(BirdName, Current, Frequency, Duration, IntanFilePath, WavFilePath)
% ========================================================================
% Function: PlotEvokedVocalizationAvgSpectrogram
%
% Author: Anand C Krishnan
% Last updated: 02-03-2026
%
% Description:
% This function detects stimulation bursts from Intan digital input
% signals, aligns them with corresponding audio recordings, and computes
% trial-averaged measures of evoked vocalizations.
%
% The analysis includes:
%   - Average spectrogram
%   - Average amplitude envelope (± SEM)
%   - Average respiration/pressure trace (± SEM, if available)
%
% Inputs:
%   BirdName      : Bird/subject identifier
%   Current       : Stimulation current (µA)
%   Frequency     : Stimulation frequency (Hz)
%   Duration      : Pulse duration (ms)
%   IntanFilePath : Directory containing Intan (.rhd) files
%   WavFilePath   : Directory containing aligned audio (.wav) files
%
% Workflow:
% 1. Load and concatenate Intan (.rhd) files:
%    - ADC timestamps
%    - Digital input signals
%    - Pressure signal (ADC channel 2, if present)
% 2. Clean digital input:
%    - Remove events shorter than 0.3 ms
%    - Detect pulse onsets
% 3. Detect stimulation bursts:
%    - Group pulses into bursts
%    - Separate bursts using a 0.9 s inter-pulse gap threshold
% 4. Load and concatenate aligned audio recordings
% 5. Define analysis windows around each burst
% 6. Normalize all trials to a common duration
% 7. For each burst:
%    - Extract audio and pressure segments
%    - Bandpass filter audio (300–10000 Hz)
%    - Compute amplitude envelope using the Hilbert transform
%    - Compute spectrogram
% 8. Compute trial-averaged measures:
%    - Mean spectrogram
%    - Mean amplitude profile and SEM
%    - Mean pressure trace and SEM (if available)
% 9. Plot averaged results
%
% Outputs:
%   None
%   A figure containing:
%     - Average spectrogram
%     - Average amplitude profile (± SEM)
%     - Average pressure trace (± SEM, if available)
%
% Dependencies:
%   - read_Intan_RHD2000_file_M.m
%   - scale_spect.m
%   - disp_idx_spect.m
%
% MATLAB functions/toolboxes:
%   - audioread
%   - spectrogram
%   - bandpass
%   - hilbert
%   - smooth
%   - bwareaopen
%   - waitbar
%
% Usage:
%   PlotEvokedVocalizationAvgSpectrograms( ...
%       BirdName, Current, Frequency, Duration, ...
%       IntanFilePath, WavFilePath)
%
% Written by Anand C Krishnan (2026)
% For use in the Rajan Lab, IISER Pune
%
%
% Disclaimer:
% This MATLAB script was written entirely by the author (Anand C Krishnan).
% Generative AI tools were used solely to formalize the code comments for 
% improved readability and documentation. AI use was limited to enhancing 
% the accompanying comments and documentation.
%
% This code is intended for research use within the lab.
% Please acknowledge the author if this code contributes to your work.
% ========================================================================


%% -------------------------- Load Intan data -----------------------------

cd(IntanFilePath)
files = dir('*.rhd');
IntanNames = {files.name};

Time_Intan   = [];
Dig_Intan    = [];
PressureData = [];
hasPressure = false;   % flag to track availability

% Concatenate time, digital input, and pressure signals
for i = 1:length(IntanNames)
    [t_board_adc, ~, board_adc_data, ~, board_dig_in_data] = ...
        read_Intan_RHD2000_file_M(IntanNames{i});

    Time_Intan   = [Time_Intan, t_board_adc];
    Dig_Intan    = [Dig_Intan, board_dig_in_data];

    % Check if ADC channel 2 (pressure) exists
    if size(board_adc_data, 1) >= 2
        PressureData = [PressureData, board_adc_data(2, :)];
        hasPressure = true;
    end
end

Fs = 30000;   % Sampling frequency (Hz)


%% --------------------- Clean digital input signal -----------------------

min_width = round(0.0003 * Fs);   % ~0.3 ms threshold
clean_signal = bwareaopen(Dig_Intan, min_width);


%% ---------------------- Detect bursts -----------------------------------

pulse_start_idx = find(diff(clean_signal) == 1) + 1;

min_sep = 0.001 * Fs; % 1 ms
pulse_start_idx = pulse_start_idx([true diff(pulse_start_idx) > min_sep]);

pulse_gap = diff(pulse_start_idx) / Fs;

burst_start_idx = pulse_start_idx([true pulse_gap > 0.9]);
burst_start_idx(end) = [];
burst_start_idx(1)   = [];

burst_end_idx = pulse_start_idx([pulse_gap > 0.9 false]);
burst_end_idx(1) = [];


%% -------------------------- Load WAV data -------------------------------

cd(WavFilePath)
files = dir('*.wav');
PyCBSNames = {files.name};

PyCBSData = [];

% Concatenate aligned audio
for i = 1:length(PyCBSNames)
    [~, name, ~] = fileparts(IntanNames{i});
    wavname = [name '.wav_Aligned.wav'];

    [x, Fs] = audioread(wavname);
    PyCBSData = [PyCBSData; x];
end


%% ---------------------- Trial parameters --------------------------------

NumTrials = 30;              % Number of bursts to analyze
Pre  = 0.2 * Fs;            % Time before burst (samples)
Post = 0.5 * Fs;            % Time after burst (samples)


%% ---------------------- Normalize burst lengths -------------------------

burstLengths = (burst_end_idx - burst_start_idx + 1) + Pre + Post;
minLen = min(burstLengths);   % enforce equal length across trials


%% ---------------------- Initialize storage ------------------------------

Spectrogram_All = [];
Amp_All         = [];

if hasPressure
    Pressure_All = [];
end

Time_Vector = [];
Freq_Vector = [];


%% ---------------------- Main processing loop ----------------------------

f = waitbar(0, 'Processing...');
pause(0.5)

for i = 1:NumTrials
    
    BurstTime = burst_start_idx(i) / Fs;

    start_sample = max(1, burst_start_idx(i) - Pre);
    end_sample   = start_sample + minLen - 1;

    % Extract signals
    Time     = Time_Intan(start_sample:end_sample) - BurstTime;
    RawSong  = PyCBSData(start_sample:end_sample);

    if hasPressure
        Pressure = PressureData(start_sample:end_sample);
        Pressure_All(:,i) = Pressure;
    end

    % Filter audio
    FiltSong = bandpass(RawSong, Fs, 300, 10000);

    % Amplitude envelope (Hilbert transform)
    AmpProfile = abs(hilbert(FiltSong));
    Amp_All(:, i) = AmpProfile;

    %% -------- Spectrogram --------
    nfft = round(Fs * 8 / 1000);
    nfft = 2^nextpow2(nfft);

    spect_win = hanning(nfft);
    noverlap  = round(0.95 * length(spect_win));

    [spect, freq, t_spec] = spectrogram(FiltSong, spect_win, noverlap, nfft, Fs, 'yaxis');
    spect_power = abs(spect);

    % Align spectrogram time to burst onset
    t_spec = t_spec - Pre/Fs;

    if i == 1
        Spectrogram_All = zeros(size(spect_power,1), size(spect_power,2), NumTrials);
        Time_Vector = [t_spec(1), t_spec(end)];
        Freq_Vector = [freq(1), freq(end)];
    end

    Spectrogram_All(:,:,i) = spect_power;

    waitbar(i/NumTrials, f, sprintf('Progress: %d of %d', i, NumTrials));
end

waitbar(1,f,'Finishing...');
pause(0.5)
close(f)


%% ---------------------- Compute averages --------------------------------

Mean_Spectrogram = mean(Spectrogram_All, 3);
idx_mean_spect   = scale_spect(Mean_Spectrogram);

if hasPressure
    Mean_Pressure = mean(Pressure_All, 2);
    SEM_Pressure = std(Pressure_All, 0, 2)/sqrt(NumTrials);
end

Mean_AmpProfile = mean(Amp_All, 2);
SEM_AmpProfile  = std(Amp_All, 0, 2) / sqrt(NumTrials);

Time_Vector_Amp = (1:minLen)/Fs - Pre/Fs;

% Optional smoothing
Mean_AmpProfile = smooth(Mean_AmpProfile, 20);


%% ---------------------- Plotting ----------------------------------------

figure;
if hasPressure
    nRows = 3;
else
    nRows = 2;
end

% --- Spectrogram ---
subplot(nRows,1,1)
disp_idx_spect(idx_mean_spect, Time_Vector, Freq_Vector, -50, -10, 1.5, 'hot', 'classic');
axis([Time_Vector(1) Time_Vector(end) 300 8000])

hold on
xline(0, '-', 'Color', [1 1 1], 'LineWidth', 2.5);
xlabel('Time from burst onset (s)')
ylabel('Frequency (Hz)')
title('Average Spectrogram')
set(gca, 'FontSize', 15, 'FontName', 'Arial')

% --- Amplitude ---
subplot(nRows,1,2)

amp_color = [0 0.2 0.8];

patch([Time_Vector_Amp fliplr(Time_Vector_Amp)], ...
      [(Mean_AmpProfile+SEM_AmpProfile)' fliplr((Mean_AmpProfile-SEM_AmpProfile)')], ...
      amp_color, 'EdgeColor','none', 'FaceAlpha',0.25);

hold on
plot(Time_Vector_Amp, Mean_AmpProfile, 'Color', amp_color, 'LineWidth', 2);

xlim([Time_Vector(1) Time_Vector(end)])
xline(0, '-', 'Color', [0.8 0 0], 'LineWidth', 1.5);
xlabel('Time from burst onset (s)')
ylabel('Amplitude')
title('Average Amplitude Profile')
set(gca, 'FontSize', 15, 'FontName', 'Arial')

% --- Pressure ---
if hasPressure
    subplot(nRows,1,3)

    upper = Mean_Pressure + SEM_Pressure;
    lower = Mean_Pressure - SEM_Pressure;

    t = Time_Vector_Amp(:)';
    upper = upper(:)';
    lower = lower(:)';

    press_color = [0 0.2 0.8];

    patch([t fliplr(t)], [upper fliplr(lower)], ...
        press_color, 'EdgeColor','none', 'FaceAlpha',0.25);

    hold on
    plot(Time_Vector_Amp, Mean_Pressure, 'Color', press_color, 'LineWidth', 2);

    xlim([Time_Vector(1) Time_Vector(end)])
    xline(0, '-', 'Color', [0.8 0 0], 'LineWidth', 1.5);
    xlabel('Time from burst onset (s)')
    ylabel('Pressure (a.u.)')
    title('Average Pressure')
    set(gca, 'FontSize', 15, 'FontName', 'Arial')
end


%% ---------------------- Final formatting --------------------------------

sgtitle({
    '\bf Evoked Vocalization', ...
    ['\rm ' BirdName ' (' num2str(Current) ' uA, ' ...
     num2str(Frequency) ' Hz, ' num2str(Duration) ' ms)']
});

set(gcf, 'Color', 'White')

end