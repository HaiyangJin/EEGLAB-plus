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
addpath('Common_Functions/');

% If a new user use this one, the folder where raw data are stored should
% be motified.

% This script can only run in the cluster.
accInfoFolder = {'All', 'Cor', 'Scr'};
indiInfoFolder = {'Individual', 'Group'};
if isunix && ~ismac
    %% 100 Preparation %%% changes needed for new user %%%
    % get the ID (string)
    ID = getenv('SLURM_ARRAY_TASK_ID');  % name of this participant
    participantName = ['P' ID(2:4)];
    experimentNum = ID(2);  % get the experimentNum
    disp(['The experiment number is ' experimentNum]);
    
    folderInfoNum = ID(1);
    is2Block = 0;
    switch folderInfoNum
        case '1'
            basedAcc = 1; % all
            isIndividual = 1; % individual
        case '2'
            basedAcc = 2; % acc
            isIndividual = 1; % individual
        case '3'
            basedAcc = 3; % scramAcc
            isIndividual = 1; % individual
        case '4'
            basedAcc = 1; % all
            isIndividual = 2; % group
        case '5'
            basedAcc = 2; % acc
            isIndividual = 2; % group
        case '6'
            basedAcc = 3; % scramAcc
            isIndividual = 2; % group
        case '8'
            is2Block = 1; % test the diff for two normal face 17ms condition (face specific)
            basedAcc = 1; % scramCor
            isIndividual = 1; % individual
        case '9'
            is2Block = 1; % test the diff for two normal face 17ms condition (face specific)
            basedAcc = 3; % scramCor
            isIndividual = 1; % individual
    end
    
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
    
    basedAcc = [];
    while isempty(basedAcc)
        basedAcc = input('Are the epochs basded on (1)all, (2)acc (3)scrambled acc trials? ');
    end
    
    % open GUI to select the folder where the PreProcessed data are saved
    [filenames, rejectedPath] = uigetfile('*.set', 'Please select all the ICA rejected data files:',...
        'MultiSelect', 'on');
    nFiles = length(filenames);
    
    idcs = strfind(rejectedPath,filesep);
    expFolderPath = [rejectedPath(1:idcs(end-1)-1), filesep];
end

%% input info
epochStart = -0.5;
epochEnd = 1;

isBasedAccFolder = accInfoFolder{basedAcc};
isIndividualFolder = indiInfoFolder{isIndividual};


%% 00 Preparation for the second part of preprocessing
for iFile = 1:nFiles
    
    if ispc || ismac
        rejectedName = filenames{iFile};
        participantName = rejectedName(1:4);
    end
    
    % the filename and path for ALL PreProcessed data
    if is2Block == 0
        preProcessedFolder = [isIndividualFolder, '_', isBasedAccFolder];
    else
        preProcessedFolder = 'Normal_17_Compare';
    end
    preProcessedName = strcat(participantName, '_04_PreProcessed_',preProcessedFolder,'.set');
    preProcessedPath = [expFolderPath, '04_PreProcessed_', preProcessedFolder, filesep];
    if isunix && ~ismac
        fopen([preProcessedPath jobID '_' ID '.txt'],'w+'); % create a txt file whose filename is the job ID
    end
    if ~exist('preProceddedPath', 'dir')
        mkdir(preProcessedPath);
    end
    
    % DivEpo labels
    if strcmp(experimentNum, '1')
        oldLabels = {'F017' 'F050'  'F100'  'F200'  'H017'  'H050'  'H100'  'H200'};
        events_all = {'NF7+'  'NF5+'  'NF1+'  'NF2+'  'NH7+'  'NH5+'  'NH1+'  'NH2+'};
    elseif strcmp(experimentNum, '2') || strcmp(experimentNum, '3')
        events_all = {'NF7+'  'NF5+'  'NF1+'  'NF2+'  'NH7+'  'NH5+'  'NH1+'  'NH2+' ...
            'SF7+'  'SF5+'  'SF1+'  'SF2+'  'SH7+'  'SH5+'  'SH1+'  'SH2+'};
    elseif strcmp(experimentNum, '4') || strcmp(experimentNum, '5')
        events_all = {'NF7+'  'NF2+'  'NH7+'  'NH2+'...
            'SF7+'  'SF2+'  'SH7+'  'SH2+'};
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
        for iReLabel = 1: length(oldLabels)
            thisOldLabel = oldLabels(iReLabel);
            thisLabel = events_all{iReLabel};
            EEG = pop_selectevent( EEG, 'type', thisOldLabel,'renametype', thisLabel,...
                'deleteevents','off','deleteepochs','off','invertepochs','off');
        end
    end
    %%%%%%%%%%%% replace the labels for experiment 1 %%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%% 114 epoch data
    %     EEG = pop_epoch(EEG, labels, [epochStart  epochEnd], 'newname', preProcessedName,...
    %         'epochinfo', 'yes');
    %
    %%%% 115 Reject +-500
    EEG = pop_eegthresh(EEG,1, 1:128 ,-500, 500, epochStart, epochEnd,1,0);
