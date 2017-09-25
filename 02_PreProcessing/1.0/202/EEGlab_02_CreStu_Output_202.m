%% 300 Create a new study  (Author: Haiyang Jin)
% create a study for all the participants in one experiment
% %% this script saves the data into table (not a cell)


%% input info
experimentNum = '2';    % the number of experiment
theParticipant = [0:19]; % input all participant names 


%% Preparation
% info based on input   
fileFolder = ['20' experimentNum];  % pilot,201,202
experiment = ['P' experimentNum];   % Pilot,P0; E1,P1; E2,P2.

% Preaparation for different platform
if isunix
    addpath('/home/hjin317/eeglab/');
    homePath = '/gpfs1m/projects/uoa00424/';
    filePath = [homePath,fileFolder,filesep];
elseif ispc
    filePath = 'C:\Users\hjin317\Google Drive\2_EEG_DataAnalysis\202_Scramble&LumiMatch\';
elseif ismac
    error('There are no data saved on Mac.');
end

% labels
if strcmp(experimentNum, '1')
    labels = {'F017' 'F050'  'F100'  'F200'  'H017'  'H050'  'H100'  'H200'};
else
    labels = {'NF7+'  'NF5+'  'NF1+'  'NF2+'  'NH7+'  'NH5+'  'NH1+'  'NH2+' ...
              'SF7+'  'SF5+'  'SF1+'  'SF2+'  'SH7+'  'SH5+'  'SH1+'  'SH2+'};
end

dt = datestr(now,'yymmddHH');
numParticipant = length(theParticipant);
studyName = ['EEG_FH_',fileFolder,'_',num2str(numParticipant),'_',dt]; 

loadPath = [filePath,'04_DivEpo',filesep]; %input load path

% ID = getenv('SLURM_ARRAY_TASK_ID');
% participantName = num2str(theParticipant,[experiment,'%02d'])';  %P101


%% create the array for the experiment desgin and then create the study
% create the experiment design
numLabel = length(labels);
cells = numParticipant*numLabel;
clear epochData
epochData = cell(1,cells);

for iLabel = 1:numLabel
    
    for iParticipant = 1:numParticipant
        epochi = iParticipant+(iLabel-1)*numParticipant;
        index = numLabel*iParticipant+(iLabel-1);
        participantName = num2str(theParticipant(iParticipant),[experiment,'%02d']);
%         subject = num2str(theParticipant(iParticipant),'S%02d');
        label = labels{iLabel};
        epochLoadPath = [loadPath, participantName,'_04_', label, '.set'];

        epochData{1, epochi}= {'index' index 'load' epochLoadPath 'subject' participantName 'condition' label};
        
    end
end

% create the study
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
[STUDY ALLEEG] = std_editset( STUDY, ALLEEG, 'name',studyName,'updatedat','off','commands', epochData);
[STUDY ALLEEG] = std_precomp(STUDY, ALLEEG, 'channels', 'interp','on', 'recompute','on','erp','on');
tmpchanlocs = ALLEEG(1).chanlocs; STUDY = std_erpplot(STUDY, ALLEEG, 'channels', { tmpchanlocs.labels }, 'plotconditions', 'together');
[STUDY EEG] = pop_savestudy( STUDY, EEG, 'filename',studyName,'filepath',loadPath);
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];


%% 301 load data
% load data for precompute baseline
fileName = [studyName, '.study']
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
[STUDY ALLEEG] = pop_loadstudy('filename', fileName, 'filepath', loadPath);
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];

% 302 precompute baseline
[STUDY ALLEEG] = std_precomp(STUDY, ALLEEG, {},'interp','on','recompute','on','erp','on','erpparams',{'rmbase' [-200 0] });
EEG = eeg_checkset( EEG );
[STUDY EEG] = pop_savestudy( STUDY, EEG, 'savemode','resave');
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];

disp(['Save the study for ', num2str(numParticipant), ' participant successfully!']);

%% 303 this file outputs all ERP data for different electrode, condition and 
% every participant in one sheet in Excel. And output the peak value
% information.

% get the mean for all trials for each condition, every participant, and
% every electrodes

% Please change the IVs for labels for different experiment

%% input info
% for mean of raw data
studyName4Cluster = ' ';
if ~exist('experimentNum')
    experimentNum = '1';   % the number of experiment
