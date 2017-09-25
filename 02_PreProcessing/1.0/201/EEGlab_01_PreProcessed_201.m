%% Author: Haiyang Jin
% This script can only run in the cluster.
% This one was used for the EEG data that have been removed components via
% ADJUST manully.

if ~isunix
    error('This script can only run in Cluster!');
end

%% input info
experimentNum = '1';    % the number of experiment
participantNum = [1:21];  % participant NAMEs :21

% DivEpo labels
if strcmp(experimentNum, '1')
    labels = {'F017' 'F050'  'F100'  'F200'  'H017'  'H050'  'H100'  'H200'};
else
    labels = {'NF7+'  'NF5+'  'NF1+'  'NF2+'  'NH7+'  'NH5+'  'NH1+'  'NH2+' ...
              'SF7+'  'SF5+'  'SF1+'  'SF2+'  'SH7+'  'SH5+'  'SH1+'  'SH2+'};
end
epochStart =  -0.1;
epochEnd = 0.8;

% divEpochStart =  -0.2;
% divEpochEnd = 0.6;

%% 100 Preparation 
% %% info based on the input
fileFolder = ['20' experimentNum];  % pilot,201,202  the name of the folder that save the data for one experiment
experiment = ['P' experimentNum];   % Pilot,P0; E1,P1; E2,P2.

% Preparation for cluster
addpath('/home/hjin317/eeglab/');
homePath = '/gpfs1m/projects/uoa00424/'; % the project folder
ID = getenv('SLURM_ARRAY_TASK_ID');
participantName = num2str(participantNum(str2num(ID)),[experiment,'%02d']);  %P101

filePath = [homePath,fileFolder,filesep];
dt = datestr(now,'yymmddHH');
% fileName = strcat(participantName, '_01_Raw data', '.set'); % the name of the raw file

% 00 DivEpo
condSavePath = strcat(filePath, '04_DivEpo_manual', filesep);

%% load PreProcessed files 
% the filename of PreProcessed data
preProcessedName = strcat(participantName, '_03_PreProcessed_manual','.set');
preProcessedFolder = '03_PreProcessed_manual';
prePath = [filePath, preProcessedFolder, filesep];

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_loadset('filename',preProcessedName,'filepath',prePath);
[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

%%%% 116 Reject epoch
EEG = pop_eegthresh(EEG,1,[1:128] ,-100,100,epochStart,epochEnd,2,0);

%%%% 117 Baseline correction
EEG = pop_rmbase( EEG, [epochStart*1000 0]);
[ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

disp('Save the preProcessed file successfully!');


%% 201 Divide data into different conditions

for j = 1:length(labels)

    % 01 load PreProcessed files
    STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG=[]; CURRENTSET=[];
    EEG = pop_loadset('filename',preProcessedName,'filepath',prePath);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );

    % 02 select event for each condition
    theLabel = labels(j);
    labelName = strcat(participantName, '_04_',labels{j});
    % labelFile = strcat(loadPath,labelName);
    
    EEG = eeg_checkset( EEG );
    EEG = pop_selectevent( EEG, 'type',theLabel,'deleteevents','off','deleteepochs','on','invertepochs','off');
%     EEG = pop_epoch( EEG, label, [divEpochStart divEpochEnd], 'newname', labelName, 'epochinfo', 'yes');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 
    EEG = eeg_checkset( EEG );
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname',labelName,'gui','off'); 
    EEG = eeg_checkset( EEG );
    EEG = pop_saveset( EEG, 'filename',labelName,'filepath',condSavePath);
    EEG = eeg_checkset( EEG );
    
end

disp('Divide the epoches successfully!');


%% %% 301 Create ERP study
% crete the study only for this participant
numParticipant = 1;
studyName = ['EEG_',fileFolder,'_',participantName,'_',dt]; 
loadPath = [filePath,'04_DivEpo_manual',filesep]; %input load path
numLabel = length(labels);

clear studyDesign
studyDesign = cell(1,numParticipant*numLabel);

for iLabel = 1:numLabel
    
    for iParticipant = 1:numParticipant
        epochi = iParticipant+(iLabel-1)*numParticipant;
        index = numLabel*iParticipant+(iLabel-1);
        %subject = num2str(theParticipant(iParticipant),'S%02d');
        label = labels{iLabel};
        epochLoadFile = [loadPath, participantName,'_04_', label, '.set'];

        studyDesign{1, epochi}= {'index' index 'load' epochLoadFile 'subject' participantName 'condition' label};
        
    end
end

[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
[STUDY ALLEEG] = std_editset( STUDY, ALLEEG, 'name',studyName,'updatedat','off','commands', studyDesign);
[STUDY ALLEEG] = std_precomp(STUDY, ALLEEG, 'channels', 'interp','on', 'recompute','on','erp','on');
tmpchanlocs = ALLEEG(1).chanlocs; STUDY = std_erpplot(STUDY, ALLEEG, 'channels', { tmpchanlocs.labels }, 'plotconditions', 'together');
[STUDY EEG] = pop_savestudy( STUDY, EEG, 'filename',studyName,'filepath',loadPath);
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];

%%%% 302 load data
% load data for precompute baseline
fileName = [studyName, '.study'];
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
[STUDY ALLEEG] = pop_loadstudy('filename', fileName, 'filepath', loadPath);
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];

%%%% 303 precompute baseline
[STUDY ALLEEG] = std_precomp(STUDY, ALLEEG, {},'interp','on','recompute','on','erp','on','erpparams',{'rmbase' [-200 0] });
EEG = eeg_checkset( EEG );
[STUDY EEG] = pop_savestudy( STUDY, EEG, 'savemode','resave');
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];

disp('Create the study for this participant successfully!');
