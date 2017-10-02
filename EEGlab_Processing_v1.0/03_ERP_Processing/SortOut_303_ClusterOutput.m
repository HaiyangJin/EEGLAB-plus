%% Save mean of raw data and peak values into excel
[fileNames, saveDir] = uigetfile('*.mat', 'Please choose the ''.mat'' file contains the mean and peak values.',...
    'MultiSelect', 'on');
% expFolder = '202';

windowsInfo = [95,123;   % time window for P1
              144,208];    % time window for N170

%% cluster information
% clusterNumP1 = [65 58 59 66 70 69 64; % PO7
%                 90 96 91 84 83 89 95]; % PO8

clusterNumP1 = [64 57 58 65 69 68 63; % P9
                95 100 99 94 89 90 96]; % P10

clusterNumN1 = [65 58 59 66 70 69 64; % PO7
                90 96 91 84 83 89 95]; % PO8

% clusterNumN1 = [58 51 59 65 64 57 50; % P7
%                 96 97 91 90 95 100 101]; % P8

potentials = {clusterNumP1, clusterNumN1};
potentialNames = {'P1', 'N170'};

%% Preparation
% Preparation for saving raw data
for iFile = 1:length(fileNames)
    load([saveDir,fileNames{iFile}]);
end

% participant and labels
participantNames = unique(table_MeanRaw.ParticipantNum);
numParticipant = length(participantNames);
labelNames = unique(table_MeanRaw.label);
numLabel = length(labelNames);

[~, numPptVariable] = ismember({'ParticipantNum'}, table_MeanRaw.Properties.VariableNames);
[~, numElecVariable] = ismember({'electrode'}, table_MeanRaw.Properties.VariableNames);
[~, numLabelVariable] = ismember({'label'}, table_MeanRaw.Properties.VariableNames);
epochStart = -str2double(table_MeanRaw.Properties.VariableNames{1,numLabelVariable+1}(2:end));

% thisDateVector = now;
% theDate8 = (datestr(thisDateVector,'yyyymmdd'));
dotPosition = find('.' == fileNames{iFile});
theDate8 = fileNames{iFile}((dotPosition-8):(dotPosition-1));

fileName = strcat(saveDir, expFolder, '_ClusterData_', theDate8, '.xlsx'); % excel file name

% Preparation for finding the peak values and corresponding latencies
% windowsInfo = [70,120;120,200];
numWindows = size(windowsInfo,1);
windowPN = [1, -1]; % positive or negative wave for the potential
numToCheck = 5; % how many time points do you want to check for each side.
peak2Cal = 2; % how many time points do you want to calculate for peak value for each side.

[~, NSColuNum] = ismember({'NS'}, table_PeakValues.Properties.VariableNames);
[~, FHColuNum] = ismember({'FH'}, table_PeakValues.Properties.VariableNames);
[~, DurationColuNum] = ismember({'Duration'}, table_PeakValues.Properties.VariableNames);

