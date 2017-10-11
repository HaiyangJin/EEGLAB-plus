%% 200 Create a new study  
% Author: Haiyang Jin (haiyang.jin@auckland.ac.nz)
% create a study for all the participants in one experiment

% This script only use one *.set file for each participant to create the
% study, the different conditions are assigned by STUDY.design (based on
% the suggestion from Makoto's PreProcessing Pipeline)

% this script saves the data into table (not a cell)


%% % Prepaparation for different platform
manual_auto = {'manual', 'auto'};
baselineStart = -100;
if isunix
    % get the experiment number
    ID = getenv('SLURM_ARRAY_TASK_ID');
    display(ID);
    % to make sure the length of ID is two
    if length(ID) ~= 3
        error('There should be three digitals for the array!!!')
    else
        experimentNum = ID(1);    % the number of experiment
        isManualRejected = manual_auto{2-str2double(ID(2))}; % if the ICs were rejected manually
        isBasedACC = ID(3);  % if this process is only for the correct trials
    end
  
    % get the Job ID from Cluster
    jobID = getenv('SLURM_ARRAY_JOB_ID');
    
    % get the experiment folder in Cluster
    eeglabPath = '/home/hjin317/eeglab/';  % the path for eeglab
    addpath(eeglabPath);  % add the path for eeglab
    projectPath = '/gpfs1m/projects/uoa00424/'; % the path for this project
    expFolder = ['20' experimentNum];  % the folder for this experiment
    expFolderPath = [projectPath,expFolder,filesep];  % the path for this experiment
    studyPath = [expFolderPath,'04_PreProcessed_',isManualRejected, '_', isBasedACC,filesep]; % get the study path
    fopen([studyPath jobID '_' ID '.txt'],'w+'); % create a txt file whose filename is the job ID
    
elseif ispc
    % input the number of this experiment
    experimentNum = input('Please input the experiment Number (1, 2, 3, or 4).', 's');
    expFolder = ['20' experimentNum];
    isManual = input('Are the ICs rejected manually? (0,1)');
    isManualRejected = manual_auto{2-isManual};
    isBasedACC = input('Are the epochs basded on ACC? (1(yes), 2(no))?', 's');
    
    % open GUI to select the folder where the PreProcessed data are saved
    studyPath = [uigetdir('C:\Users\hjin317\Google Drive\2_EEG_DataAnalysis',...
        'Please choose the folder where the clean (PreProcessed) data are saved.'), filesep];
    
elseif ismac
    % this script doesn't work on Mac since no data could be accessed
    error('There are no data saved on Mac.');
else
    error('Platform not supported!');
end


%% Preparation 
% the numbers of all the participant that you want to create the study for
if strcmp(experimentNum, '2')
    theParticipants = 0:19;
elseif strcmp(experimentNum, '1')
    theParticipants = 1:21;
elseif strcmp(experimentNum, '3')
    if strcmp(isBasedACC, '1')
        theParticipants = [1:8 10:16 18:20];
    else
        theParticipants = 1:20;
    end
elseif strcmp(experimentNum, '4')
    theParticipants = 1:20;
end
numParticipant = length(theParticipants); % the number of participants


%% create the array for the experiment desgin and then create the study
% create the experiment design
clear tempStudyDesign
clear participantList
tempStudyDesign = cell(1, numParticipant);
participantList = cell(1, numParticipant);

preProcessedName = ['_04_PreProcessed_', isManualRejected, '_', isBasedACC];

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
studyName = ['EEG_FH_', expFolder, '_', num2str(numParticipant), '_', ...
    isManualRejected, '_', isBasedACC, '_' dt];
[STUDY, ALLEEG] = std_editset(STUDY, ALLEEG, 'name', studyName, 'updatedat','off',...
    'commands', tempStudyDesign);

% get all the lables for this study
labels = unique({STUDY.datasetinfo(1).trialinfo.type});
if isBasedACC  % if the labels are only for correct ones
    % find the lables end with '1'
    endLetterLabel = cellfun(@(x) x(end), labels, 'UniformOutput', false);
    logicEndLabel = strcmp(endLetterLabel,'1');
    
    % find the 17ms labels end with '0'
    letter3Label = cellfun(@(x) x(3), labels, 'UniformOutput', false);
    logic3Label = strcmp(letter3Label,'7');
    letter0Label = cellfun(@(x) x(end), labels, 'UniformOutput', false);
    logic0Label = strcmp(letter0Label,'0');
    logic30Label = logical(logic3Label .* logic0Label);
    
    % find the labels start with S
    letterSLabel = cellfun(@(x) x(1), labels, 'UniformOutput', false);
    logicSLabel = strcmp(letterSLabel,'S');
    
    logicLabel = logical(logicEndLabel + logic30Label + logicSLabel);
    labels = labels(logicLabel);
end

% make the design for this study
designName = [expFolder, '_', num2str(numParticipant), '_', isManualRejected, '_', isBasedACC];
STUDY = std_makedesign(STUDY, ALLEEG, 1, 'variable1','type','variable2','',...
    'name', designName,'pairing1','on','pairing2','on','delfiles','off',...
    'defaultdesign','off','values1',labels, 'subjselect', participantList);

% precompute baseline
[STUDY , ALLEEG] = std_precomp(STUDY, ALLEEG, {},'interp','on','recompute','on',...
    'erp','on','erpparams',{'rmbase' [baselineStart 0] });

% save this study
EEG = ALLEEG;
STUDY = pop_savestudy( STUDY, EEG, 'filename',studyName,'filepath',studyPath);
disp(['Save the study of ', studyName, ' successfully!']);


%% %%%% 301 Output the mean of raw data into excel %%%% %%
% Output the mean for all trials for each condition, every participant, and
% every electrodes.

% Create the array for Independent Variable (IV) and another array for Dependent
% Variable (DV). IVs includes participant names, electrodes, labels and so
% on. DVs includes all the EEG data.

% Preparation
elecAll = {STUDY.changrp.channels};  % all the electrodes in this exp
numElecAll = length(elecAll); % number of electrodes
labels = STUDY.design.variable(1).value;  % get the label names
numLabels = length(labels); % number of labels
participantNames = cellstr(STUDY.subject); % cell array contains all the participant names

% info about epoch start and end point
epochStart = EEG(1).xmin*1000; % -200;
epochEnd = EEG(1).xmax*1000; % 1499;
epochLength = EEG.pnts; % epochEnd-epochStart+1;

% info about the CELL for the mean raw data
meanRaw_IVs = {'ParticipantNum', 'electrode', 'label'};
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

numRow_MeanRaw = numElecAll*numLabels*numParticipant+1;  % number of rows

% the column number of the independent variables
participantColuNum = find(strcmp(meanRaw_IVs, 'ParticipantNum'));
elecColuNum = find(strcmp(meanRaw_IVs, 'electrode'));
labelColuNum = find(strcmp(meanRaw_IVs, 'label'));


%% Combine all the trials across all conditions
% create the cell for IVs and DVs of mean raw data
clear cell_MeanRawIVs
cell_MeanRawIVs = cell(numRow_MeanRaw,numColu_MeanRawIVs);
cell_MeanRawIVs(1,:) = meanRaw_IVs;

clear cell_MeanRawDVs;
cell_MeanRawDVs = cell(numRow_MeanRaw,numColu_MeanRawDVs);
cell_MeanRawDVs(1,:) = meanRaw_DVs;

numRowsEachElec = numLabels*numParticipant;

for iElec = 1:numElecAll
    % add the electrode names into the IVs
    tempElec = elecAll(iElec); 
    elecStartRow = (iElec-1)*numRowsEachElec+1+1;
    elecEndRow = iElec*numRowsEachElec+1;
    cell_MeanRawIVs(elecStartRow:elecEndRow, elecColuNum) = tempElec;
    
    % get the erpdata from the study
    [STUDY, erpdata, erptimes] = std_erpplot(STUDY,ALLEEG,'channels',tempElec,'noplot', 'on');
    
    for iLabel = 1:numLabels
        % add the label names into the IVs
        thisLabel = labels(iLabel);
        labelStartRow = (iLabel-1)*numParticipant + elecStartRow;
        labelEndRow = iLabel*numParticipant - 1 + elecStartRow;
        cell_MeanRawIVs(labelStartRow:labelEndRow,labelColuNum) = thisLabel;
        
        % add participant names into the IVs
        cell_MeanRawIVs(labelStartRow:labelEndRow,participantColuNum) = participantNames;
        
        % add data to the DVs
        erpDataSet = erpdata{iLabel,1}';
        cell_MeanRawDVs(labelStartRow:labelEndRow, :) = num2cell(erpDataSet);
        
    end
    
end
clear tempElec
clear thisLabel

% combine the two cells (IVs and DVs) together and convert to table
cell_MeanRaw = horzcat(cell_MeanRawIVs, cell_MeanRawDVs);
table_MeanRaw = cell2table(cell_MeanRaw(2:end,:), 'VariableNames', cell_MeanRaw(1,:));

% save the mean of the raw data into the excel amd the backup file
if ~exist('dt', 'var')
    dt = datestr(now,'yymmddHH');
end

sheetName_MeanRaw = [expFolder,'_MeanRaw']; 
rawMeanName = strcat(studyPath, sheetName_MeanRaw, '_', isManualRejected, '_', isBasedACC, '_', dt);
excelName_RawMean = strcat(rawMeanName, '.xlsx');
backup_RawMean = strcat(rawMeanName, '.mat');

if ispc || ismac
    writetable(table_MeanRaw, excelName_RawMean, 'Sheet', sheetName_MeanRaw);
    save(backup_RawMean, 'table_MeanRaw', 'STUDY', 'ALLEEG', 'expFolder', '-v7.3'); %, '-nocompression'     
elseif isunix
    save(backup_RawMean, 'table_MeanRaw', 'STUDY', 'ALLEEG', 'expFolder', '-v7.3'); %, '-nocompression'     
else
    error('Platform not supported')
end

disp('Save or backup the mean data successfully!');


%% %%%% 302 Lock the time windows %%%% %%
% 1. get the grand average for one left and one right electrodes.
% 2. then calculate the time windows for this grand average.

% Preparation for locking time windows
leftElec = 'E58';    % P7, center of the assumed cluster
rightElec = 'E96';   % P8, center of the assumed cluster

% if this part script runs on windows or Mac, please specify the *.mat
% containing the raw mean data.
if ~exist('table_MeanRaw', 'var')
    if ispc || ismac
        [fileNames, studyPath] = uigetfile('*.mat', 'Please choose the ''.mat'' file contains the mean values.');
        load([studyPath,fileNames]); % load the raw data
    else
        error('There are no raw EEG data available!');
    end
end

% save the data for two electordes to get the grand average data for locking time windows
rowLogic = logical(strcmp(table_MeanRaw{:, 'electrode'}, leftElec)... % get all the rows for E58 
                 + strcmp(table_MeanRaw{:, 'electrode'}, rightElec)); % get all the rows for E96
table_LockWindow = table_MeanRaw(rowLogic, :); % table only includes the rows for E58 and E96
coluNumGrandAver = size(table_LockWindow,2); % column number for the table of grand average
rowNumGrandAver = 1; % row number for the table of grand average
table_GrandAver = table; % create the table for grand average

% add the variable names again and the grand average row
dataStartColuName = {['N', num2str(abs(ALLEEG(1).xmin*1000))]};
dataStartColuNum = find(strcmp(dataStartColuName, ...
    table_LockWindow.Properties.VariableNames)); % get the column number for the start of the minmum time point
rowGrandValue = num2cell(mean(table_LockWindow{:,dataStartColuNum:end},1));
rowGrand = horzcat({'GrandAverage', [leftElec,rightElec], 'All'},rowGrandValue);
table_GrandAver(rowNumGrandAver,1:coluNumGrandAver) = rowGrand;
table_GrandAver.Properties.VariableNames = table_LockWindow.Properties.VariableNames;
table_LockWindow = vertcat(table_LockWindow, rowGrand); % save the mean data to lock window table


%% calculate the time windows
% find the time points where the values changes from positive to 
% negative or vice vera between 50 and 220
P1Start_Assumed = 0;  % assumed start time point for P1
P1End_Assumed = round(72/lag);  % assumed end time point for P1 and the start time point for N1
N1end_Assumed = round(220/lag);   % assumed end time point for N1
ratioPeak = 1/2;     % the ratio of peak value. (PEAK VALUE * Ratio) would be used to lock the time window

coluNum0 = find(strcmp(table_GrandAver.Properties.VariableNames,'P0'));
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
                    nZero = 0;  
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

% get all the positive time point data for grand average (from time point 1 to end)
grandPositive = table_GrandAver{1, coluNum0+1:end};

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

% save the data into excel or backup the data in cluster
if ~exist('dt', 'var')
    dt = datestr(now,'yymmddHH');
end
sheetName_LockWindow = 'LockWindow'; 
sheetName_GrandAver = 'GrandAver';
lockWindowName = strcat(studyPath, expFolder, '_LockingWindow_', isManualRejected, '_', isBasedACC, '_', dt);
excelName_LockWindow = strcat(lockWindowName, '.xlsx');
backup_LockWindow = strcat(lockWindowName, '.mat');

% create a table to contain the info about time windows and save in the
% excel
timePointPeak = {timePeakP1 + tempP1_Start - 1; timePeakN1 + tempN1_Start - 1};
windowStartFrame = {timeWindowP1_Start; timeWindowN1_Start};
windowEndFrame = {timeWindowP1_End; timeWindowN1_End};
windowStart = {timeWindowP1_Start*lag; timeWindowN1_Start*lag};
windowEnd = {timeWindowP1_End*lag; timeWindowN1_End*lag};
timeWindowRowNames = {'P1'; 'N1'};
table_TimeWindow = table(timePointPeak, windowStartFrame, windowEndFrame,...
    windowStart, windowEnd, 'RowNames', timeWindowRowNames);

if ispc || ismac
    writetable(table_LockWindow, excelName_LockWindow, 'Sheet', sheetName_LockWindow);
    writetable(table_GrandAver, excelName_LockWindow, 'Sheet', sheetName_GrandAver);
    writetable(table_TimeWindow, excelName_LockWindow, 'WriteRowNames', true,...
        'Sheet', sheetName_GrandAver, 'Range', 'B5');
    save(backup_LockWindow, 'table_LockWindow', 'table_GrandAver', 'table_TimeWindow',...
        'STUDY', 'ALLEEG', 'expFolder', '-v7.3') %, '-nocompression'
elseif isunix
    save(backup_LockWindow, 'table_LockWindow', 'table_GrandAver', 'table_TimeWindow',...
        'STUDY', 'ALLEEG', 'expFolder', '-v7.3') %, '-nocompression'
else
    error('Platform not supported');
end

disp('Save the time windows into the excel file successfully!');


%% %%%% 303 Save the scalp distribution to check the location of peak %%%% %%
if ~exist('elecAll', 'var')
    elecAll = {STUDY.changrp.channels};  % all the electrodes in this study
end
numElecAll = length(elecAll);

table_GrandTopoCheck = table; % create the table for the data of scalp distribution

for iTimeWindow = 1:length(timeWindowRowNames)
    startThisWindow = table_TimeWindow{iTimeWindow,'windowStartFrame'};
    endThisWindow = table_TimeWindow{iTimeWindow, 'windowEndFrame'};
    
    startColuName = ['P', num2str(startThisWindow{1,1}*lag)];
    endColuName = ['P', num2str(endThisWindow{1,1}*lag)];
    
    % start and end of columns for the temp Raw data
    startColuNum = find(strcmp(table_MeanRaw.Properties.VariableNames, startColuName));
    endColuNum = find(strcmp(table_MeanRaw.Properties.VariableNames, endColuName));
    
    tempTopoData = zeros(1,numElecAll);  % create a zeros array

    for iElec = 1:numElecAll
        thisElec = elecAll{1,iElec};  % this electrode
        
        % rows for the temp raw data
        logicTempRows = strcmp(table_MeanRaw{:,'electrode'}, thisElec);
        
        % select the data of all participants and all labels for this electrode
        % and this time window
        tempRawData = table_MeanRaw{logicTempRows, startColuNum:endColuNum};
        
        % calculate and save the mean of data for this time window and this
        % electrode
        tempTopoData(1,iElec) = mean(mean(tempRawData));
    end
    
    table_GrandTopoCheck(1, iTimeWindow) = {tempTopoData};
    
end

% save the data into excel or backup the data in cluster
if ~exist('dt', 'var')
    dt = datestr(now,'yymmddHH');
end
sheetName_Topo = 'TopoCheck'; 
topoCheck = strcat(studyPath, expFolder, '_TopoData_', isManualRejected, '_', isBasedACC, '_', dt);
excelName_TopoCheck = strcat(topoCheck, '.xlsx');
backup_TopoCheck = strcat(topoCheck, '.mat');

% create a table to contain the info about topo for checking
table_GrandTopoCheck.Properties.VariableNames = timeWindowRowNames;

if ispc || ismac
    writetable(table_GrandTopoCheck, excelName_TopoCheck, 'Sheet', sheetName_Topo);
    save(backup_TopoCheck, 'table_GrandTopoCheck', 'STUDY', 'ALLEEG', 'expFolder',...
        '-v7.3') %, '-nocompression'
elseif isunix
    save(backup_TopoCheck, 'table_GrandTopoCheck', 'STUDY', 'ALLEEG', 'expFolder',...
        '-v7.3') %, '-nocompression'
else
    error('Platform not supported');
end

% save the grand topo map as pdf

for iPotential = 1:size(table_GrandTopoCheck,2)
    
    % Name of the figure
    namePotential = table_GrandTopoCheck.Properties.VariableNames{1,iPotential};
    topoFigureName = [namePotential, '-GrandTopo']; 
    topoFileName = [expFolder, '-',topoFigureName];
    
    % get the data for this potential and this label
    tempGrandTopoData = table_GrandTopoCheck{1, iPotential};
    
    topoFig = figure('Name',topoFigureName);
    topoplot(tempGrandTopoData, ALLEEG(1).chanlocs,...  % ALLEEG(1).chanlocs, chanLocations
        ...   % set the maximum and minimum value for all the value    'maplimits', [-4 5],
        'electrodes', 'labels'); %             'electrodes', 'labels'... % show the name of the labels on their locations
    
    colorbar; % show the color bar
    title(['\fontsize{20}', topoFigureName]);
    % topoFig.Color = 'none';  % set the background color as transparent.
    topoFig.Position = [200, 300, 900, 750]; % resize the window for this figure
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
