%% Cluster script for Continuous Data based on Makoto's PreProcessing Pipeline 
% Author: Haiyang Jin (haiyang.jin@auckland.ac.nz)
% This pipeline is based on makoto's PreProcessing pipeline for continuous data 201709
% % 0(1). Change the option to use double precision
% % 1(2). Import data
% % 2(no). offset the time point
% % 3. Downsample if necessary
% % 4. High-pass filter the data at 1-Hz (for ICA, ASR, and CleanLine)
% % 5. Import channel info
% % 6. Remove line noise using CleanLine
% % 7. Apply clean_rawdata() to reject bad channels and correct continuous data 
% %    using Artifact Subspace Reconstruction (ASR)
% % 8. Interpolate all the removed channels
% % 9. Re-reference the data to average
% % 10. Run AMICA using calculated data rank with 'pcakeep' option (or runica() using 'pca' option)
% % 11. Estimate single equivalent current dipoles
% % 12. Search for and estimate symmetrically constrained bilateral dipoles
% % 13. Create STUDY with no STUDY.design just for IC rejection (this greatly 
% %     saves your time--see this page for how to do it)
% % 14. Epoch IC-rejected data to -1 to 2 sec to event onset
% % 15. Create final STUDY specifying full STUDY.design

% If a new user use this one, the folder where raw data are stored should
% be motified. 

% This script can only run in the cluster.
if ~isunix
    error('This script can only run in NeSI!');
end

%% input info
% epochStart = -0.5;
% epochEnd = 1;
isHighFilter1 = 1;  % if the high filter frequency is 1 Hz, 
addpath(['.', filesep, 'Common_Functions']);

%% 100 Preparation %%% changes needed for new user %%%
% get the ID (string) and name of this participant
ID = getenv('SLURM_ARRAY_TASK_ID'); 
% participantName = ['P' ID];
if length(ID) ~= 2
    error('There should be two digitials for array in *.sl file.');
end

% get the experimentNum
experimentNum = ID(2);
disp(experimentNum);
switch ID(1)  % get the round number 1 or 3
    case '1'
        roundNum = '1';
    case '3'
        roundNum = '2';  
end

% ParticipantNum
if strcmp(experimentNum, '1')
    theParticipants = 1:21; 
elseif strcmp(experimentNum, '2')
    theParticipants = 0:19;
elseif strcmp(experimentNum, '3')
    theParticipants = 1:20;
elseif strcmp(experimentNum, '4')
    theParticipants = 1:30;
end
numParticipant = length(theParticipants);

% Preparation for cluster 
eeglabPath = '/home/hjin317/eeglab/';
addpath(eeglabPath);  % add the path for eeglab
projectPath = '/gpfs1m/projects/uoa00424/'; % the project folder

% Paths where data will be saved
dt = datestr(now,'yymmddHH'); 
expFolder = ['20' experimentNum];  % pilot,201,202  the name of the folder that save the data for one experiment
expFolderPath = [projectPath,expFolder,filesep];  % where the raw data are saved
outputPath = [expFolderPath, 'All_', num2str(numParticipant), filesep]; % where the output will be saved
if ~exist('outputPath', 'dir')
    mkdir(outputPath);
end
jobID = getenv('SLURM_ARRAY_JOB_ID'); % get the job ID from Cluster
fopen([outputPath jobID '_' ID '.txt'],'w+'); % create a txt file whose filename is the job ID

% Loop to run 1st part of preprocessing (just after clean line)
for iParticipant = 1:numParticipant
    %% Preparation
    % get the participant name
    participantName = num2str(theParticipants(iParticipant),['P', experimentNum,'%02d']);  %P101
    % filenames to be saved later
    rawFilename = strcat(participantName, '_01_Raw data'); % the name of the raw file
%     ICAName = strcat(participantName, '_02_ICAed_',dt);
%     ICAWeightName = strcat(participantName, '_ICAWeight_',dt);
    tempFile = strcat(outputPath, participantName, '_tempFile', roundNum, '.mat');
%     tempfile_weight = scrcat(outputPath, participantName, '_EEGweight.mat');
    
    % check if there are only 1 raw file for this participant
    oneRawFile = strcmp(participantName, 'P209') || strcmp(participantName, 'P211')...
        || strcmp(participantName, 'P301') || strcmp(participantName, 'P304')...
        || strcmp(participantName, 'P311')...
        || strcmp(experimentNum, '4');
    
    appendNeeded = 0;
    if strcmp(participantName, 'P426') || strcmp(participantName, 'P428')
        appendNeeded = 1;
    end
    
    %% PREPROCESSING %%
    % high frequency filter for the two rounds data
    highFilter = [1, 0.1];
    iProcess = str2double(roundNum);

    %%%%%%% iProcess = 1  %%%%%%%%%%%
    % get the ICA weight for the 1Hz high filtered data
    %%%% 101 Load raw data and save it
    [ALLEEG , ~, ~, ALLCOM] = eeglab;  % start the eeglab
    pop_editoptions( 'option_storedisk', 1, 'option_savetwofiles', 1, 'option_saveversion6', 1, ...
        'option_single', 0, 'option_memmapdata', 0, 'option_eegobject', 0, 'option_computeica', 1, ...
        'option_scaleicarms', 1, 'option_rememberfolder', 1, 'option_donotusetoolboxes', 0, ...
        'option_checkversion', 1, 'option_chat', 0); % uncheck 'If set, use single precision under...'
    
    if appendNeeded
        AppendData;
    elseif oneRawFile
        rawName = [participantName, '.RAW'];
        EEG = pop_readegi([expFolderPath, rawName], [],[],'auto');
    else
        rawName = [participantName, '001.RAW'];
        EEG = pop_readsegegi([expFolderPath, rawName]); %'C:\EEG data\202_EEG&Mask\P021\P021001.RAW')
    end
%     [~, EEG] = pop_newset(ALLEEG, EEG, 1,'setname',rawFilename,'gui','off');
%     EEG = pop_saveset(EEG, 'filename',rawFilename,'filepath',expFolderPath); % save the raw data as backup
    
    %%%% 102 Change time point
    EEG = correctTriggerLatency(EEG,50);
    
    %%%% 103 Re-sample to 250 Hz
%     EEG = pop_resample( EEG, 250);
    
    %%%% 104 Filter the data between 1-Hz (high) and 50 Hz (low)
    EEG  = pop_basicfilter( EEG,  1:128 , 'Cutoff', [highFilter(iProcess) 50], ...
        'Design', 'butter', 'Filter', 'bandpass', 'Order',  4, 'RemoveDC', 'on' );
    
    %%%% 105 Import channel info
    EEG = pop_chanedit(EEG, 'load',{strcat(projectPath,'GSN-HydroCel-129.sfp') 'filetype' 'autodetect'},...
        'setref',{'4:132' 'Cz'},'changefield',{132 'datachan' 0});
    
    %%%% 106 Remove line noise using CleanLine
    EEG = pop_cleanline(EEG, 'bandwidth', 2,'chanlist', 1:EEG.nbchan, ...
        'computepower', 0, 'linefreqs', [50 100 150 200 250], 'normSpectrum', 0, ...
        'p', 0.01, 'pad', 2, 'plotfigures', 0, 'scanforlines', 1, 'sigtype', 'Channels',...
        'tau', 100, 'verb', 1, 'winsize', 4, 'winstep', 4);
    
    %%%% save the matlab space for step 2 
    save(tempFile, '-v7.3');
    
    disp(['Save the temp file for ' participantName ' successfully!']);

    
end