end
% theParticipant = [0:19]; % input all participant names  :13 15 

% for peak data 
windowsInfo = [70,120;120,200]; % each row represents one time window, and the first and second columns represent the start and end time point of that window
windowNames = {'P1', 'N170'}; % names of the time windows
windowPN = [1, -1]; % positive or negative wave for the potential

numToCheck = 5; % how many time points do you want to check for each side. 
peak2Cal = 2; % how many time points do you want to calculate for peak value for each side.

% %% info based on the input
expFolder = ['20' experimentNum];  % pilot,201,202  the name of the folder that save the data for one experiment
experiment = ['P' experimentNum];   % Pilot,P0; E1,P1; E2,P2.
numWindows = size(windowsInfo,1);

%% open eeglab and load the study
% clear studyName
% clear loadPath
if ispc
    [studyName, loadPath] = uigetfile('*.study', 'Please choose the study you want to load.');
    saveDir = 'C:\Users\hjin317\Dropbox\My research\2_N170&Time\';
elseif ismac
    [studyName, loadPath] = uigetfile('*.study', 'Please choose the study you want to load.');
    saveDir = '/Users/Haiyang/Dropbox/My research/2_N170&Time/';
elseif isunix
    % cluster preparation
    if ~exist('studyName')
        studyName = studyName4Cluster;
    else
        studyName = [studyName, '.study'];
    end
    addpath('/home/hjin317/eeglab/');
    homePath = '/gpfs1m/projects/uoa00424/';
    filePath = [homePath,expFolder,'/'];
    loadPath = [filePath,'04_DivEpo/']; %input load path
    saveDir = homePath;
else
    disp('Platform not supported')
end

% load the study
eeglab;
[STUDY, ALLEEG] = pop_loadstudy('filename', studyName, 'filepath', loadPath);
CURRENTSTUDY = 1; EEG = ALLEEG; CURRENTSET = [1:length(EEG)];


%% %%%% Output the mean of raw data into excel %%%% %%
% Preparation 
% labels
if strcmp(experimentNum, '1') || strcmp(experimentNum, '4')
    labels = {'F017' 'F050'  'F100'  'F200'  'H017'  'H050'  'H100'  'H200'};
elseif strcmp(experimentNum, '2') || strcmp(experimentNum, '3')
    labels = {'NF7+'  'NF5+'  'NF1+'  'NF2+'  'NH7+'  'NH5+'  'NH1+'  'NH2+' ...
              'SF7+'  'SF5+'  'SF1+'  'SF2+'  'SH7+'  'SH5+'  'SH1+'  'SH2+'};
else
    error('No labels assigned for this study.');
end

% the electrodes
elecAll = {STUDY.changrp.channels};  % all the electrodes in this exp
% elecAll = {'E51', 'E52', 'E58', 'E59', 'E60', 'E63', 'E64', 'E65', 'E66', 'E67', 'E68', 'E69', 'E70', 'E71',...
%            'E76', 'E77', 'E83', 'E84', 'E85', 'E89', 'E90', 'E91', 'E92', 'E94', 'E95', 'E96', 'E97', 'E99',...
%            'E62', 'E73', 'E75'};
% elecAll = {'E90'};