%     [ALLEEG, EEG , ~] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off');
    
    %%%% 116 Reject improbable data
    EEG = pop_jointprob(EEG,1, 1:128, 6, 2, 1, 0);
%     [~, EEG , ~] = pop_newset(ALLEEG, EEG, 1,'overwrite','on','gui','off');
    
    %%%% Throw out stuff that ICA shouldn't fix
    % stillBads = markBadEpochs(75,32,1,400,1,1000,EEG);
    % EEG = pop_rejepoch( EEG, stillBads, 0);
    
    %%%% 117 Baseline correction
    EEG = pop_rmbase(EEG, [-200 0]);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%% work on the labels %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%  Rename the labels as correct and incorrect  %%%%%%%%%%%%%%%%%
    if basedAcc == 1
        % create a cell to save the numbers of labels in this exp
        numLabelBack = length(events_all);
        labelsBackCell = cell(2, numLabelBack);
        labelsBackCell(1,:) = events_all;
        labelsBackCell(2,:) = cellfun(@(x) sum(ismember({EEG.event.type},x)),events_all,'un',0);
        % save this label backup cell
        labelBackupName = [preProcessedPath, participantName, '_LabelNumBackup.mat'];
        save(labelBackupName, 'labelsBackCell');
        events = events_all;
        
%         if is2Block
%             allEvents = unique({EEG.urevent.type});
%             blockEvent = allEvents(cellfun(@(x) strcmp(x(1:3), 'blo'), allEvents));
%             EEG = pop_selectevent( EEG, 'type', blockEvent, 'renametype','Block',...
%                 'oldtypefield','Block','deleteevents','off','deleteepochs','off','invertepochs','off');
%             
%             block = EEG.event(tempEvent).Block;
%             if ~strcmp(block, '')
%                 EEG.event(tempEvent).type = strcat(EEG.event(tempEvent).type, '_', block(end));
%             end
%             
%         end
    elseif basedAcc == 2
        % save all the responses events as {'RESP'}
