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
    error('This script can only run in Cluster!');
end

%% input info
epochStart =  -0.5;
epochEnd = 1;
isHighFilter1 = 1; % if the high filter frequency is 1 Hz, 

%% 100 Preparation %%% changes needed for new user %%%
% get the ID (string) and 
ID = getenv('SLURM_ARRAY_TASK_ID'); 

if length(ID) ~= 4
    error('There should be two digitials for array in *.sl file.');
end

% name of this participant
subjCode = ['P' ID(2:4)];
backupSubjCode = subjCode;
% get the experimentNum
experimentNum = ID(2);
disp(experimentNum);
switch ID(1)  % get the round number 2 or 4
    case '2'
        roundNum = '1';
    case '4'
        roundNum = '2'; 
end

% exp infor (participant)
ExpInfo;

% Preparation for cluster 
Mahuika;

% Paths where data will be saved
dt = datestr(now,'yymmddHH'); 
expFolder = ['20' experimentNum];  % pilot,201,202  the name of the folder that save the data for one experiment
% expFolderPath = [projectPath,expFolder,filesep];  % where the raw data are saved
outPath = [outputPath, 'All_', num2str(nSubj), filesep]; % where the output will be saved
if ~exist('outputPath', 'dir')
    mkdir(outPath);
end
jobID = getenv('SLURM_ARRAY_JOB_ID'); % get the job ID from Cluster
fopen([outPath jobID '_' ID '.txt'],'w+'); % create a txt file whose filename is the job ID

% Loop to run 1st part of preprocessing (just after clean line)
% for iParticipant = 1:numParticipant
%% Preparation
% get the participant name
%     participantName = num2str(theParticipants(iParticipant),['P', experimentNum,'%02d']);  %P101
% filenames to be saved later
% rawFilename = strcat(participantName, '_01_Raw data'); % the name of the raw file
ICAName = strcat(subjCode, '_02_ICAed_',dt);
tempFile = strcat(outPath, subjCode, '_tempFile', roundNum, '.mat');

tempfile_weight = strcat(outPath, subjCode, '_EEGweight.mat');


%% PREPROCESSING %%
% high frequency filter for the two rounds data
% highFilter = [1, 0.1];
iProcess = str2double(roundNum);

%%%% load the temp1 data
eeglab;
load(tempFile);
subjCode = backupSubjCode;
ICAWeightName = strcat(subjCode, '_ICAWeight_',dt);

% EEG = pop_loadset('filename',tempFile,'filepath',outputPath);

%%%% 107 Remove bad channels
chanStruct = EEG.chanlocs;
EEG = clean_rawdata(EEG, 5, -1, 0.8, -1, 8, 0.25);

%%%% 108 Interpolate all the removed channels
EEG = pop_interp(EEG,chanStruct,'Spherical');

%%%% 109 Re-reference the data to average
% Apply average reference after adding initial reference
EEG.nbchan = EEG.nbchan+1;
EEG.data(end+1,:) = zeros(1, EEG.pnts);
EEG.chanlocs(1,EEG.nbchan).labels = 'initialReference';
EEG = pop_reref(EEG, []);
EEG = pop_select( EEG,'nochannel',{'initialReference'});

if iProcess == 1
    %%%% 110: Run AMICA using calculated data rank with 'pcakeep' option
    % create a folder to save the tmpdata***
    tempFolder = [outPath, subjCode, filesep];
    if ~exist('tempFolder', 'dir')
        mkdir(tempFolder);
    end 
    cd(tempFolder);
    
    if isfield(EEG.etc, 'clean_channel_mask')
        dataRank = min([rank(double(EEG.data')) sum(EEG.etc.clean_channel_mask)]);
    else
        dataRank = rank(double(EEG.data'));
    end
    runamica15(EEG.data, 'num_chans', EEG.nbchan,...
        'outdir', [outPath ICAWeightName],...
        'pcakeep', dataRank, 'num_models', 1,...
        'do_reject', 1, 'numrej', 15, 'rejsig', 3, 'rejint', 1);
    EEG.etc.amica  = loadmodout15([outPath ICAWeightName]);
    EEG.etc.amica.S = EEG.etc.amica.S(1:EEG.etc.amica.num_pcs, :);
    EEG.icaweights = EEG.etc.amica.W;
    EEG.icasphere  = EEG.etc.amica.S;
    EEG = eeg_checkset(EEG, 'ica');
    EEG_Weight = EEG;
    
    % save the EEG_Weight from 1 Hz data
    save(tempfile_weight, 'EEG_Weight', '-v7.3');
    disp('Save the EEG_Weight file successfully!');
    
elseif iProcess == 2
    % load EEG_Weight from 1 Hz data
    load(tempfile_weight);
    
    %%%% apply the ICA weight from 1 Hz data to 0.1 Hz data
    EEG = pop_editset(EEG, 'icachansind', 'EEG_Weight.icachansind', ...
        'icaweights', 'EEG_Weight.icaweights', 'icasphere', 'EEG_Weight.icasphere');
end


% only run this part for step 4
if strcmp(roundNum, '2')  
    %%%% 111: Estimate single equivalent current dipoles
    coordinateTransformParameters = [0.05476 -17.3653 -8.1318 0.075502 0.0031836 -1.5696 11.7138 12.7933 12.213];
    templateChannelFilePath = [eeglabPath, 'plugins/dipfit2.3/standard_BEM/elec/standard_1005.elc'];
    hdmFilePath = [eeglabPath, '/plugins/dipfit2.3/standard_BEM/standard_vol.mat'];
    EEG = pop_dipfit_settings( EEG, 'hdmfile', hdmFilePath, 'coordformat', 'MNI',...
        'mrifile', [eeglabPath, '/plugins/dipfit2.3/standard_BEM/standard_mri.mat'],...
        'chanfile', templateChannelFilePath, 'coord_transform', coordinateTransformParameters,...
        'chansel', 1:EEG.nbchan);
    EEG = pop_multifit(EEG, 1:EEG.nbchan,'threshold', 100, 'dipplot','off','plotopt',{'normlen' 'on'});
    
    %%%% 112: Search for and estimate symmetrically constrained bilateral dipoles
    EEG = fitTwoDipoles(EEG, 'LRR', 35);
    
    %%%% 114 epoch data
    EEG = pop_epoch(EEG, labels, [epochStart  epochEnd], 'newname', preProcessedName,...
        'epochinfo', 'yes');
    
    %%%% 113 Save the ICAed data for further IC rejection on PC
    [~, EEG] = pop_newset(ALLEEG, EEG, 0,'setname',ICAName,'gui','off');
    EEG = pop_saveset( EEG, 'filename', ICAName, 'filepath', outPath);
    
    disp('Save the ICAed file successfully!');
end

% %% automatic delete the artifacts in ICs
% % %%%% 114 Adjust
% % [art] = ADJUST (EEG,ADJUSTOutputName);
% % [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
% %
% % %%%% 115 Removed comoponents
% % EEG = eeg_checkset( EEG );
% % EEG = pop_subcomp( EEG, art, 0);
