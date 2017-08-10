%% Save mean of raw data and peak values into excel
[fileNames, saveDir] = uigetfile('*.mat', 'Please choose the ''.mat'' file contains the mean and peak values.', 'MultiSelect', 'on');
% expFolder = '202';
% epochStart = -200;

clusterNums = [65 58 59 66 70 69 64; % PO7
               90 96 91 84 83 89 95]; % PO8 
%                58 51 59 65 64 57 50 % P7
%                96 97 91 90 95 100 101 % P8

windowsInfo = [70,120;...   % time window for P1
               120,200];    % time window for N170

          
%% save the mean data into Excel
for iFile = 1:length(fileNames)
    load([saveDir,fileNames{iFile}]);
end

% info based on input
numElecPerCluster = size(clusterNums,2);
numCluster = size(clusterNums,1);

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

fileName = strcat(saveDir, expFolder, '_cluster_', theDate8, '.xlsx'); % excel file name

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
            
            tempCell(numLabel*(iPpt-1)+iLabel,(numLabelVariable+1):end) = num2cell(mean(tempTable{:,(numLabelVariable+1):end}));
            
        end   
    end 
    
    tempTable = cell2table(tempCell, 'VariableNames', table_MeanRaw.Properties.VariableNames);
    clusterTable = vertcat(clusterTable, tempTable);
    
end

sheetNameRaw = [expFolder, '_ClusterRaw'];
writetable(clusterTable, fileName, 'Sheet', sheetNameRaw);
disp('Save the mean data into the excel successfully!');
    
    
%% calculate the peak values and latency
% windowsInfo = [70,120;120,200]; % each row represents one time window, and the first and second columns represent the start and end time point of that window
numWindows = size(windowsInfo,1);
windowPN = [1, -1]; % positive or negative wave for the potential
numToCheck = 5; % how many time points do you want to check for each side. 
peak2Cal = 2; % how many time points do you want to calculate for peak value for each side.

numRow_PeakValue = size(clusterTable,1);
numColu_PeakValue = length(table_PeakValues.Properties.VariableNames);
clusterPeakCell = cell(numRow_PeakValue, numColu_PeakValue);

[~, NSColuNum] = ismember({'NS'}, table_PeakValues.Properties.VariableNames);
[~, FHColuNum] = ismember({'FH'}, table_PeakValues.Properties.VariableNames);
[~, DurationColuNum] = ismember({'Duration'}, table_PeakValues.Properties.VariableNames);

data2Check = clusterTable{:,(numLabelVariable+1):end};

for iRow = 1:numRow_PeakValue
    % the row data for this round
    tempRowData = data2Check(iRow,:);
    
    % save the (three) IVs about lables into the peak value data cell
    thisLabel = clusterTable{iRow, numLabelVariable}{1};
    if strcmp(expFolder, '201') || strcmp(expFolder, '204')
        clusterPeakCell(iRow, NSColuNum) = {'N'};
        clusterPeakCell(iRow, FHColuNum) = {thisLabel(1)};
        clusterPeakCell(iRow, DurationColuNum) = {thisLabel(2:4)};
    elseif strcmp(expFolder, '202') || strcmp(expFolder, '203')
        clusterPeakCell(iRow, NSColuNum) = {thisLabel(1)};
        clusterPeakCell(iRow, FHColuNum) = {thisLabel(2)};
        clusterPeakCell(iRow, DurationColuNum) = {thisLabel(3)};
    end
    
    % find and save the peak values
    for iWindow = 1:numWindows
        
        thisWindowStart = windowsInfo(iWindow,1);
        thisWindowEnd = windowsInfo(iWindow,2);
        
        windowStartPoint = abs(epochStart) + thisWindowStart;
        windowEndPoint = abs(epochStart) + thisWindowEnd;
        
        % the data to be checked for peak values
        dataInThisWindow = tempRowData(1, windowStartPoint:windowEndPoint);
        
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
        end
        
        % save the value data and latency into the data cell
        clusterPeakCell(iRow, 2*iWindow-1+DurationColuNum) = {tempMeanPeak};
        clusterPeakCell(iRow, 2*iWindow+DurationColuNum) = {tempLatency};
        
    end
end
    
clusterPeakTable = cell2table(clusterPeakCell, 'VariableNames', table_PeakValues.Properties.VariableNames);
clusterPeakTable(:,1:3) = clusterTable(:,1:3);
sheetNameRaw = [expFolder, '_ClusterPeak'];
writetable(clusterPeakTable, fileName, 'Sheet', sheetNameRaw);

disp('Save the peak values into the excel file successfully!');
