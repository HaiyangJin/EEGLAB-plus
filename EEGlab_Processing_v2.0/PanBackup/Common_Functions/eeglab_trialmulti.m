function allTrialTable = eeglab_trialmulti(thisPath)
% This script helps to get the raw trial data from multiple data set
% (*.set).
if nargin < 1
[filenames, thisPath] = uigetfile({'*.set', 'eeglab data set (*.set)'}, ...
    'Please select all the files you want to get the raw trial data', ...
    'MultiSelect', 'on');
else
    cd(thisPath);
    files = dir('*.set');
    filenames = {files.name};
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
channelFiles; % to get the channel names
% eeglab; % run eeglab

if nFiles == 1
    EEG = pop_loadset('filename',filenames,'filepath',thisPath);
    allTrialTable = eeg_trialdata(EEG);
else
    for iFile = 1:nFiles
        thisFilename = filenames{1, iFile}; % this filename
        EEG = pop_loadset('filename',thisFilename,'filepath',thisPath);
        
        thisAllData = eeg_trialdata(EEG);
        
        % To reduce the demand of the memory, only save the potential used electrodues 
        isChan = ismember(thisAllData{:, 'Channel'}, chanSum);
        thisData = thisAllData(isChan, :);
        if iFile == 1
            allTrialTable = thisData;
        else
            allTrialTable = vertcat(allTrialTable, thisData);
        end
    end
end

csvName = ['rawERPTrial_' num2str(nFiles) '_' datestr(now, 'yyyymmdd') '.csv'];
if ~isunix
    writetable(allTrialTable, csvName);
end
disp(['Output the trial data for ' num2str(nFiles) ' files successfully!']);

end