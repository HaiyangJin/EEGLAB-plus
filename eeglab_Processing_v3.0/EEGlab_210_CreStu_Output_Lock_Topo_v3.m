%% 200 Create a new study  
% Author: Haiyang Jin (haiyang.jin@auckland.ac.nz)
% create a study for all the participants in one experiment

% This script only use one *.set file for each participant to create the
% study, the different conditions are assigned by STUDY.design (based on
% the suggestion from Makoto's PreProcessing Pipeline)

% this script saves the data into table (not a cell)


%% % Prepaparation for different platform
baselineStart = -200;
if isunix && ~ismac
    addpath('Common_Functions/');
    Mahuika;
    % get the experiment number
    ID = getenv('SLURM_ARRAY_TASK_ID');
    display(ID);
    % to make sure the length of ID is two
    if length(ID) ~= 4
        error('There should be four digitals for the array!!!')
    else
        experimentNum = ID(2);    % the number of experiment
        folderInfoNum = ID(1);
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
        end
    end
    
    % get the Job ID from Cluster
    jobID = getenv('SLURM_ARRAY_JOB_ID');
    
    expCode = ['20' experimentNum];  % the folder for this experiment
    expFolderPath = [projectPath,expCode,filesep];  % the path for this experiment
    
elseif ispc || ismac
    % input the number of this experiment
    experimentNum = [];
    while isempty(experimentNum)
        experimentNum = input('Please input the experiment Number (1, 2, 3, or 4): ','s');
    end
    expCode = ['20' experimentNum];
    
    isIndividual = [];
    while isempty(isIndividual)
        isIndividual = input('Are the ICs rejected individually (1(individually), 2(group)): ');
    end
    
    basedAcc = [];
    while isempty(basedAcc)
        basedAcc = input('Are the epochs basded on (1)all, (2) acc (3) scrambled acc trials?  ');
    end
    
else
    error('Platform not supported!');
end

% get the folder info
indiInfoFolder = {'Individual', 'Group'};
isIndividualFolder = indiInfoFolder{isIndividual};

accInfoFolder = {'All', 'Acc', 'ScramAcc'};
isBasedAccFolder = accInfoFolder{basedAcc};

folderInfo = [isIndividualFolder, '_', isBasedAccFolder];

% get the study path
if isunix && ~ismac
    studyPath = [expFolderPath,'04_PreProcessed_', folderInfo, filesep]; % get the study path
    fopen([studyPath jobID '_' ID '.txt'],'w+'); % create a txt file whose filename is the job ID
    
elseif ispc || ismac
    % open GUI to select the folder where the PreProcessed data are saved
    studyPath = [uigetdir('.',...
        'Please choose the folder where the clean (PreProcessed) data are saved.'), filesep];
end


%% Preparation 
% the numbers of all the participant that you want to create the study for
if strcmp(experimentNum, '2')
    theParticipants = 0:19;
elseif strcmp(experimentNum, '1')
    theParticipants = 1:21;
elseif strcmp(experimentNum, '3')
    if basedAcc ~= 1
        theParticipants = [1:8 10:16 18:20];
    else
        theParticipants = 1:20;
    end
elseif strcmp(experimentNum, '4')
    if basedAcc == 3
        theParticipants = [1:7 9:16 18:21 23:30];
    else
        theParticipants = 1:30;
    end
end
numParticipant = length(theParticipants); % the number of participants


%% create the array for the experiment desgin and then create the study
% create the experiment design
clear tempStudyDesign
clear participantList
tempStudyDesign = cell(1, numParticipant);
participantList = cell(1, numParticipant);

preProcessedName = ['_04_PreProcessed_', isIndividualFolder, '_', isBasedAccFolder];

for iParticipant = 1:numParticipant
    tempParticipant = num2str(theParticipants(iParticipant),['P' experimentNum '%02d']);
    
    % get the list of participant names for this study
    participantList{1, iParticipant} = tempParticipant;
    % the filename of the preprocessed file
    dataFilename = [studyPath, tempParticipant, preProcessedName, '.set']; % [path 'P301_04_PreProcessed(_manual)]
    
    tempStudyDesign{1, iParticipant}= {'index' iParticipant ...
                                        'load' dataFilename ...
                                        'subject' tempParticipant ...
                                        'condition' 'OneCondition'};
end

% create the study
[ALLEEG] = eeglab;
dt = datestr(now,'yymmddHH');
studyName = ['EEG_FH_', expCode, '_', num2str(numParticipant), '_', ...
    folderInfo, '_' dt];
[STUDY, ALLEEG] = std_editset(STUDY, ALLEEG, 'name', studyName, 'updatedat','off',...
    'commands', tempStudyDesign);

% get all the lables for this study
events = unique({STUDY.datasetinfo(1).trialinfo.type});
endLetterEvent = cellfun(@(x) x(end), events, 'UniformOutput', false);

if basedAcc == 2 % if the events are for acc trials
    logicEndEvent = strcmp(endLetterEvent,'1');
    
    if strcmp(experimentNum, '3') || strcmp(experimentNum, '4')
        % find the events ending with '0' (except for
        letter3Event = cellfun(@(x) x(3), events, 'UniformOutput', false);
        logic3Event = strcmp(letter3Event,'7');
        letter0Event = cellfun(@(x) x(end), events, 'UniformOutput', false);
        logic0Event = strcmp(letter0Event,'0');
        logic1Event = logical(logic3Event .* logic0Event);
    else
        logic1Event = 0;
    end
    
    % find the events start with S
    letterSEvent = cellfun(@(x) x(1), events, 'UniformOutput', false);
    logic2Event = strcmp(letterSEvent,'S');
    
    logicEvent = logical(logicEndEvent + logic1Event + logic2Event);
    events = events(logicEvent);
elseif basedAcc == 3;
    %%%%%%% combine correct and incorrect scrambled trials together %%%%%%%
    
    %%%%%%% divide correct and incorrect trials %%%%%%
    logicEndEvent = ~strcmp(endLetterEvent,'+');
    
    logic1Event = ~(cellfun(@(x) strcmp(x(1), 'N'), events) ...
        .* ~cellfun(@(x) strcmp(x(3), '7'), events) ...
        .* strcmp(endLetterEvent, '0'));

    logicEvent = logical(logicEndEvent .* logic1Event);
    events = events(logicEvent);
end

% make the design for this study
designName = [expCode, '_', num2str(numParticipant), '_', folderInfo];
STUDY = std_makedesign(STUDY, ALLEEG, 1, 'variable1','type','variable2','',...
    'name', designName,'pairing1','on','pairing2','on','delfiles','off',...
    'defaultdesign','off','values1',events, 'subjselect', participantList);

% precompute baseline
[STUDY , ALLEEG] = std_precomp(STUDY, ALLEEG, {},'interp','on','recompute','on',...
    'erp','on','erpparams',{'rmbase' [baselineStart 0] });

% save this study
EEG = ALLEEG;
STUDY = pop_savestudy( STUDY, EEG, 'filename',studyName,'filepath',studyPath);
disp(['Save the study of ', studyName, ' successfully!']);


%% %%%% 301 Output the mean of raw data into excel %%%% %%
% Output the mean for all trials for each condition, every participant, and
% every channels.

% Create the array for Independent Variable (IV) and another array for Dependent
% Variable (DV). IVs includes participant names, channels, events and so
% on. DVs includes all the EEG data.

% Preparation
elecAll = {STUDY.changrp.channels};  % all the channels in this exp
numChanAll = length(elecAll); % number of channels
% events = STUDY.design.variable(1).value;  % get the event names
numEvents = length(events); % number of events
% participantNames = cellstr(STUDY.subject); % cell array contains all the participant names
participantNames = participantList';

% info about epoch start and end point
epochStart = EEG(1).xmin*1000; % -200;
epochEnd = EEG(1).xmax*1000; % 1499;
epochLength = EEG.pnts; % epochEnd-epochStart+1;

% info about the CELL for the mean raw data
meanRaw_IVs = {'SubjCode', 'Channel', 'Event'};
% create the Variable Names for meanRaw_DVs
lag = 1000 ./ double(EEG(1).srate);
pointsEpoch = epochStart:lag:epochEnd; %#ok<BDSCI>
meanRaw_DVs = cell(1,epochLength);
for iNum = 1:epochLength
    tempNum = pointsEpoch(iNum);
    if tempNum < 0
        tempNeg = num2str(tempNum);
        meanRaw_DVs(1,iNum) =  {['N', tempNeg(2:end)]};
    else
        meanRaw_DVs(1,iNum) = {['P', num2str(tempNum)]};
    end
end

numColu_MeanRawIVs = length(meanRaw_IVs);  % number of columns for IVs
numColu_MeanRawDVs = length(meanRaw_DVs);  % number of columns for DVs

numRow_MeanRaw = numChanAll*numEvents*numParticipant+1;  % number of rows

% the column number of the independent variables
participantColuNum = find(strcmp(meanRaw_IVs, 'SubjCode'));
elecColuNum = find(strcmp(meanRaw_IVs, 'Channel'));
eventColuNum = find(strcmp(meanRaw_IVs, 'Event'));


%% Combine all the trials across all conditions
% create the cell for IVs and DVs of mean raw data
clear cell_RawEpochIVs
cell_RawEpochIVs = cell(numRow_MeanRaw,numColu_MeanRawIVs);
cell_RawEpochIVs(1,:) = meanRaw_IVs;

clear cell_RawEpochDVs;
cell_RawEpochDVs = cell(numRow_MeanRaw,numColu_MeanRawDVs);
cell_RawEpochDVs(1,:) = meanRaw_DVs;

numRowsEachChan = numEvents*numParticipant;

for iChan = 1:numChanAll
    % add the channel names into the IVs
    tempChan = elecAll(iChan); 
    elecStartRow = (iChan-1)*numRowsEachChan+1+1;
    elecEndRow = iChan*numRowsEachChan+1;
    cell_RawEpochIVs(elecStartRow:elecEndRow, elecColuNum) = tempChan;
    
    % get the erpdata from the study
    [STUDY, erpdata, erptimes] = std_erpplot(STUDY,ALLEEG,'channels',tempChan,'noplot', 'on');
    
    for iEvent = 1:numEvents
        % add the event names into the IVs
        thisEvent = events(iEvent);
        eventStartRow = (iEvent-1)*numParticipant + elecStartRow;
        eventEndRow = iEvent*numParticipant - 1 + elecStartRow;
        cell_RawEpochIVs(eventStartRow:eventEndRow,eventColuNum) = thisEvent;
        
        % add participant names into the IVs
        cell_RawEpochIVs(eventStartRow:eventEndRow,participantColuNum) = participantNames;
        
        % add data to the DVs
        erpDataSet = erpdata{iEvent,1}';
        cell_RawEpochDVs(eventStartRow:eventEndRow, :) = num2cell(erpDataSet);
        
    end
    
end
clear tempChan
clear thisEvent

% combine the two cells (IVs and DVs) together and convert to table
cell_RawEpoch = horzcat(cell_RawEpochIVs, cell_RawEpochDVs);
table_RawEpoch = cell2table(cell_RawEpoch(2:end,:), 'VariableNames', cell_RawEpoch(1,:));

% save the mean of the raw data into the excel amd the backup file
if ~exist('dt', 'var')
    dt = datestr(now,'yymmddHH');
end

sheetName_MeanRaw = [expCode,'_RawEpoch']; 
rawEpochName = strcat(studyPath, sheetName_MeanRaw, '_', folderInfo, '_', dt);
excelName_RawEpoch = strcat(rawEpochName, '.xlsx');
backup_RawEpoch = strcat(rawEpochName, '.mat');

if ispc || ismac
    writetable(table_RawEpoch, excelName_RawEpoch, 'Sheet', sheetName_MeanRaw);
    save(backup_RawEpoch, 'table_RawEpoch', '-v7.3'); %, '-nocompression'     
elseif isunix
    save(backup_RawEpoch, 'table_RawEpoch', '-v7.3'); %, '-nocompression'     
else
    error('Platform not supported')
end

disp('Save or backup the raw epoch data successfully!');


%% %%%% 302 Lock the time windows %%%% %%
% 1. get the grand average for one left and one right channels.
% 2. then calculate the time windows for this grand average.

% Get the grand average of the epoch data
double_GrandAver = mean(cell2mat(cell_RawEpochDVs(2:end, :)));
table_GrandAver = array2table(double_GrandAver, 'VariableNames', cell_RawEpochDVs(1,:));

% save the data into excel or backup the data in cluster
if ~exist('dt', 'var')
    dt = datestr(now,'yymmddHH');
end
sheetName_LockWindow = 'LockWindow'; 
sheetName_GrandAver = 'GrandAver';
lockWindowName = strcat(studyPath, expCode, '_LockingWindow_', folderInfo, '_', dt);
backup_LockWindow = strcat(lockWindowName, '.mat');
excelName_LockWindow = strcat(lockWindowName, '.xlsx');
if ispc || ismac
    writetable(table_GrandAver, excelName_LockWindow, 'Sheet', sheetName_GrandAver);
end
save(backup_LockWindow, 'table_GrandAver', '-v7.3') %, '-nocompression'


%% calculate the time windows
intendWindowSize = 40;
% numPeakPoints = 11;
ratioPeak = 1/2;     % the ratio of peak value. (PEAK VALUE * Ratio) would be used to lock the time window
coluNum0 = find(strcmp(table_GrandAver.Properties.VariableNames,'P0'));

% get all the positive time point data for grand average (from time point 1 to end)
grandPositive = table_GrandAver{1, coluNum0+1:end};

%%%%%%%%%%%%%%%%%%%%  Method 1 to lock the time window %%%%%%%%%%%%%%%%%%%%
% find the time points where the values changes from positive to 
% negative or vice vera between 50 and 220

P1Start_Assumed = round(40/lag);  % assumed start time point for P1
P1End_Assumed = round(72/lag);  % assumed end time point for P1 and the start time point for N1
N1end_Assumed = round(220/lag);   % assumed end time point for N1

nZero = 0;

for iTime = P1Start_Assumed:N1end_Assumed
    % get the potential value for this and next time point
    tempColu1 = coluNum0 + iTime;
    tempColu2 = coluNum0 + iTime + 1;
    tempPotential1 = table_GrandAver{1,tempColu1};
    tempPotential2 = table_GrandAver{1,tempColu2};
    
    if tempPotential1 * tempPotential2 < 0
        nZero = nZero + 1;
        if tempPotential1 < 0 && tempPotential2 > 0  % from negative to positive 
            switch nZero
                case 1
                    tempP1_Start = iTime + 1;
                case 3
                    tempN1_End = iTime;
            end
        elseif tempPotential1 > 0 && tempPotential2 < 0 % from positive to negative
            switch nZero
                case 1
                    if iTime < round(110/lag)
                        nZero = 0;
                    else
                        tempP1_Start = P1Start_Assumed;
                        tempP1_End = iTime;
                        tempN1_Start = iTime + 1;
                        nZero = 2;
                    end
%                     error('The first value changes from positive to negative! Please check the grand average data manually.');
                case 2
                    if iTime > P1End_Assumed 
                        tempP1_End = iTime;
                        tempN1_Start = iTime + 1;
                    else
                        nZero = 0; % if the second zero point (from positive to negative)...
                        % is less than assumed end time point of P1(75) then restart finding zero.
                    end
                case 4
                    error('There are more than 3 changes between positive and negative. Please check manually');
            end 
        end 
    end
end

if ~exist('tempP1_End','var')
	tempN1_End = N1end_Assumed;
	tempN1_Start = tempP1_End + 1;
end

% if there are only two zeros between 0 and 220 ms, set the tempN1_End
% equals 220
if nZero == 2
    tempN1_End = N1end_Assumed;
end

% lock the time window for P1
[peakP1, timePeakP1] = max(grandPositive(tempP1_Start:tempP1_End));  % get the peak values for P1 
ratioValueP1 = peakP1 * ratioPeak;  % the potentials which were used to lock the time window for P1

for iTime_P1 = tempP1_Start:tempP1_End
    tempValue1_P1 = grandPositive(iTime_P1);
    tempValue2_P1 = grandPositive(iTime_P1+1);
    if tempValue1_P1 <= ratioValueP1 && tempValue2_P1 >= ratioValueP1
        timeWindowP1_Start = iTime_P1;
    elseif tempValue1_P1 >= ratioValueP1 && tempValue2_P1 <= ratioValueP1
        timeWindowP1_End = iTime_P1 + 1;   
    end 
end

% lock the time window for N1
[peakN1, timePeakN1] = min(grandPositive(tempN1_Start:tempN1_End)); % get the peak values for N1
ratioValueN1 = peakN1 * ratioPeak;  % the potentials which were used to lock the time window for N1

for iTime_N1 = tempN1_Start:tempN1_End
    tempValue1_N1 = grandPositive(iTime_N1);
    tempValue2_N1 = grandPositive(iTime_N1+1);
    if tempValue1_N1 <= ratioValueN1 && tempValue2_N1 >= ratioValueN1
        timeWindowN1_End = iTime_N1 + 1;
    elseif tempValue1_N1 >= ratioValueN1 && tempValue2_N1 <= ratioValueN1
        timeWindowN1_Start = iTime_N1;   
    end 
end


%%%%%%%%%%%%%%%%%%%%  Method 2 to lock the time window %%%%%%%%%%%%%%%%%%%%
% find the time points where the peak is (the peak is the max or min values
% among the nearest X data points)
% between 40 and 220
windowSize4Peak = round(intendWindowSize/lag);  % the size of the time window for get the averaged peak
% how many data points do you want to average for the peak (Note: it is the time point, not the durations (ms))
if ~mod(windowSize4Peak, 2), points4Peak = windowSize4Peak + 1; else points4Peak = windowSize4Peak; end  
pointSide4Peak = (points4Peak - 1)/2;
P1Start_Assumed = round(40/lag) + pointSide4Peak;  % assumed start time point for P1
P1End_Assumed = round(130/lag) - pointSide4Peak;  % assumed end time point for P1 
N1Start_Assumed = round(130/lag) + pointSide4Peak;  % assumed start point for N1
N1End_Assumed = round(220/lag) - pointSide4Peak;   % assumed end time point for N1

% find the maxmium and minmum values in the P1/N1 assumed windows
[~, timePeakP1_2] = max(grandPositive(1, P1Start_Assumed : P1End_Assumed));  
[~, timePeakN1_2] = min(grandPositive(1, N1Start_Assumed : N1End_Assumed));

timeWindowP1_Start_2 = timePeakP1_2 - pointSide4Peak + P1Start_Assumed - 1;
timeWindowP1_End_2 =  timePeakP1_2 + pointSide4Peak + P1Start_Assumed - 1;
timeWindowN1_Start_2 = timePeakN1_2 - pointSide4Peak + N1Start_Assumed - 1;
timeWindowN1_End_2 = timePeakN1_2 + pointSide4Peak + N1Start_Assumed - 1;


%%%%%%%%%%%%%%%%%%%%% save and write the data into excel %%%%%%%%%%%%%%%%%%
% create a table to contain the info about time windows and save in the
% excel
timePointPeak = {timePeakP1 + tempP1_Start - 1; timePeakN1 + tempN1_Start - 1; ...
    timePeakP1_2 + P1Start_Assumed - 1; timePeakN1_2 + N1Start_Assumed - 1};
windowStartFrame = {timeWindowP1_Start; timeWindowN1_Start; timeWindowP1_Start_2; timeWindowN1_Start_2};
windowEndFrame = {timeWindowP1_End; timeWindowN1_End; timeWindowP1_End_2; timeWindowN1_End_2};
windowStart = {timeWindowP1_Start*lag; timeWindowN1_Start*lag;...
    timeWindowP1_Start_2*lag; timeWindowN1_Start_2*lag};
windowEnd = {timeWindowP1_End*lag; timeWindowN1_End*lag;...
    timeWindowP1_End_2*lag; timeWindowN1_End_2*lag};
timeWindowRowNames = {'P1_Method1'; 'N1_Method1'; 'P1_Method2'; 'N1_Method2'};
table_LockWindow = table(timePointPeak, windowStartFrame, windowEndFrame,...
    windowStart, windowEnd, 'RowNames', timeWindowRowNames);

if ispc || ismac
    writetable(table_LockWindow, excelName_LockWindow, 'Sheet', sheetName_LockWindow);
%     writetable(table_TimeWindow, excelName_LockWindow, 'WriteRowNames', true,...
%         'Sheet', sheetName_GrandAver, 'Range', 'B5');
    save(backup_LockWindow, 'table_LockWindow', 'table_GrandAver', ...
         '-v7.3') %, '-nocompression'
elseif isunix
    save(backup_LockWindow, 'table_LockWindow', 'table_GrandAver', ...
         '-v7.3') %, '-nocompression'
else
    error('Platform not supported');
end

disp('Save the time windows into the excel file successfully!');


%% %%%% 303 Save the scalp distribution to check the location of peak %%%% %%
if ~exist('elecAll', 'var')
    elecAll = {STUDY.changrp.channels};  % all the channels in this study
end
numChanAll = length(elecAll);

table_TopoData = table; % create the table
table_GrandTopoCheck = table; % create the table for the data of scalp distribution

for iTimeWindow = 1:length(timeWindowRowNames)
    startThisWindow = table_LockWindow{iTimeWindow,'windowStartFrame'};
    endThisWindow = table_LockWindow{iTimeWindow, 'windowEndFrame'};
    
    startColuName = ['P', num2str(startThisWindow{1,1}*lag)];
    endColuName = ['P', num2str(endThisWindow{1,1}*lag)];
    
    % start and end of columns for the temp Raw data
    startColuNum = find(strcmp(table_RawEpoch.Properties.VariableNames, startColuName));
    endColuNum = find(strcmp(table_RawEpoch.Properties.VariableNames, endColuName));
    
    % save the data for ploting topo graph for each event (condition)
    for iEvent = 1:numEvents
        thisEvent = events{1,iEvent};
        
        tempTopoData = zeros(1,numChanAll);
        
        for iChan = 1:numChanAll
            thisChan = elecAll{1,iChan};
            
            logicTempRows = logical(strcmp(table_RawEpoch{:, 'Event'}, thisEvent) .* ...
                strcmp(table_RawEpoch{:,'Channel'}, thisChan));
            tempRawData = table_RawEpoch{logicTempRows, startColuNum:endColuNum};
            
            % tempTopoData for this time widnow and event
            tempTopoData(1,iChan) = mean(mean(tempRawData));
        end
        
        table_TopoData(iTimeWindow,iEvent) = {tempTopoData};
    end
    
    % save the data for plotting grand topo graph
    tempTopoData = zeros(1,numChanAll);  % create a zeros array
    for iChan = 1:numChanAll
        thisChan = elecAll{1,iChan};  % this channel
        
        % rows for the temp raw data
        logicGrandRows = strcmp(table_RawEpoch{:,'Channel'}, thisChan);
        
        % select the data of all participants and all events for this channel
        % and this time window
        tempRawData = table_RawEpoch{logicGrandRows, startColuNum:endColuNum};
        
        % calculate and save the mean of data for this time window and this
        % channel
        tempTopoData(1,iChan) = mean(mean(tempRawData));
    end
    
    table_GrandTopoCheck(1, iTimeWindow) = {tempTopoData};
    
end

% save the data into excel or backup the data in cluster
if ~exist('dt', 'var')
    dt = datestr(now,'yymmddHH');
end
sheetName_GrandTopo = 'GrandTopoCheck'; 
sheetName_TopoEvent = 'TopoEvent';
topoCheck = strcat(studyPath, expCode, '_TopoData_', folderInfo, '_', dt);
excelName_TopoCheck = strcat(topoCheck, '.xlsx');
backup_TopoCheck = strcat(topoCheck, '.mat');

% create a table to include the info about topo for checking
table_GrandTopoCheck.Properties.VariableNames = timeWindowRowNames;
table_TopoData.Properties.VariableNames = ...
    cellfun(@(x) x(~logical((x == '+') + (x == '_'))), events, 'UniformOutput', false);
 
table_TopoData.Properties.RowNames = timeWindowRowNames;

if ispc || ismac
    writetable(table_GrandTopoCheck, excelName_TopoCheck, 'Sheet', sheetName_GrandTopo);
    writetable(table_TopoData, excelName_TopoCheck, 'Sheet', sheetName_TopoEvent);
    save(backup_TopoCheck, 'table_GrandTopoCheck', 'table_TopoData', 'STUDY', 'ALLEEG', ...
         '-v7.3') %, '-nocompression'
elseif isunix
    save(backup_TopoCheck, 'table_GrandTopoCheck', 'table_TopoData', 'STUDY', 'ALLEEG', ...
         '-v7.3') %, '-nocompression'
else
    error('Platform not supported');
end

figureSize = [200, 300, 900, 750];

% save topo for each event (condition)
for iPotential = 1:size(table_TopoData,1)
    for iEvent = 1:numEvents
        
        % Name of the figure
        namePart1 = table_TopoData.Properties.RowNames{iPotential,1};
        namePart2 = table_TopoData.Properties.VariableNames{1,iEvent};
        figureName = [namePart1, '-', namePart2];
        fileName = [expCode, '-',figureName];
        
        % get the data for this potential and this event
        topoData = table_TopoData{iPotential,iEvent};
        
        topoFig = figure('Name',figureName);
        topoplot(topoData, ALLEEG(1).chanlocs,...  % ALLEEG(1).chanlocs, chanLocations
            ...   % set the maximum and minimum value for all the value 'maplimits', [-4 5],
            'electrodes', 'labels'); %             'channels', 'events'... % show the name of the events on their locations

        colorbar; % show the color bar
        title(['\fontsize{20}', figureName]);
        % topoFig.Color = 'none';  % set the background color as transparent.
        topoFig.Position = figureSize; % resize the window for this figure
%         set(gcf, 'Position', [200, 200, 900, 750]) 
        
        % print the figure as pdf file
        figurePDFName = [studyPath, fileName];
        print(figurePDFName, '-dpdf');
    end
end


% save the grand topo map as pdf
for iPotential = 1:size(table_GrandTopoCheck,2)
    
    % Name of the figure
    namePotential = table_GrandTopoCheck.Properties.VariableNames{1,iPotential};
    topoFigureName = [namePotential, '-GrandTopo-cluster']; 
    topoFileName = [expCode, '-',topoFigureName];
    
    % get the data for this potential and this event
    tempGrandTopoData = table_GrandTopoCheck{1, iPotential};
    
    topoFig = figure('Name',topoFigureName);
    topoplot(tempGrandTopoData, ALLEEG(1).chanlocs,...  % ALLEEG(1).chanlocs, chanLocations
        ...   % set the maximum and minimum value for all the value    'maplimits', [-4 5],
        'electrodes', 'labels'); %             'electrodes', 'labels'... % show the name of the events on their locations
    
    colorbar; % show the color bar
    title(['\fontsize{20}', topoFigureName]);
    % topoFig.Color = 'none';  % set the background color as transparent.
    topoFig.Position = figureSize; % resize the window for this figure
    %         set(gcf, 'Position', [200, 200, 900, 750])
    
    % print the figure as pdf file
    figurePDFName = [studyPath, topoFileName];
    print(figurePDFName, '-dpdf');
    
end

disp('Save the data for topograph check successfully!');


%% All done successfully!
disp('Done!!!');

if ispc || ismac
    beep;
    pause(0.3);
    beep;
    pause(0.3);
    beep;
end
