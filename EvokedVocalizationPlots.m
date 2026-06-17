function [BirdName, Current, Frequency, Duration, IntanFilePath, WavFilePath] = EvokedVocalizationPlots()
% ========================================================================
% Function: EvokedVocalizationPlots
%
% Description:
% This function launches a graphical user interface (GUI) for selecting
% experiment metadata and data directories required for evoked vocalization
% analysis.
%
% The GUI allows the user to:
% - Enter bird/subject name
% - Enter stimulation current (µA)
% - Enter stimulation frequency (Hz)
% - Enter pulse duration (ms)
% - Select a folder containing Intan (.rhd) files
% - Select a folder containing aligned audio (.wav) files
%
% After all inputs are provided, the user can choose between:
% - "All Spectrograms"      -> Runs PlotEvokedVocalizationAllSpectrogram
% - "Average Spectrograms"  -> Runs PlotEvokedVocalizationAvgSpectrogram
%
% Prior to running either analysis, the GUI validates:
% - Bird name is not empty
% - Numeric parameters are valid
% - Numeric parameters are non-negative
% - Selected folders exist
% - At least one .rhd file is present in the Intan folder
% - At least one .wav file is present in the audio folder
%
% Workflow:
% 1. Display GUI for metadata entry and folder selection
% 2. User selects analysis type
% 3. Inputs are validated
% 4. Selected plotting function is executed
%
% Dependencies:
%   Required user functions:
%     - PlotEvokedVocalizationAllSpectrogram.m
%     - PlotEvokedVocalizationAvgSpectrogram.m
%   
%   Required data:
%     - Folder containing Intan .rhd files
%     - Folder containing aligned .wav files
%   
%   MATLAB requirements:
%     - Built-in GUI functions (dialog, uicontrol, uigetdir)
%     - No additional toolboxes required by this GUI
%
% Notes:
% - This function serves as the main graphical entry point for evoked
%   vocalization spectrogram analysis.
% - The plotting functions are called directly from the GUI callbacks.
% - Output arguments are generated internally during validation and passed
%   to the plotting functions; the function is not intended to return
%   values to the workspace.
%
% Written by Anand C Krishnan (2026)
% For use in the Rajan Lab, IISER Pune
%
%
% Disclaimer:
% This MATLAB GUI script was written with the assistance of generative AI
% tools. Its role is limited to collecting user inputs necessary to run the
% accompanying analysis scripts. The underlying analysis scripts and 
% analytical methods were written entirely by the author (Anand C Krishnan).
%
% This code is intended for research use within the lab.
% Please acknowledge the author if this code contributes to your work.
% ========================================================================



% ---------------------- Create Dialog ----------------------
d = dialog('Position',[450 250 500 420], ...
           'Name','Experiment Setup', ...
           'Color',[0.96 0.96 0.96]);

% ---------------------- Title ----------------------
uicontrol('Parent',d,'Style','text',...
    'Position',[50 380 400 30],...
    'String','Evoked Vocalization Analysis',...
    'FontSize',14,'FontWeight','bold',...
    'BackgroundColor',[0.96 0.96 0.96]);

% ---------------------- Labels ----------------------
labels = {'Bird name:', 'Current (uA):', 'Frequency (Hz):', 'Duration (ms):'};
ypos   = [310 280 250 220];

for i = 1:4
    uicontrol('Parent',d,'Style','text',...
        'Position',[50 ypos(i) 120 20],...
        'String',labels{i},...
        'HorizontalAlignment','left',...
        'BackgroundColor',[0.96 0.96 0.96]);
end

% ---------------------- Inputs ----------------------
birdEdit = uicontrol('Parent',d,'Style','edit',...
    'Position',[180 310 200 25],'String','birdname');

currEdit = uicontrol('Parent',d,'Style','edit',...
    'Position',[180 280 200 25],'String','0');

freqEdit = uicontrol('Parent',d,'Style','edit',...
    'Position',[180 250 200 25],'String','0');