for iPotential = 1:length(potentials)
    thisPotentialName = potentialNames{1,iPotential};
    clusterNums = potentials{1,iPotential};
    
    numElecPerCluster = size(clusterNums,2);
    numCluster = size(clusterNums,1);
    
    %% output the mean raw data for the cluster
    clusterTable = table;
    for iCluster = 1:numCluster
        tempCenElec = ['E', num2str(clusterNums(iCluster,1))];
        elecNames = arrayfun(@(x) {['E', num2str(x)]}, clusterNums(iCluster,:));
        rowsElec = ismember(table_MeanRaw.electrode, elecNames);
        
        % create the data cell for this cluster
        clear tempCell
        numRows = numParticipant*numLabel;
        tempCell = cell(numRows,size(table_MeanRaw,2));
        tempCell(:,numElecVariable) = {tempCenElec}; % central electrode
        
        for iPpt = 1:numParticipant % participant
            tempPptName = participantNames{iPpt, 1};
            rowsPpt = strcmp(table_MeanRaw.ParticipantNum, tempPptName);
            tempCell((numLabel*(iPpt-1)+1):(numLabel*iPpt),numPptVariable) = {tempPptName}; % participant names
            
            for iLabel = 1:numLabel % label
                tempLabelName = labelNames{iLabel,1};
                rowsLabel = strcmp(table_MeanRaw.label, tempLabelName);
                tempCell(numLabel*(iPpt-1)+iLabel,numLabelVariable) = {tempLabelName}; % label name
                
                tempRows = logical(rowsElec .* rowsPpt .* rowsLabel);
                tempTable = table_MeanRaw(tempRows, :);
                
                tempCell(numLabel*(iPpt-1)+iLabel,(numLabelVariable+1):end) = ...
                    num2cell(mean(tempTable{:,(numLabelVariable+1):end}));
                
            end
        end
        
        tempTable = cell2table(tempCell, 'VariableNames', table_MeanRaw.Properties.VariableNames);
        clusterTable = vertcat(clusterTable, tempTable);
        
    end
    
    
    % sheet name and save the table data into excel
    sheetNameRaw = [expFolder, '_', thisPotentialName, '_ClusterRaw'];
    writetable(clusterTable, fileName, 'Sheet', sheetNameRaw);
    
    disp(['Save the mean data of ', thisPotentialName, ' into the excel successfully!']);
    
    %% calculate the peak values and latency
    % Preparation
    numRow_PeakValue = size(clusterTable,1);
    numColu_PeakValue = length(table_PeakValues.Properties.VariableNames);
    clusterPeakCell = cell(numRow_PeakValue, numColu_PeakValue);
    
    data2Check = clusterTable{:,(numLabelVariable+1):end};
    
    for iRow = 1:numRow_PeakValue
        % the row data for this round
        tempRowData = data2Check(iRow,:);
        
        % save the (three) IVs about lables into the peak value data cell
        thisLabel = clusterTable{iRow, numLabelVariable}{1};
        if strcmp(expFolder, '201') %|| strcmp(expFolder, '204')
            clusterPeakCell(iRow, NSColuNum) = {'N'};
            clusterPeakCell(iRow, FHColuNum) = {thisLabel(1)};
            clusterPeakCell(iRow, DurationColuNum) = {thisLabel(2:4)};
        elseif strcmp(expFolder, '202') || strcmp(expFolder, '203')
            clusterPeakCell(iRow, NSColuNum) = {thisLabel(1)};
            clusterPeakCell(iRow, FHColuNum) = {thisLabel(2)};
            clusterPeakCell(iRow, DurationColuNum) = {thisLabel(3)};
        end
        
        % find and save the peak values
        iWindow = iPotential; % the time window for this potential
        thisWindowStart = windowsInfo(iWindow,1);
        thisWindowEnd = windowsInfo(iWindow,2);
        
        windowStartPoint = abs(epochStart) + thisWindowStart;
        windowEndPoint = abs(epochStart) + thisWindowEnd;
        
        % the data to be checked for peak values
        dataInThisWindow = tempRowData(1, windowStartPoint:windowEndPoint);
        zeroNum = 0;
        
        if windowPN(iWindow) > 0
            [~, tempColu] = max(dataInThisWindow);
            tempColuCluster = tempColu + windowStartPoint;
            tempMeanPeak = mean(data2Check(iRow, tempColuCluster + (-peak2Cal:peak2Cal)));
            tempLatency = str2double(table_MeanRaw.Properties.VariableNames{1,tempColuCluster}(2:end));
        elseif windowPN(iWindow) < 0
            [~, tempColu] = min(dataInThisWindow);
            tempColuCluster = tempColu + windowStartPoint;
            tempMeanPeak = mean(data2Check(iRow, tempColuCluster + (-peak2Cal:peak2Cal)));
            tempLatency = str2double(table_MeanRaw.Properties.VariableNames{1,tempColuCluster}(2:end));
        else
            tempMeanPeak = [];
            tempLatency = [];
            zeroNum = zeroNum + 1;
        end
        
        % save the value data and latency into the data cell
        clusterPeakCell(iRow, 2*iWindow-1+DurationColuNum) = {tempMeanPeak};
        clusterPeakCell(iRow, 2*iWindow+DurationColuNum) = {tempLatency};
        
    end
    
    clusterPeakTable = cell2table(clusterPeakCell, 'VariableNames', table_PeakValues.Properties.VariableNames);
    clusterPeakTable(:,1:3) = clusterTable(:,1:3);
    
    % the sheet name and save the peak value data
    sheetNameRaw = [expFolder, '_', thisPotentialName, '_ClusterPeak'];
    writetable(clusterPeakTable, fileName, 'Sheet', sheetNameRaw);
    
    disp(['Save the peak values ', thisPotentialName, ' into the excel file successfully!']);
    
end

disp('All Done!!!');
disp(['zeroNum = ',num2str(zeroNum)]);





%% variableNames for peak values
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
dt = (datestr(thisDateVector,'yyyymmdd'));

sheetName_PeakValue = [expFolder,'_PeakValues']; 
if ~exist(excelName_RawMean)
    excelName_RawMean = strcat(studyPath, sheetName_PeakValue, '_', dt,'.xlsx');
end
backup_RawMean = strcat(studyPath,sheetName_PeakValue, '_', dt,'.mat');

if ispc || ismac
    writetable(table_PeakValues, excelName_RawMean, 'Sheet', sheetName_PeakValue);
    save(backup_RawMean, 'table_PeakValues', '-v7.3') %, '-nocompression'
elseif isunix
    save(backup_RawMean, 'table_PeakValues', 'expFolder', '-v7.3') %, '-nocompression'
else
    disp('Platform not supported')
end

disp('Save the peak values into the excel file successfully!');
