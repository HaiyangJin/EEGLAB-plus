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
epochStart = -0.5;
epochEnd = 1;
addpath(genpath(['.', filesep, 'Common_Functions']));

%% 100 Preparation %%% changes needed for new user %%%
% get the ID (string) and name of this participant
ID = getenv('SLURM_ARRAY_TASK_ID'); 
subjCode = ['P' ID];

% get the experimentNum
expCode = ID(1);
disp(expCode);

% Preparation for cluster 
Mahuika;

% Paths where data will be saved
dt = datestr(now,'yymmddHH'); 
expFolder = ['20' expCode];  % pilot,201,202  the name of the folder that save the data for one experiment
expFolderPath = [projectPath,expFolder,filesep];  % where the raw data are saved
outputPath = [expFolderPath, dt(1:6), filesep]; % where the output will be saved
if ~exist('outputPath', 'dir')
    mkdir(outputPath);
end
jobID = getenv('SLURM_ARRAY_JOB_ID'); % get the job ID from Cluster
fopen([outputPath jobID '_' ID '.txt'],'w+'); % create a txt file whose filename is the job ID

% filenames to be saved later
rawFilename = strcat(subjCode, '_01_Raw data'); % the name of the raw file
ICAName = strcat(subjCode, '_02_ICAed_',dt);
ICAWeightName = strcat(subjCode, '_ICAWeight_',dt); 

% check if there are only 1 raw file for this participant
oneRawFile = strcmp(subjCode, 'P209') || strcmp(subjCode, 'P211')...
    || strcmp(subjCode, 'P301') || strcmp(subjCode, 'P304')...
    || strcmp(subjCode, 'P311')...
    || strcmp(expCode, '4') ...
    || strcmp(expCode, '5');

appendNeeded = 0;
if strcmp(subjCode, 'P426') || strcmp(subjCode, 'P428') ...
        || strcmp(subjCode, 'P500') || strcmp(subjCode, 'P503')
    appendNeeded = 1; 
end

%% PREPROCESSING %%
% high frequency filter for the two rounds data 
highFilter = [1, 0.1];
nFilter = length(highFilter);
if ~ismember(nFilter, [1 2])
    error('Please check the filter setting for ICA!');
end

for iProcess = 1:nFilter
    %%%%%%% iProcess = 1  %%%%%%%%%%%
    % get the ICA weight for the 1Hz high filtered data
    
    %%%%%%% iProcess = 2  %%%%%%%%%%%
    % run the pipeline for the 0.1Hz high filtered data and apply the ICA
    % weight from data of step 1
    
    %%%% 101 Load raw data and save it
    eeglab versions;  % start the eeglab
    pop_editoptions( 'option_storedisk', 1, 'option_savetwofiles', 1, 'option_saveversion6', 1, ...
        'option_single', 0, 'option_memmapdata', 0, 'option_eegobject', 0, 'option_computeica', 1, ...
        'option_scaleicarms', 1, 'option_rememberfolder', 1, 'option_donotusetoolboxes', 0, ...
        'option_checkversion', 1, 'option_chat', 0); % uncheck 'If set, use single precision under...'
    
    if appendNeeded
        AppendData;
    elseif oneRawFile
        rawName = [subjCode, '.RAW'];
        EEG = pop_readegi([expFolderPath, rawName], [],[],'auto');
    else
        rawName = [subjCode, '001.RAW'];
        EEG = pop_readsegegi([expFolderPath, rawName]); %'C:\EEG data\202_EEG&Mask\P021\P021001.RAW')
    end
    [~, EEG] = pop_newset(ALLEEG, EEG, 1,'setname',rawFilename,'gui','off');
    EEG = pop_saveset(EEG, 'filename',rawFilename,'filepath',expFolderPath); % save the raw data as backup
    
    %%%% 102 Change time point
    allevents = {EEG.event.type};
    if ismember(expCode, {'2', '3'})
        isSaveEvent = cellfun(@(x) ismember(x(4), {'+', '-'}), allevents);
    elseif ismember(expCode, {'4', '5'})
        isSaveEvent = cellfun(@(x) strcmp(x(4), '+') || strcmp(x(1:3), 'blo'), allevents);
    end
    screenEvents = unique(allevents(isSaveEvent));
    EEG = correctEventDelay(EEG, 50, screenEvents);
    
    %%%% 103 Re-sample to 250 Hz
    EEG = pop_resample(EEG, 250);
    
    %%%% 104 Filter the data between 1-Hz (high) and 50 Hz (low)
    EEG  = pop_basicfilter(EEG,  1:EEG.nbchan, 'Cutoff', [highFilter(iProcess) 50], ...
        'Design', 'butter', 'Filter', 'bandpass', 'Order',  4, 'RemoveDC', 'on' );
    
    %%%% 105 Import channel info
    EEG = pop_chanedit(EEG, 'load',{strcat(projectPath,'Common_Functions', filesep, 'GSN-HydroCel-129.sfp') 'filetype' 'autodetect'},...
        'setref',{'4:132' 'Cz'},'changefield',{132 'datachan' 0});
