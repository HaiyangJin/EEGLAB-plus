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
if ~isunix
    error('This script can only run in Cluster!');
end

%% input info
epochStart =  -0.5;
epochEnd = 1;
% isHighFilter1 = 1; % if the high filter frequency is 1 Hz, 

%% 100 Preparation %%% changes needed for new user %%%
% get the ID (string) 
ID = getenv('SLURM_ARRAY_TASK_ID');  % name of this participant
participantName = ['P' ID(2:4)];
experimentNum = ID(2);  % get the experimentNum
disp(experimentNum);

folderInfoNum = ID(1);
switch folderInfoNum
    case '1'
        isIndividual = 2;
        isBasedAcc = 1;
    case '2'
        isIndividual = 1;
        isBasedAcc = 1;
    case '3'
        isIndividual = 1;
        isBasedAcc = 2;
    case '4'
        isIndividual = 2;
        isBasedAcc = 2;
end

indiInfoFolder = {'Individual', 'Group'};
isIndividualFolder = indiInfoFolder{isIndividual};

accInfoFolder = {'Acc', 'All'};
isBasedAccFolder = accInfoFolder{isBasedAcc};

jobID = getenv('SLURM_ARRAY_JOB_ID'); % get the job ID from Cluster

% Preparation for cluster 
eeglabPath = '/home/hjin317/eeglab/';
addpath(eeglabPath);  % add the path for eeglab
projectPath = '/gpfs1m/projects/uoa00424/'; % the project folder

% Paths where data will be saved
dt = datestr(now,'yymmddHH'); 
expFolder = ['20' experimentNum];  % pilot,201,202  the name of the folder that save the data for one experiment
expFolderPath = [projectPath,expFolder,filesep];  % where the raw data are saved


%% 00 Preparation for the second part of preprocessing 
%%%% 00 load the IC Rejected data
% the filename and path for IC rejected data
rejectedFolder = ['03_Rejected', isIndividualFolder];
rejectedName = strcat(participantName, '_', rejectedFolder,'.set');
rejectedPath = [expFolderPath, rejectedFolder, filesep];

% the filename and path for ALL PreProcessed data
preProcessedFolder = [isIndividualFolder, '_', isBasedAccFolder];
preProcessedName = strcat(participantName, '_', preProcessedFolder,'.set');
preProcessedPath = [expFolderPath, preProcessedFolder, filesep];
if ~exist('preProceddedPath', 'dir')
    mkdir(preProcessedPath);
end
fopen([preProcessedPath jobID '_' ID '.txt'],'w+'); % create a txt file whose filename is the job ID

% DivEpo labels
if strcmp(experimentNum, '1')
    oldLabels = {'F017' 'F050'  'F100'  'F200'  'H017'  'H050'  'H100'  'H200'};
    labels = {'NF7+'  'NF5+'  'NF1+'  'NF2+'  'NH7+'  'NH5+'  'NH1+'  'NH2+'};
elseif strcmp(experimentNum, '2') || strcmp(experimentNum, '3')
    labels = {'NF7+'  'NF5+'  'NF1+'  'NF2+'  'NH7+'  'NH5+'  'NH1+'  'NH2+' ...
              'SF7+'  'SF5+'  'SF1+'  'SF2+'  'SH7+'  'SH5+'  'SH1+'  'SH2+'};
elseif strcmp(experimentNum, '4')
    labels = {'NF7+'  'NF2+'  'NH7+'  'NH2+'...
              'SF7+'  'SF2+'  'SH7+'  'SH2+'};
end

% Load the ICRejected (after reject artifacts) data
[ALLEEG] = eeglab;
EEG = pop_loadset('filename',rejectedName,'filepath',rejectedPath);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% replace the labels for experiment 1 %%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(experimentNum, '1')
    for iReLabel = 1: length(oldLabels)
        thisOldLabel = oldLabels(iReLabel);
        thisLabel = labels{iReLabel};
        EEG = pop_selectevent( EEG, 'type', thisOldLabel,'renametype', thisLabel,...
            'deleteevents','off','deleteepochs','off','invertepochs','off');
    end
end
%%%%%%%%%%%% replace the labels for experiment 1 %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% 114 epoch data    
EEG = pop_epoch( EEG, labels, [epochStart  epochEnd], 'newname', preProcessedName,...
    'epochinfo', 'yes');

%%%% 115 Reject +-500
EEG = pop_eegthresh(EEG,1, 1:128 ,-500, 500, epochStart, epochEnd,0,1);
[ALLEEG, EEG , ~] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off');

%%%% 116 Reject improbable data
EEG = pop_jointprob(EEG,1, 1:128, 6, 2, 1, 1);
[~, EEG , ~] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off');

%%%% Throw out stuff that ICA shouldn't fix
% stillBads = markBadEpochs(75,32,1,400,1,1000,EEG);
% EEG = pop_rejepoch( EEG, stillBads, 0);

