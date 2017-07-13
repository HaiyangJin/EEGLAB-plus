%% Author: Haiyang Jin
% This script can only run in the cluster.
% If a new user use this one, the folder where raw data are stored should
% be motified. 

if ~isunix
    error('This script can only run in Cluster!');
end

%% input info
experimentNum = '1';    % the number of experiment
participantNum = 1:21;  % participant NAMEs :21

% DivEpo labels
if strcmp(experimentNum, '1')
    labels = {'F017' 'F050'  'F100'  'F200'  'H017'  'H050'  'H100'  'H200'};
else
    labels = {'NF7+'  'NF5+'  'NF1+'  'NF2+'  'NH7+'  'NH5+'  'NH1+'  'NH2+' ...
              'SF7+'  'SF5+'  'SF1+'  'SF2+'  'SH7+'  'SH5+'  'SH1+'  'SH2+'};
end
epochStart =  -0.3;
epochEnd = 1;

divEpochStart =  -0.3;
divEpochEnd = 0.6;

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
fileName = strcat(participantName, '_01_Raw data_', dt, '.set'); % the name of the raw file

% the name of raw file
if strcmp(participantName,'P106') 
    rawName = [participantName, '_2001.RAW'];
else
    rawName = [participantName, '001.RAW'];
end
ICAName = strcat(participantName, '_02_ICAed_',dt);
ADJUSTOutputName = [participantName,'_ADJUST_',dt,'.txt'];

% 00 DivEpo
condSavePath = strcat(filePath, 'DivEpo/');
preProcessedName = strcat(participantName, '_03_PreProcessed_',dt,'.set');


%%%% 101 Load raw data and save it
eeglab;
disp(rawName);
[ALLEEG EEG CURRENTSET, ALLCOM] = eeglab;
if strcmp(participantName,'P209') || strcmp(participantName,'P211') == 1
    EEG = pop_readegi([filePath, rawName], [],[],'auto');
else
    EEG = pop_readsegegi([filePath, rawName]); 
end
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname',fileName(1:16),'gui','off'); 
EEG = eeg_checkset( EEG );
EEG = pop_saveset( EEG, 'filename',fileName,'filepath',filePath);
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);


%%%% 102 Change time point
EEG = correctTriggerLatency(EEG,50);

%%%% 103 Re-sample to 250 Hz
% EEG = pop_resample( EEG, 250);

%%%% 104 Filter the data between 1-Hz (high) and 30 Hz (low) 
EEG  = pop_basicfilter( EEG,  1:128 , 'Cutoff', [ 1 30], 'Design', 'butter', 'Filter', 'bandpass', 'Order',  4, 'RemoveDC', 'on' );
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off'); 

%%%% 105 Remove line noise using CleanLine
EEG = pop_cleanline(EEG, 'bandwidth',2,'chanlist',[1:128] ,'computepower',1,'linefreqs',[50 100] ,'normSpectrum',0,'p',0.01,'pad',2,'plotfigures',0,'scanforlines',1,'sigtype','Channels','tau',100,'verb',1,'winsize',4,'winstep',4);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off'); 
close(2);

%%%% 106 Import channel info
EEG=pop_chanedit(EEG, 'load',{strcat(homePath,'GSN-HydroCel-129.sfp') 'filetype' 'autodetect'},'setref',{'4:132' 'Cz'},'changefield',{132 'datachan' 0});
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%%%% 107 Remove bad channels
chanStruct = EEG.chanlocs;
[EEG] = pop_rejchanspec( EEG, 'freqlims', [0 35], 'stdthresh', [-15 3], 'plotchans', 'off');
% EEG = pop_rejchan(EEG, 'elec',[1:128] ,'threshold',[-15 3] ,'norm','on','measure','spec','freqrange',[0 35] );

[ badElecs,votes ] = rejChanLocalAmp( EEG ,5000,10,5);
EEG = pop_select( EEG,'nochannel',badElecs);

EEG = pop_interp(EEG,chanStruct,'Spherical');
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off');

%%%% 108 Re-reference the data to average
EEG = eeg_checkset( EEG );
EEG = pop_reref( EEG, [],'refloc',struct('labels',{'Cz'},'Y',{0},'X',{5.4492e-16},'Z',{8.8992},'sph_theta',{0},'sph_phi',{90},'sph_radius',{8.8992},'theta',{0},'radius',{0},'type',{''},'ref',{'Cz'},'urchan',{132},'datachan',{0}));
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off');

%%%% 109 Remove one electrode (to redce data rank)
EEG = eeg_checkset( EEG );
EEG = pop_select( EEG,'nochannel',{'E17'});
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off'); 

%%%% 110 Epoch data 
EEG = eeg_checkset( EEG );
EEG = pop_epoch( EEG, labels, [epochStart  epochEnd], 'newname', ICAName, 'epochinfo', 'yes');
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off'); 
EEG = eeg_checkset( EEG );

%%%% 111 Reject +-500
EEG = pop_eegthresh(EEG,1,[1:128] ,-500,500,epochStart,epochEnd,0,1);
[ALLEEG, EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off'); 

%%%% 112 Reject improbable data
EEG = pop_jointprob(EEG,1,[1:128] ,6,2,1,1);
[ALLEEG, EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off'); 

%%%%  temporarily save ICAed data as a new set and reload it 
EEG = eeg_checkset( EEG );
EEG = pop_saveset( EEG, 'filename',ICAName,'filepath',filePath);
[ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%%%% 113 Run ICA
EEG = eeg_checkset( EEG );
EEG = pop_runica(EEG, 'extended',1,'interupt','on');
[ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%%%%%%%% save as ICAed file %%%%%%%%
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname',ICAName,'gui','off'); 
EEG = eeg_checkset( EEG );
EEG = pop_saveset( EEG, 'filename',ICAName,'filepath',filePath);
[ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%%%% Throw out stuff that ICA shouldn't fix
% stillBads = markBadEpochs(75,32,1,400,1,1000,EEG);
% EEG = pop_rejepoch( EEG, stillBads, 0);

%%%% 114 Adjust
[art] = ADJUST (EEG,ADJUSTOutputName);
[ALLEEG, EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

%%%% 115 Removed comoponents
EEG = eeg_checkset( EEG );
EEG = pop_subcomp( EEG, art, 0);

%%%%%%%% save as PreProcessed file %%%%%%%%
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname',preProcessedName,'gui','off'); 
EEG = eeg_checkset( EEG );
EEG = pop_saveset( EEG, 'filename',preProcessedName,'filepath',filePath);

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
    EEG = pop_loadset('filename',preProcessedName,'filepath',filePath);
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
loadPath = [filePath,'DivEpo',filesep]; %input load path
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
