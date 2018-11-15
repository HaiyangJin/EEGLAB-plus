function eeglab_rawoutput(STUDY, ALLEEG, isTrialOutput)
% STUDY: from eeglab
% ALLEEG: from eeglab
% isTrialOutput(logical): Is the output for each trial? The default is 0.

% This script is to output the raw data for each bin (each participant,
% each condition, and each eletrode) and even for each trial.

%% Default values
if nargin < 2
    error('Not enough inputs for erp_rawoutput!');
elseif nargin < 3
    isTrialOutput = 0;
end

%% Information from STUDY and ALLEEG
electrodes = {STUDY.changrp.channels};  % all the electrodes in this exp
nElec = length(electrodes); % number of electrodes

event = STUDY.design.variable(1).value;  % get the event names
nEvent = length(event); % number of labels

subjCode = STUDY.subject; % cell array contains all the participant names
nSubj = length(subjCode);

% info about epoch start and end point
lagFrame = 1000 / ALLEEG(1).srate;

epochStart = ALLEEG(1).xmin*1000; 
epochEnd = ALLEEG(1).xmax*1000; 
epochLength = ALLEEG.pnts; % (epochEnd-epochStart+lagFrame)/lagFrame;


%% Preparation for saving the raw data
% create the struct for Independent variables
IVstruct = struct;

% IVstruct().subjCode = 
% IVstruct().electrode = 
% IVstruct().event = 

% create the cell for saving rawEpoch
if isTrialOutput
    xRawEpoch = sum([ALLEEG(:).trials]) * nElec; 
else
    xRawEpoch = nSubj * nEvent * nElec;
end
rawEpoch = cell(xRawEpoch, epochLength);

% create the Variable Names for rawEpoch
rawVarNames = erp_pointvarnames(ALLEEG);


%% Combine all the trials across all conditions
% create the cell for IVs and DVs of mean raw data
clear cell_MeanRawDVs;
cell_MeanRawDVs = cell(numRow_MeanRaw,numColu_MeanRawDVs);
cell_MeanRawDVs(1,:) = meanRaw_DVs;

numRowsEachElec = nEvent*nSubj;

for iElec = 1:nElec
    % add the electrode names into the IVs
    tempElec = elecAll(iElec); 
    elecStartRow = (iElec-1)*numRowsEachElec+1+1;
    elecEndRow = iElec*numRowsEachElec+1;
    cell_MeanRawIVs(elecStartRow:elecEndRow, elecColuNum) = tempElec;
    
    
    
    
    means = squeeze( mean( EEG.data( :, samples, : ), 2 ) );
    
    
    % get the erpdata from the study
    [STUDY, erpdata, erptimes] = std_erpplot(STUDY,ALLEEG,'channels',tempElec,'noplot', 'on');
    
    for iLabel = 1:nEvent
        % add the label names into the IVs
        thisLabel = event(iLabel);
        labelStartRow = (iLabel-1)*numParticipant + elecStartRow;
        labelEndRow = iLabel*numParticipant - 1 + elecStartRow;
        cell_MeanRawIVs(labelStartRow:labelEndRow,labelColuNum) = thisLabel;
        
        % add participant names into the IVs
        cell_MeanRawIVs(labelStartRow:labelEndRow,participantColuNum) = subjCode;
        
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
rawMeanName = strcat(studyPath, sheetName_MeanRaw, '_', folderInfo, '_', dt);
excelName_RawMean = strcat(rawMeanName, '.xlsx');
backup_RawMean = strcat(rawMeanName, '.mat');


end