%     EEG = pop_chanedit(EEG, 'load',{'GSN-HydroCel-129.sfp' 'filetype' 'autodetect'},...
%         'setref',{'4:132' 'Cz'},'changefield',{132 'datachan' 0});
%     
    %%%% 106 Remove line noise using CleanLine
    EEG = pop_cleanline(EEG, 'bandwidth', 2,'chanlist', 1:EEG.nbchan, ...
        'computepower', 0, 'linefreqs', [50 100 150 200 250], 'normSpectrum', 0, ...
        'p', 0.01, 'pad', 2, 'plotfigures', 0, 'scanforlines', 1, 'sigtype', 'Channels',...
        'tau', 100, 'verb', 1, 'winsize', 4, 'winstep', 4);
    
    %%%% 107 Remove bad channels
    chanStruct = EEG.chanlocs;
%     EEG = clean_rawdata(EEG, 5, -1, 0.8, -1, 8, 0.25);
    EEG = clean_rawdata(EEG, 5, -1, 0.8, -1, 20, -1);
    
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
        tempFolder = [outputPath, subjCode, filesep];
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
            'outdir', [outputPath ICAWeightName],...
            'pcakeep', dataRank, 'num_models', 1,...
            'do_reject', 1, 'numrej', 15, 'rejsig', 3, 'rejint', 1);
        EEG.etc.amica  = loadmodout15([outputPath ICAWeightName]);
        EEG.etc.amica.S = EEG.etc.amica.S(1:EEG.etc.amica.num_pcs, :); 
        EEG.icaweights = EEG.etc.amica.W;
        EEG.icasphere  = EEG.etc.amica.S;
        EEG = eeg_checkset(EEG, 'ica');
        EEG_Weight = EEG;
        
    elseif iProcess == 2
        %%%% apply the ICA weight from 1 Hz data to 0.1 Hz data
        EEG = pop_editset(EEG, 'icachansind', 'EEG_Weight.icachansind', ...
            'icaweights', 'EEG_Weight.icaweights', 'icasphere', 'EEG_Weight.icasphere');
    end
    
end

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
if strcmp(expCode, '1')
    events_epoch = {'F017' 'F050'  'F100'  'F200'  'H017'  'H050'  'H100'  'H200'};
elseif strcmp(expCode, '2') || strcmp(expCode, '3')
    events_epoch = {'NF7+'  'NF5+'  'NF1+'  'NF2+'  'NH7+'  'NH5+'  'NH1+'  'NH2+' ...
        'SF7+'  'SF5+'  'SF1+'  'SF2+'  'SH7+'  'SH5+'  'SH1+'  'SH2+'};
elseif strcmp(expCode, '4') || strcmp(expCode, '5')
    events_epoch = {'NF7+'  'NF2+'  'NH7+'  'NH2+'...
        'SF7+'  'SF2+'  'SH7+'  'SH2+'};
end

EEG = pop_epoch(EEG, events_epoch, [epochStart  epochEnd], 'newname', ICAName,...
    'epochinfo', 'yes');
    
%%%% 113 Save the ICAed data for further IC rejection on PC
[~, EEG] = pop_newset(ALLEEG, EEG, 0,'setname',ICAName,'gui','off');
EEG = pop_saveset( EEG, 'filename', ICAName, 'filepath', outputPath);

disp('Save the ICAed file successfully!');

%% automatic delete the artifacts in ICs
% %%%% 114 Adjust
% [art] = ADJUST (EEG,ADJUSTOutputName);
% [ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
% 
% %%%% 115 Removed comoponents
% EEG = eeg_checkset( EEG );
% EEG = pop_subcomp( EEG, art, 0);