durEdit  = uicontrol('Parent',d,'Style','edit',...
    'Position',[180 220 200 25],'String','0');

% ---------------------- Paths ----------------------
intanText = uicontrol('Parent',d,'Style','text',...
    'Position',[50 150 300 25],...
    'String','No Intan folder selected',...
    'BackgroundColor','w',...
    'HorizontalAlignment','left');

wavText = uicontrol('Parent',d,'Style','text',...
    'Position',[50 100 300 25],...
    'String','No WAV folder selected',...
    'BackgroundColor','w',...
    'HorizontalAlignment','left');

% ---------------------- Browse Buttons ----------------------
uicontrol('Parent',d,'Position',[360 150 90 30],...
    'String','Browse',...
    'Callback',@(src,event) selectFolder(intanText));

uicontrol('Parent',d,'Position',[360 100 90 30],...
    'String','Browse',...
    'Callback',@(src,event) selectFolder(wavText));

% ---------------------- Action Buttons ----------------------

uicontrol('Parent',d,'Position',[50 30 170 40],...
    'String','All Spectrograms',...
    'Callback',@(src,event) runAllSpectrograms());

uicontrol('Parent',d,'Position',[240 30 170 40],...
    'String','Average Spectrograms',...
    'Callback',@(src,event) runAvgSpectrograms());

uicontrol('Parent',d,'Position',[430 30 60 40],...
    'String','Cancel',...
    'Callback',@(src,event) delete(d));

% ---------------------- Helper Function ----------------------
function selectFolder(textHandle)
    path = uigetdir(pwd, 'Select folder');
    
    if isequal(path,0)
        return; % user cancelled
    end
    
    set(textHandle,'String',path);
end

% ---------------------- Run All Spectrograms ----------------------
function runAllSpectrograms()

    [BirdName, Current, Frequency, Duration, ...
     IntanFilePath, WavFilePath] = validateInputs();

    PlotEvokedVocalizationAllSpectrogram( ...
        BirdName, Current, Frequency, Duration, ...
        IntanFilePath, WavFilePath);

end


% ---------------------- Run Average Spectrograms ----------------------
function runAvgSpectrograms()

    [BirdName, Current, Frequency, Duration, ...
     IntanFilePath, WavFilePath] = validateInputs();

    PlotEvokedVocalizationAvgSpectrogram( ...
        BirdName, Current, Frequency, Duration, ...
        IntanFilePath, WavFilePath);

end


% ---------------------- Validate Inputs ----------------------
function [BirdName, Current, Frequency, Duration, ...
          IntanFilePath, WavFilePath] = validateInputs()

    BirdName  = strtrim(birdEdit.String);

    Current   = str2double(currEdit.String);
    Frequency = str2double(freqEdit.String);
    Duration  = str2double(durEdit.String);

    IntanFilePath = get(intanText,'String');
    WavFilePath   = get(wavText,'String');

    % Bird name
    if isempty(BirdName)
        errordlg('Bird name cannot be empty.');
        error('Bird name empty.');
    end

    % Numeric check
    if any(isnan([Current Frequency Duration]))
        errordlg('Invalid numeric input.');
        error('Invalid numeric input.');
    end

    % Non-negative check
    if any([Current Frequency Duration] < 0)
        errordlg('Values must be non-negative.');
        error('Negative values.');
    end

    % Folder validation
    if contains(IntanFilePath,'No Intan') || ...
       contains(WavFilePath,'No WAV') || ...
       ~isfolder(IntanFilePath) || ...
       ~isfolder(WavFilePath)

        errordlg('Please select valid folders.');
        error('Invalid folders.');
    end

    % File checks
    rhdFiles = dir(fullfile(IntanFilePath, '*.rhd'));
    wavFiles = dir(fullfile(WavFilePath, '*.wav'));

    if isempty(rhdFiles)
        errordlg('No .rhd files found.');
        error('Missing .rhd files.');
    end

    if isempty(wavFiles)
        errordlg('No .wav files found.');
        error('Missing .wav files.');
    end

end

end