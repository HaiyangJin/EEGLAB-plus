function allTrialTable = st_trialmulti(studyPath, channels, saveCSV)
% This script helps to get the raw trial data from multiple data set
% (*.set).
if nargin < 1 || isempty(studyPath)
    if ispc || ismac  % if it is on pc or mac
        [filenames, studyPath] = uigetfile({'*.set', 'eeglab data set (*.set)'}, ...
            'Please select all the files you want to get the raw trial data', ...
            'MultiSelect', 'on');
    else % if it is on cluster
        studyPath = pwd;
        files = dir('*.set');
        filenames = {files.name};
    end
else
    cd(studyPath);
    files = dir('*.set');
    filenames = {files.name};
end

if nargin < 2 || isempty(channels)
    channels = [];
else
    channels = channame(channels);
end
if nargin < 3
    saveCSV = 0;
end

% check how many files are selected
if iscell(filenames)
    nFiles = length(filenames);
elseif filenames ~= 0
    nFiles = 1;
else
    error('No files are selected for eeglab_trialmulti!')
end

%% save raw trial data for each file
% eeglab; % eeglab dir should be added to matlab Path.

if nFiles == 1
    EEG = pop_loadset('filename',filenames,'filepath',studyPath);
    allTrialTable = st_trialdata(EEG, channels);
else
    allTrialTable = table;
    for iFile = 1:nFiles
        thisFilename = filenames{1, iFile}; % this filename
        EEG = pop_loadset('filename',thisFilename,'filepath',studyPath);
        
        thisAllTrialEpoch = st_trialdata(EEG, channels);

        allTrialTable = vertcat(allTrialTable, thisAllTrialEpoch); %#ok<AGROW>
    end
end

if ~isunix && saveCSV
    csvName = ['rawERPTrial_' num2str(nFiles) '_' datestr(now, 'yyyymmdd') '.csv'];
    writetable(allTrialTable, csvName);
end
disp(['Output the trial data for ' num2str(nFiles) ' files successfully!']);

end