%         if ~strcmp(experimentNum, '5')
%             % save the label ('RES0' and 'RES1') as 'RESP'. And create another
%             % filed 'RESP' wihcih show if this trial is correct or incorrect
%             respEvents = {'RES0' 'RES1'};
%         else
%             respEvents = {''};
%         end
        allEvents = unique({EEG.urevent.type});
        respEvents =  allEvents(cellfun(@(x) strcmp(x(1:2), 'RE'), allEvents));
        EEG = pop_selectevent( EEG, 'type', respEvents, 'renametype','RESP',...
            'oldtypefield','RESP','deleteevents','off','deleteepochs','off','invertepochs','off');
            
        % Rename the label with correct or incorrect
        for tempEvent = 1:length({EEG.event.type})
            tempLabel = EEG.event(tempEvent).type;  % this type (label)
            RESP = EEG.event(tempEvent).RESP;   % this response
            if strcmp(tempLabel(1), 'N') && ~isempty(RESP)
                if strcmp(RESP(1:2),'RE') % if there is a label about acc
                    EEG.event(tempEvent).type = strcat(EEG.event(tempEvent).type, '_', RESP);
                end
            end
        end
        
        % get the labels for this data set only includes correct trials
        labelAll = unique({EEG.event.type});  % get all the labels for this data set
        tempLabelLogical1 = arrayfun(@(x) length(x{:}), labelAll) > 5; % labels are longer than 5
        tempLabelLogical2 = arrayfun(@(x) strcmp(x{:}(4),'+'), labelAll); % labels for onset only
        tempLabels = labelAll(logical(tempLabelLogical1 .* tempLabelLogical2)); % temp labels based on first two
        
        if ~strcmp(experimentNum, '5')
            tempLabelLogical3 = arrayfun(@(x) strcmp(x{:}(9),'1'), tempLabels); % labels for correct only
        else
            tempLabelLogical3 = true(1, length(tempLabels));
        end
        events = tempLabels(tempLabelLogical3);  % get all the labels for correct Normal trials
        
        % add incorrect events 
        if strcmp(experimentNum, '3') || strcmp(experimentNum, '4')
            events = horzcat(events, {'NF7+_RES0' 'NH7+_RES0'}); %#ok<AGROW> % add the labels for incorrect 17ms
        end
        
        % add scrambled events
        if strcmp(experimentNum, '2') || strcmp(experimentNum, '3')  % add the lables for scramble trials
            events = horzcat(events, {'SF7+'  'SF5+'  'SF1+'  'SF2+'  'SH7+'  'SH5+'  'SH1+'  'SH2+'}); %#ok<AGROW>
        elseif strcmp(experimentNum, '4') || strcmp(experimentNum, '5')
            events = horzcat(events, {'SF7+'  'SF2+'  'SH7+'  'SH2+'}); %#ok<AGROW>
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
            case '5'
                labelsBackup = {...
                    'NF7+_RE11', 'NF7+_RE12', 'NF7+_RE13', 'NF7+_RE14', 'NF7+_RE15', ...
                    'NF2+_RE11', 'NF2+_RE12', 'NF2+_RE13', 'NF2+_RE14', 'NF2+_RE15', ...
                    'NH7+_RE51', 'NH7+_RE52', 'NH7+_RE53', 'NH7+_RE54', 'NH7+_RE55', ...
                    'NH2+_RE51', 'NH2+_RE52', 'NH2+_RE53', 'NH2+_RE54', 'NH2+_RE55', ...
                    'SF7+', 'SF2+', 'SH7+', 'SH2+'};
        end
        
        % create a cell to save the numbers of labels in this exp
        numLabelBack = length(labelsBackup);    % number of labels for backup
        labelsBackCell = cell(2, numLabelBack);
        labelsBackCell(1,:) = labelsBackup;
        labelsBackCell(2,:) = cellfun(@(x) sum(ismember({EEG.event.type},x)),labelsBackup,'un',0);
        % save this label backup cell
        labelBackupName = [preProcessedPath, participantName, '_LabelNumBackup.mat'];
        save(labelBackupName, 'labelsBackCell');
        
    elseif basedAcc == 3
        allEvents = unique({EEG.urevent.type});
        respEvents =  allEvents(cellfun(@(x) strcmp(x(1:2), 'RE'), allEvents));
        % save the label ('RES0' and 'RES1') as 'RESP'. And create another
        % filed 'RESP' wihcih show if this trial is correct or incorrect
        EEG = pop_selectevent( EEG, 'type', respEvents,'renametype','RESP',...
            'oldtypefield','RESP','deleteevents','off','deleteepochs','off','invertepochs','off');
        
        if is2Block
            blockEvent = allEvents(cellfun(@(x) strcmp(x(1:3), 'blo'), allEvents));
            EEG = pop_selectevent( EEG, 'type', blockEvent, 'renametype','Block',...
                'oldtypefield','Block','deleteevents','off','deleteepochs','off','invertepochs','off');
        end
        
        % Rename the labels with correct or incorrect
        for tempEvent = 1:length({EEG.event.type})
            tempLabel = EEG.event(tempEvent).type;  % this type (label)
            RESP = EEG.event(tempEvent).RESP;   % this response
            if is2Block; block = EEG.event(tempEvent).Block; end
            
            %%% if the RT is longer than 1000ms, this trial will not be
            %%% included.
            %         if strcmp(tempLabel(1), 'N') && ~isempty(RESP)
            if ~strcmp(RESP,'') % if there is a label about acc
                EEG.event(tempEvent).type = strcat(tempLabel, '_', RESP);
                if is2Block && ~strcmp(block, '')
                    EEG.event(tempEvent).type = strcat(EEG.event(tempEvent).type, '_', block(end));
                end
                
            end
            %         end
        end
        
        % select the labels for this data set only includes correct trials
        labelAll = unique({EEG.event.type});  % get all the labels for this data set
        tempEventLogical1 = arrayfun(@(x) length(x{:}), labelAll) > 5; % labels are longer than 5
        tempEventLogical2 = arrayfun(@(x) strcmp(x{:}(4),'+'), labelAll); % labels for onset only
        tempEvents = labelAll(logical(tempEventLogical1 .* tempEventLogical2)); % temp labels based on first two
        
        tempEventLogical3 = arrayfun(@(x) strcmp(x{:}(1),'S'), tempEvents); % labels for scrambled stimuli with ACC only
        scrambledEvents = tempEvents(tempEventLogical3);
        tempNormalEvents = tempEvents(~tempEventLogical3);
        
        if ~strcmp(experimentNum, '5')
            tempEventLogical4 = arrayfun(@(x) strcmp(x{:}(9),'1'), tempNormalEvents); % labels for correct trials only
        else
            tempEventLogical4 = true(1, length(tempNormalEvents));
        end
        normalEvents = tempNormalEvents(tempEventLogical4);
        
        
        switch experimentNum
            case '1'
                error('No scrambled trials were included in this experiment!');
            case '2'
                events = horzcat(normalEvents, scrambledEvents);
            case '3'
                events = horzcat(normalEvents, scrambledEvents, {
                    'NF7+_RES0' ...
                    'NH7+_RES0'});
            case '4'
                events = horzcat(normalEvents, scrambledEvents, {
                    'NF7+_RES0' ...
                    'NH7+_RES0'});
            case '5'
                events = horzcat(normalEvents, scrambledEvents);
        end
        
        
        % backup the label names into a cell
        % the labels one experiment should include
        switch experimentNum
            case '1'
                eventsBackup = {
                    'NF7+_RES1' 'NF5+_RES1' 'NF1+_RES1' 'NF2+_RES1' ...
                    'NH7+_RES1' 'NH5+_RES1' 'NH1+_RES1' 'NH2+_RES1'};
            case '2'
                eventsBackup = {
                    'NF7+_RES1' 'NF5+_RES1' 'NF1+_RES1' 'NF2+_RES1' ...
                    'NH7+_RES1' 'NH5+_RES1' 'NH1+_RES1' 'NH2+_RES1' ...
                    ...
                    ...
                    'SF7+_RES1' 'SF5+_RES1' 'SF1+_RES1' 'SF2+_RES1' ...
                    'SH7+_RES1' 'SH5+_RES1' 'SH1+_RES1' 'SH2+_RES1' ...
                    'SF7+_RES0' 'SF5+_RES0' 'SF1+_RES0' 'SF2+_RES0' ...
                    'SH7+_RES0' 'SH5+_RES0' 'SH1+_RES0' 'SH2+_RES0'};
            case '3'
                eventsBackup = {
                    'NF7+_RES1' 'NF5+_RES1' 'NF1+_RES1' 'NF2+_RES1' ...
                    'NH7+_RES1' 'NH5+_RES1' 'NH1+_RES1' 'NH2+_RES1' ...
                    'NF7+_RES0' ...
                    'NH7+_RES0' ...
                    'SF7+_RES1' 'SF5+_RES1' 'SF1+_RES1' 'SF2+_RES1' ...
                    'SH7+_RES1' 'SH5+_RES1' 'SH1+_RES1' 'SH2+_RES1' ...
                    'SF7+_RES0' 'SF5+_RES0' 'SF1+_RES0' 'SF2+_RES0' ...
                    'SH7+_RES0' 'SH5+_RES0' 'SH1+_RES0' 'SH2+_RES0'};
            case '4'
                eventsBackup = {
                    'NF7+_RES1' 'NF2+_RES1' ...
                    'NH7+_RES1' 'NH2+_RES1' ...
                    'NF7+_RES0' ...
                    'NH7+_RES0' ...
                    'SF7+_RES1' 'SF2+_RES1' ...
                    'SH7+_RES1' 'SH2+_RES1' ...
                    'SF7+_RES0' 'SF2+_RES0' ...
                    'SH7+_RES0' 'SH2+_RES0'};
            case '5'
                eventsBackup = {...
                    'NF7+_RE11', 'NF7+_RE12', 'NF7+_RE13', 'NF7+_RE14', 'NF7+_RE15', ...
                    'NF2+_RE11', 'NF2+_RE12', 'NF2+_RE13', 'NF2+_RE14', 'NF2+_RE15', ...
                    'NH7+_RE51', 'NH7+_RE52', 'NH7+_RE53', 'NH7+_RE54', 'NH7+_RE55', ...
                    'NH2+_RE51', 'NH2+_RE52', 'NH2+_RE53', 'NH2+_RE54', 'NH2+_RE55', ...
                    'SF7+_RE11', 'SF7+_RE12', 'SF7+_RE13', 'SF7+_RE14', 'SF7+_RE15', ...
                    'SF2+_RE11', 'SF2+_RE12', 'SF2+_RE13', 'SF2+_RE14', 'SF2+_RE15', ...
                    'SH7+_RE51', 'SH7+_RE52', 'SH7+_RE53', 'SH7+_RE54', 'SH7+_RE55', ...
                    'SH2+_RE51', 'SH2+_RE52', 'SH2+_RE53', 'SH2+_RE54', 'SH2+_RE55'};
                if is2Block
                    no2Events = cellfun(@(x) x(3) ~= '2', eventsBackup);
                    eventsBackup = [cellfun(@(x) [x '_1'], eventsBackup(no2Events),  ...
                        'UniformOutput', false), ...
                        cellfun(@(x) [x '_2'], eventsBackup,  ...
                        'UniformOutput', false)];
                end
        end
        
        % create a cell to save the numbers of labels in this exp
        numLabelBack = length(eventsBackup);    % number of labels for backup
        labelsBackCell = cell(2, numLabelBack);
        labelsBackCell(1,:) = eventsBackup;
        labelsBackCell(2,:) = cellfun(@(x) sum(ismember({EEG.event.type},x)),eventsBackup,'un',0);
        % save this label backup cell
        labelBackupName = [preProcessedPath, participantName, '_LabelNumBackup.mat'];
        save(labelBackupName, 'labelsBackCell');
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%% work on the labels %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
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
    disp(events);
    designName = [participantName, '_', preProcessedFolder];
    STUDY = std_makedesign(STUDY, ALLEEG, 1, 'variable1','type','variable2','',...
        'name', designName,'pairing1','on','pairing2','on','delfiles','off',...
        'defaultdesign','off','values1',events, 'subjselect', {participantName});
    
    % precompute baseline
    [STUDY , ALLEEG] = std_precomp(STUDY, ALLEEG, {},'interp','on','recompute','on',...
        'erp','on','erpparams',{'rmbase' [ALLEEG(1).xmin*1000 0] });
    
    % save this study
    EEG = ALLEEG;
    pop_savestudy(STUDY, EEG, 'filename',studyName,'filepath',preProcessedPath);
    disp(['Save the study of ', studyName, ' successfully!']);
    
end
