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
% % (+1) Reject +-500
% % (+2) Reject improbable data
% % (+3) Baseline correction
% % 15. Create final STUDY specifying full STUDY.design

% If a new user use this one, the folder where raw data are stored should
% be motified.

% This script can only run in the cluster.
indiInfoFolder = {'Individual', 'Group'};
if isunix && ~ismac
    %% 100 Preparation %%% changes needed for new user %%%
    addpath(genpath('Common_Functions/'));
    
    % get the ID (string)
    ID = getenv('SLURM_ARRAY_TASK_ID');  % name of this participant
    participantName = ['P' ID(2:4)];
    experimentNum = ID(2);  % get the experimentNum
    disp(['The experiment number is ' experimentNum]);
    
    isIndividual = str2double(ID(1));  % 1: individual; 2: group
    
    jobID = getenv('SLURM_ARRAY_JOB_ID'); % get the job ID from Cluster
    
    % Preparation for cluster
    Mahuika;
    
    % Paths where data will be saved
    % dt = datestr(now,'yymmddHH');
    expFolder = ['20' experimentNum];  % pilot,201,202  the name of the folder that save the data for one experiment
    expFolderPath = [projectPath, expFolder, filesep];  % where the raw data are saved
        
    %%%% 00 load the IC Rejected data
    % the filename and path for IC rejected data
    rejectedFolder = ['03_Rejected_', indiInfoFolder{isIndividual}];
    rejectedName = strcat(participantName, '_', rejectedFolder,'.set');
    rejectedPath = [expFolderPath, rejectedFolder, filesep];
    
    nFiles = 1;
    
elseif ispc || ismac
    
    experimentNum = [];
    while isempty(experimentNum)
        experimentNum = input('Please input the experiment Number (1, 2, 3, 4, or 5): ','s');
    end
    
    isIndividual = [];
    while isempty(isIndividual)
        isIndividual = input('Are the ICs rejected individually (1(individually), 2(group)): ');
    end
    
    % open GUI to select the folder where the PreProcessed data are saved
    [filenames, rejectedPath] = uigetfile('*.set', 'Please select all the ICA rejected data files:',...
        'MultiSelect', 'on');
    nFiles = length(filenames);
    
    idcs = strfind(rejectedPath,filesep);
    expFolderPath = [rejectedPath(1:idcs(end-1)-1), filesep];
end

%% input info
preProcessedFolder = indiInfoFolder{isIndividual};
baseline = -200;


%% 00 Preparation for the second part of preprocessing
for iFile = 1:nFiles
    
    if ispc || ismac
        rejectedName = filenames{iFile};
        participantName = rejectedName(1:4);
    end
    
    % the filename and path for ALL PreProcessed data
    preProcessedName = strcat(participantName, '_04_PreProcessed_',preProcessedFolder,'.set');
    preProcessedPath = [expFolderPath, '04_PreProcessed_', preProcessedFolder, filesep];
    if isunix && ~ismac
        fopen([preProcessedPath jobID '_' ID '.txt'],'w+'); % create a txt file whose filename is the job ID
    end
    if ~exist(preProcessedPath, 'dir')
        mkdir(preProcessedPath);
    end
    
    % Load the ICRejected (after reject artifacts) data
    if iFile == 1
        [ALLEEG] = eeglab;
    else
        STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; CURRENTSET=[];  % EEG=[];
    end
    EEG = pop_loadset('filename',rejectedName,'filepath',rejectedPath);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%% replace the labels for experiment 1 %%%%%%%%%%%%%%%%%%%%%%%%%%
    if strcmp(experimentNum, '1')
        oldLabels = {'F017' 'F050'  'F100'  'F200'  'H017'  'H050'  'H100'  'H200'};
        events_all = {'NF7+'  'NF5+'  'NF1+'  'NF2+'  'NH7+'  'NH5+'  'NH1+'  'NH2+'};
        
        for iReLabel = 1: length(oldLabels)
            thisOldLabel = oldLabels(iReLabel);
            thisLabel = events_all{iReLabel};
            EEG = pop_selectevent( EEG, 'type', thisOldLabel,'renametype', thisLabel,...
                'deleteevents','off','deleteepochs','off','invertepochs','off');
        end
    end
    %%%%%%%%%%%% replace the labels for experiment 1 %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%% 114 epoch data (did in EEGlab_110)
    %     EEG = pop_epoch(EEG, labels, [epochStart  epochEnd], 'newname', preProcessedName,...
    %         'epochinfo', 'yes');
    %
    %%%% 115 Reject +-500
    EEG = pop_eegthresh(EEG,1, 1:EEG.nbchan ,-500, 500, EEG.xmin, EEG.xmax,1,0);
%     [ALLEEG, EEG , ~] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off');
    
    %%%% 116 Reject improbable data
    EEG = pop_jointprob(EEG,1, 1:EEG.nbchan, 6, 2, 1, 0);
%     [~, EEG , ~] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off');
    
    %%%% Throw out stuff that ICA shouldn't fix
    % stillBads = markBadEpochs(75,32,1,400,1,1000,EEG);
    % EEG = pop_rejepoch( EEG, stillBads, 0);
    
    %%%% 117 Baseline correction
    EEG = pop_rmbase(EEG, [baseline 0]);
    
    %%%% 118 Save the PreProcessed data set for further data analysis
    [~, EEG] = pop_newset(ALLEEG, EEG, 0,'setname', preProcessedName, 'gui','off');
    pop_saveset( EEG, 'filename', preProcessedName, 'filepath', preProcessedPath);
    
    disp('Save the preProcessed file successfully!');
    
    
    %% %% 200 Create ERP study for this participant
    % crete the study only for this participant
    dt = datestr(now,'yymmddHH');
    studyName = ['EEG_', participantName,'_',dt];
    %     numLabel = length(labels);
    
    % create the study design for this participant
    clear participantTempDesign
    participantTempDesign = {'index' 1 'load' [preProcessedPath, preProcessedName]...
        'subject' participantName 'condition' 'OneCondition'};
    
    % create this study with the temp design
    [ALLEEG] = eeglab;
    [STUDY, ALLEEG] = std_editset(STUDY, ALLEEG, 'name', studyName, 'updatedat','off',...
        'commands', participantTempDesign);
    
    % make the design for this participant
    allEvents = unique({ALLEEG.urevent.type});
    events = allEvents(cellfun(@(x) strcmp(x(4), '+'), allEvents));
    disp(events);
    designName = [participantName, '_', preProcessedFolder];
    STUDY = std_makedesign(STUDY, ALLEEG, 1, 'variable1','type','variable2','',...
        'name', designName,'pairing1','on','pairing2','on','delfiles','off',...
        'defaultdesign','off','values1',events, 'subjselect', {participantName});
    
    % precompute baseline
    [STUDY , ALLEEG] = std_precomp(STUDY, ALLEEG, {},'interp','on','recompute','on',...
        'erp','on','erpparams',{'rmbase' [baseline 0] });
    
    % save this study
    EEG = ALLEEG;
    pop_savestudy(STUDY, EEG, 'filename',studyName,'filepath',preProcessedPath);
    disp(['Save the study of ', studyName, ' successfully!']);
    
end