numLabels = length(labels);
numElecAll = length(elecAll);
numParticipant = length(STUDY.subject); 
participantNames = cellstr(STUDY.subject); % cellstr(num2str(theParticipant',['P', experimentNum, '%02d']))

% info about epoch start and end point
epochStart = EEG(1).xmin*1000; % -200;
epochEnd = EEG(1).xmax*1000; % 1499;
epochLength = EEG(1).pnts; % epochEnd-epochStart+1;

% info about the CELL for the mean raw data
meanRaw_IVs = {'ParticipantNum', 'electrode', 'label'};
% create the Variable Names for meanRaw_DVs
tempEpoch = epochStart:epochEnd;
meanRaw_DVs = cell(1,epochLength);
for iNum = 1:epochLength
    tempNum = tempEpoch(iNum);
    if tempNum < 0
        tempNeg = num2str(tempNum);
        meanRaw_DVs(1,iNum) =  {['N', tempNeg(2:end)]};
    else
        meanRaw_DVs(1,iNum) = {['P', num2str(tempNum)]};
    end
end
% rowVariableNames = [meanRaw_IVs,meanRaw_DVs]; % 'ExpNum', 

numColu_MeanRawIVs = length(meanRaw_IVs);  % number of IVs
numColu_MeanRawDVs = length(meanRaw_DVs);  % number of DVs

numRow_MeanRaw = numElecAll*numLabels*numParticipant+1;   % number of rows

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

for iElec = 1:numElecAll
    % add the electrode names into the IVs
    tempElec = elecAll(iElec);
    numRow4ThisElec = numLabels*numParticipant;
    elecStartRow = (iElec-1)*numRow4ThisElec+1;
    cell_MeanRawIVs(elecStartRow+1:iElec*numRow4ThisElec+1, elecColuNum) = tempElec;
    
    % get the erpdata from the study
    [STUDY, erpdata, erptimes] = std_erpplot(STUDY,ALLEEG,'channels',tempElec);
    close(2);
    
    for iLabel = 1:numLabels
        % add the label names into the IVs
        thisLabel = labels(iLabel);
        labelStartRow = (iLabel-1)*numParticipant;
        labelRows = elecStartRow+labelStartRow+(1:numParticipant);
        cell_MeanRawIVs(labelRows,labelColuNum) = thisLabel;
        
        % add participant names into the IVs
        cell_MeanRawIVs(labelRows,participantColuNum) = participantNames;   
        
        % add data to the DVs
        erpDataSet = erpdata{iLabel,1}';
        cell_MeanRawDVs(labelRows, :) = num2cell(erpDataSet);
           
    end
    
end

clear tempElec
clear thisLabel

% combine the two cells (IVs and DVs) together and convert to table
cell_MeanRaw = [cell_MeanRawIVs, cell_MeanRawDVs];
table_MeanRaw = cell2table(cell_MeanRaw(2:end,:), 'VariableNames', cell_MeanRaw(1,:));

% save the mean of the raw data into the excel amd the backup file
thisDateVector = now;
theDate8 = (datestr(thisDateVector,'yyyymmdd'));

sheetName_MeanRaw = [expFolder,'_MeanRaw']; 
fileName = strcat(saveDir, sheetName_MeanRaw, '_', theDate8, '.xlsx');
fileNameBackup = strcat(saveDir, sheetName_MeanRaw, '_', theDate8, '.mat');

% save the chanel location 
chanLocations = ALLEEG(1).chanlocs;

if ispc || ismac
    writetable(table_MeanRaw, fileName, 'Sheet', sheetName_MeanRaw);
    save(fileNameBackup, 'table_MeanRaw', 'expFolder', 'chanLocations', '-v7.3') %, '-nocompression'     
elseif isunix
    save(fileNameBackup, 'table_MeanRaw', 'expFolder', 'chanLocations', '-v7.3') %, '-nocompression'     
else
    disp('Platform not supported')
end

% Mean Raw data
% rawSheetName = '201_meanEEGData';  
% xlswrite(fileName,meanRawData,rawSheetName);

disp('Save the mean data into the excel successfully!');


%% %%%% 304 Output the peak value %%%% %%
% Preparation
% [fileName, saveDir] = uigetfile('*.mat', 'Select the .mat file for raw mean data');

% info about CELL for the peak values
peakValue_IVs = [meanRaw_IVs, {'NS', 'FH', 'Duration'}];
% peakValue_DVs = {'Potential','Latency'};

numColu_PeakValueIVs = length(peakValue_IVs);
numColu_PeakValueDVs = size(windowsInfo,1)*numWindows;

numRow_PeakValue = numRow_MeanRaw;

NSColuNum = find(strcmp(peakValue_IVs, 'NS'));
FHColuNum = find(strcmp(peakValue_IVs, 'FH'));
DurationColuNum = find(strcmp(peakValue_IVs, 'Duration'));


%% find and output the peak values
% create the cell for IVs and DVs of peak values
clear cell_PeakValueIVs
cell_PeakValueIVs = cell(numRow_PeakValue, numColu_PeakValueIVs);
cell_PeakValueIVs(1,:) = peakValue_IVs;

clear cell_PeakValueDVs
cell_PeakValueDVs = cell(numRow_PeakValue, numColu_PeakValueDVs);
tempRowNames = {'Potential','Latency'};
for iW = 1:numWindows
    cell_PeakValueDVs(1,(2*iW-1:2*iW)) = arrayfun(@(x) strcat(windowNames{1,iW},'_',x), tempRowNames);
end

% copy the first three columns (IVs) from cell_MeanRaw
cell_PeakValueIVs(2:end,1:numColu_MeanRawIVs) = cell_MeanRawIVs(2:end,:);

% get the row data (only the DVs)
data2Check = cell_MeanRawDVs;

for iRow = 2:numRow_PeakValue
    % the row data for this round
    tempRowData = data2Check(iRow,:);
        
    % save the (three) IVs about lables into the peak value data cell
    thisLabel = cell_PeakValueIVs{iRow, labelColuNum};
    if strcmp(experimentNum, '1') || strcmp(experimentNum, '4')
        cell_PeakValueIVs(iRow, NSColuNum) = {'N'};
        cell_PeakValueIVs(iRow, FHColuNum) = {thisLabel(1)};
        cell_PeakValueIVs(iRow, DurationColuNum) = {thisLabel(2:4)};
    elseif strcmp(experimentNum, '2') || strcmp(experimentNum, '3')
        cell_PeakValueIVs(iRow, NSColuNum) = {thisLabel(1)};
        cell_PeakValueIVs(iRow, FHColuNum) = {thisLabel(2)};
        cell_PeakValueIVs(iRow, DurationColuNum) = {thisLabel(3)};
    end
    
    % find and save the peak values
    for iWindow = 1:numWindows
        
        thisWindowStart = windowsInfo(iWindow,1);
        thisWindowEnd = windowsInfo(iWindow,2);
        
        windowStartPoint = abs(epochStart) + thisWindowStart;
        windowEndPoint = abs(epochStart) + thisWindowEnd;
        
        % the data to be checked for peak values
        dataInThisWindow = cell2mat(tempRowData(1, windowStartPoint:windowEndPoint));
        
        if windowPN(iWindow) > 0
            [tempPeakValue, tempColu] = max(dataInThisWindow);
            tempMeanPeak = mean(cell2mat(data2Check(iRow,tempColu + windowStartPoint + [-peak2Cal:peak2Cal])));
            tempLatency = data2Check{1,tempColu + windowStartPoint + [-peak2Cal:peak2Cal]};
        elseif windowPN(iWindow) < 0
            [tempPeakValue, tempColu] = min(dataInThisWindow);
            tempMeanPeak = mean(cell2mat(data2Check(iRow,tempColu + windowStartPoint + [-peak2Cal:peak2Cal])));
            tempLatency = data2Check{1,tempColu + windowStartPoint + [-peak2Cal:peak2Cal]};
        else 
            tempMeanPeak = [];
            tempLatency = [];
        end
        
        % save the value data and latency into the data cell
        cell_PeakValueDVs(iRow, 2*iWindow-1) = {tempMeanPeak};
        cell_PeakValueDVs(iRow, 2*iWindow) = {tempLatency};
     
    end
end

clear thisLabel

% coombine the two cells (IVs and DVs) together and convert to table
cell_PeakValue = [cell_PeakValueIVs, cell_PeakValueDVs];
table_PeakValues = cell2table(cell_PeakValue(2:end,:), 'VariableNames', cell_PeakValue(1,:));

% save the peak value into the excel or variable
thisDateVector = now;
theDate8 = (datestr(thisDateVector,'yyyymmdd'));

sheetName_PeakValue = [expFolder,'_PeakValues']; 
if ~exist(fileName)
    fileName = strcat(saveDir, sheetName_PeakValue, '_', theDate8,'.xlsx');
end
fileNameBackup = strcat(saveDir,sheetName_PeakValue, '_', theDate8,'.mat');

if ispc || ismac
    writetable(table_PeakValues, fileName, 'Sheet', sheetName_PeakValue);
    save(fileNameBackup, 'table_PeakValues', '-v7.3') %, '-nocompression'
elseif isunix
    save(fileNameBackup, 'table_PeakValues', 'expFolder', '-v7.3') %, '-nocompression'
else
    disp('Platform not supported')
end

disp('Save the peak values into the excel file successfully!');
