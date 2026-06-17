function PlotEvokedVocalizationAllSpectrogram(BirdName, Current, Frequency, Duration, IntanFilePath, WavFilePath)
% ========================================================================
% Function: PlotEvokedVocalizationAllSpectrogram
%
% Author: Anand C Krishnan
% Last updated: 02-03-2026
%
% Description:
% This function detects stimulation bursts from Intan digital input signals,
% aligns them with corresponding audio recordings, and plots spectrograms
% for individual evoked vocalization trials.
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
% 1. Load and concatenate all Intan (.rhd) files:
%    - Extract ADC timestamps and digital input signals
% 2. Clean digital input:
%    - Remove short events (<0.3 ms)
%    - Detect stimulation pulse onsets
% 3. Detect stimulation bursts:
%    - Group pulses into bursts
%    - Separate bursts using an inter-pulse gap threshold of 0.9 s
% 4. Load and concatenate aligned audio recordings
% 5. Prompt the user for the number of trials to display
% 6. For each selected burst:
%    - Extract audio surrounding the burst
%    - Bandpass filter the audio (300–10000 Hz)
%    - Compute a spectrogram
%    - Display the spectrogram in a vertically aligned trial layout
% 7. Add common time axis and experiment metadata
%
% Outputs:
%   None
%   A figure containing spectrograms from individual stimulation trials.
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
%   - bwareaopen
%   - waitbar
%
% Usage:
%   PlotEvokedVocalizationAllSpectrograms( ...
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

Time_Intan = [];
Dig_Intan  = [];

% Concatenate time and digital input across all files
for i = 1:length(IntanNames)
    [t_board_adc, ~, ~, ~, board_dig_in_data] = ...
        read_Intan_RHD2000_file_M(IntanNames{i});

    Time_Intan = [Time_Intan, t_board_adc];
    Dig_Intan  = [Dig_Intan, board_dig_in_data];
end

Fs = 30000;   % Sampling frequency (Hz)


%% --------------------- Clean digital input signal -----------------------

% Minimum pulse width threshold (in samples)
min_width = round(0.0003 * Fs);   % ~0.3 ms

% Remove short noise spikes
clean_signal = bwareaopen(Dig_Intan, min_width);


%% ---------------------- Detect pulses and bursts ------------------------

% Detect rising edges (pulse starts)
pulse_start_idx = find(diff(clean_signal) == 1) + 1;

% Remove closely spaced pulses (<1 ms apart)
min_sep = 0.001 * Fs;
pulse_start_idx = pulse_start_idx([true diff(pulse_start_idx) > min_sep]);

% Compute gap between pulses
pulse_gap = diff(pulse_start_idx) / Fs;

% Identify burst start and end indices
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

% Concatenate aligned audio files
for i = 1:length(PyCBSNames)
    [~, name, ~] = fileparts(IntanNames{i});   % base name from Intan
    wavname = [name '.wav_Aligned.wav'];       % aligned wav name
    
    [x, Fs] = audioread(wavname);
    PyCBSData = [PyCBSData; x];
end


%% ---------------------- Trial parameters --------------------------------

% Ask user for number of trials to plot
prompt = {'Enter number of trials to plot:'};
dlgtitle = 'Input';
dims = [1 40];
definput = {'30'};   % default value

answer = inputdlg(prompt, dlgtitle, dims, definput);

if isempty(answer)
    error('User cancelled input.');
end

NumTrials = str2double(answer{1});

if isnan(NumTrials) || NumTrials <= 0
    error('Invalid number of trials entered.');
end

% Ensure NumTrials does not exceed available bursts
maxTrials = length(burst_start_idx);

if NumTrials > maxTrials
    warning('Requested trials exceed available bursts. Using maximum available (%d).', maxTrials);
    NumTrials = maxTrials;
end


Pre  = 0.2 * Fs;   % Time before burst (samples)
Post = 0.5 * Fs;   % Time after burst (samples)


%% ---------------------- Initialize waitbar ------------------------------

f = waitbar(0, 'Processing...');
pause(0.5);


%% ---------------------- Main plotting loop ------------------------------
figure
for i = 1:NumTrials
    
    % Define window around burst
    BurstTime   = burst_start_idx(i) / Fs;
    start_sample = burst_start_idx(i) - Pre;
    end_sample   = burst_end_idx(i)   + Post;

    % Extract time and audio segment
    Time = Time_Intan(start_sample:end_sample);
    Time = Time - BurstTime;

    RawSong = PyCBSData(start_sample:end_sample);

    % Bandpass filter (300–10,000 Hz)
    FiltSong = bandpass(RawSong, Fs, 300, 10000);

    %% -------- Spectrogram computation --------
    
    nfft = round(Fs * 8 / 1000);     % 8 ms window
    nfft = 2^nextpow2(nfft);

    spect_win = hanning(nfft);
    noverlap  = round(0.95 * length(spect_win));

    [spect, freq, time_song] = ...
        spectrogram(FiltSong, spect_win, noverlap, nfft, Fs, 'yaxis');

    %% -------- Spectrogram scaling --------
    
    idx_spect = scale_spect(spect);

    freq_spect = [freq(1), freq(end)];
    time_spect = [Time(1), Time(end)];

    %% -------- Plotting --------
    
    if i < NumTrials
        ax(i) = subplot(NumTrials + 10, 1, i);
    else
        ax(i) = subplot(NumTrials + 10, 1, [NumTrials+1:NumTrials+10]);
    end

    disp_idx_spect(idx_spect, time_spect, freq_spect, ...
        -55, -10, 1.2, 'hot', 'classic');

    axis([time_spect(1) time_spect(2) 300 8000]);
    hold on

    % Mark burst onset
    xline(0, 'k', 'LineWidth', 2);

    axis off

    % Update progress
    waitbar(i/NumTrials, f, ...
        sprintf('Progress: %d of %d', i, NumTrials));
end


%% ---------------------- Align subplot formatting ------------------------

for i = 1:NumTrials
    pos = get(ax(i), 'Position');
    pos(1) = 0.08;   % left margin
    pos(3) = 0.82;   % width
    set(ax(i), 'Position', pos);
end


%% ---------------------- Add common axis ---------------------------------

han = axes('Position', [0.08 0.08 0.82 0.85]);
set(han, 'Color', 'none')
set(han, 'XLim', [time_spect(1) time_spect(2)])
set(han, 'YTick', [])
set(han, 'YColor', 'none')
set(han, 'Box', 'off')
set(han, 'XAxisLocation', 'bottom')

xticks([-0.2:0.2:1.6])
xlabel('Time from burst onset (s)')


%% ---------------------- Final formatting --------------------------------

sgtitle({
    '\bf Evoked Vocalization', ...
    ['\rm ' BirdName ' (' num2str(Current) ' uA, ' ...
     num2str(Frequency) ' Hz, ' num2str(Duration) ' ms)']
});

set(gca, 'FontSize', 15, 'FontName', 'Arial')
set(gcf, 'Color', 'White')


%% ---------------------- Finish ------------------------------------------

waitbar(1, f, 'Finishing...');
pause(0.5);
close(f)

end