%%%% 117 Baseline correction
EEG = pop_rmbase( EEG, [epochStart*1000 0]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% work on the labels %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%  Rename the labels as correct and incorrect  %%%%%%%%%%%%%%%%%
if strcmp(isBasedAccFolder,'1')
    % save the label ('RES0' and 'RES1') as 'RESP'. And create another
    % filed 'RESP' wihcih show if this trial is correct or incorrect
    EEG = pop_selectevent( EEG, 'type',{'RES0' 'RES1'},'renametype','RESP',...
        'oldtypefield','RESP','deleteevents','off','deleteepochs','off','invertepochs','off');
    
    % Rename the label with correct or incorrect
    for tempEvent = 1:length({EEG.event.type})
        tempLabel = EEG.event(tempEvent).type;  % this type (label)
        RESP = EEG.event(tempEvent).RESP;   % this response
        if strcmp(tempLabel(1), 'N') && ~isempty(RESP)
            if strcmp(RESP(1:3),'RES') % if there is a label about acc
            EEG.event(tempEvent).type = strcat(EEG.event(tempEvent).type, '_', RESP);
            end
        end
    end
 
    % get the labels for this data set only includes correct trials
    labelAll = unique({EEG.event.type});  % get all the labels for this data set
    tempLabelLogical1 = arrayfun(@(x) length(x{:}), labelAll) > 5; % labels are longer than 5
    tempLabelLogical2 = arrayfun(@(x) strcmp(x{:}(4),'+'), labelAll); % labels for onset only
    tempLabels = labelAll(logical(tempLabelLogical1 .* tempLabelLogical2)); % temp labels based on first two
    
    tempLabelLogical3 = arrayfun(@(x) strcmp(x{:}(9),'1'), tempLabels); % labels for onset only
    labels = tempLabels(tempLabelLogical3);  % get all the labels for correct Normal trials
    
    if strcmp(experimentNum, '3') || strcmp(experimentNum, '4')
        labels = horzcat(labels, {'NF7+_RES0' 'NH7+_RES0'}); % add the labels for incorrect 17ms
    end
    
    if ~strcmp(experimentNum, '1')  % add the lables for scramble trials
        labels = horzcat(labels, {'SF7+'  'SF5+'  'SF1+'  'SF2+'  'SH7+'  'SH5+'  'SH1+'  'SH2+'});
    end
    
    % backup the label names into a cell
    % the labels one experiment should include
    labelsBackup23 = {'NF7+_RES1' 'NF5+_RES1' 'NF1+_RES1' 'NF2+_RES1' ...
                      'NH7+_RES1' 'NH5+_RES1' 'NH1+_RES1' 'NH2+_RES1' ...
                      'NF7+_RES0' 'NH7+_RES0' ...
                      'SF7+' 'SF5+' 'SF1+' 'SF2+' 'SH7+' 'SH5+' 'SH1+' 'SH2+'};
    switch experimentNum
        case '1'
            labelsBackup = {'NF7+_RES1' 'NF5+_RES1' 'NF1+_RES1' 'NF2+_RES1' ...
                            'NH7+_RES1' 'NH5+_RES1' 'NH1+_RES1' 'NH2+_RES1'};
        case '2'
            labelsBackup = labelsBackup23;
        case '3'
            labelsBackup = labelsBackup23;
        case '4'
            labelsBackup = {'NF7+_RES1' 'NF2+_RES1' ...
                            'NH7+_RES1' 'NH2+_RES1' ...
                            'NF7+_RES0' 'NH7+_RES0' ...
                            'SF7+' 'SF2+' 'SH7+' 'SH2+'};
    end

    % create a cell to save the numbers of labels in this exp
    numLabelBack = length(labelsBackup);    % number of labels for backup
    labelsBackCell = cell(2, numLabelBack);
    labelsBackCell(1,:) = labelsBackup;
    labelsBackCell(2,:) = cellfun(@(x) sum(ismember({EEG.event.type},x)),labelsBackup,'un',0);
    % save this label backup cell
    labelBackupName = [preProcessedPath, participantName, '_LabelNumBackup.mat'];
    save(labelBackupName, 'labelsBackCell');
else 
    % create a cell to save the numbers of labels in this exp
    numLabelBack = length(labels);
    labelsBackCell = cell(2, numLabelBack);
    labelsBackCell(1,:) = labels;
    labelsBackCell(2,:) = cellfun(@(x) sum(ismember({EEG.event.type},x)),labels,'un',0);
    % save this label backup cell
    labelBackupName = [preProcessedPath, participantName, '_LabelNumBackup.mat'];
    save(labelBackupName, 'labelsBackCell');
end

%%%%%%%%%%%%%%%%%%%%%%%%%% work on the labels %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% 118 Save the ICAed data for further IC rejection on PC
[~, EEG] = pop_newset(ALLEEG, EEG, 0,'setname', preProcessedName, 'gui','off');
pop_saveset( EEG, 'filename', preProcessedName, 'filepath', preProcessedPath);

disp('Save the preProcessed file successfully!');


%% %% 200 Create ERP study for this participant
% crete the study only for this participant
studyName = ['EEG_', participantName,'_',dt]; 
numLabel = length(labels);

% create the study design for this participant
clear participantTempDesign
participantTempDesign = {'index' 1 'load' [preProcessedPath, preProcessedName]...
    'subject' participantName 'condition' 'OneCondition'};

% create this study with the temp design
[ALLEEG] = eeglab;
[STUDY, ALLEEG] = std_editset(STUDY, ALLEEG, 'name', studyName, 'updatedat','off',...
    'commands', participantTempDesign);

% make the design for this participant
designName = [participantName, '_', preProcessedFolder];
STUDY = std_makedesign(STUDY, ALLEEG, 1, 'variable1','type','variable2','',...
    'name', designName,'pairing1','on','pairing2','on','delfiles','off',...
    'defaultdesign','off','values1',labels, 'subjselect', {participantName});

% precompute baseline
[STUDY , ALLEEG] = std_precomp(STUDY, ALLEEG, {},'interp','on','recompute','on',...
    'erp','on','erpparams',{'rmbase' [ALLEEG(1).xmin*1000 0] });

% save this study
EEG = ALLEEG;
pop_savestudy(STUDY, EEG, 'filename',studyName,'filepath',preProcessedPath);
disp(['Save the study of ', studyName, ' successfully!']);
