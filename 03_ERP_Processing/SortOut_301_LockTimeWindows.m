%% Output the time window for P1 and N1 (N170)
%% Save mean of raw data and peak values into excel
% select the matlab data file (table) which includes the grand average data
% for all conditions
[fileNames, saveDir] = uigetfile('*.mat', 'Please choose the ''.mat'' file contains the mean values.');
load([saveDir,fileNames]); % load the raw data

% Input info
experimentNum = [];
while isempty(experimentNum)
    experimentNum = input('Please enter the experiment number (1, 2, or 3): ','s');
end
expFolder = ['20', num2str(experimentNum)];

leftElec = 'E58';    % P7, center of the assumed cluster
rightElec = 'E96';   % P8, center of the assumed cluster
start_Assumed = 0;  % assumed start time point for P1
end_Assumed = 220;   % assumed end time point for N1
ratioPeak = 1/2;     % the ratio of peak value. (PEAK VALUE * RATIO) would be used to lock the time window
 
%% save the data for two electordes to get the grand average data for locking time windows
rowLogic = logical(strcmp(table_MeanRaw{:, 'electrode'}, leftElec) + strcmp(table_MeanRaw{:, 'electrode'}, rightElec)); %get all the rows for E58 and E96
table_LockWindow = table_MeanRaw(rowLogic, :);
coluNumGrand = size(table_LockWindow,2);
table_GrandAver = table;

% add the variable names again and the grand average row
rowGrandValue = num2cell(mean(table_LockWindow{:,4:end}));
rowGrand = horzcat({'GrandAverage', [leftElec,rightElec], 'All'},rowGrandValue);
table_GrandAver(1,1:coluNumGrand) = rowGrand;
table_GrandAver.Properties.VariableNames = table_LockWindow.Properties.VariableNames;
table_LockWindow = vertcat(table_LockWindow, rowGrand);

thisDateVector = now;
theDate8 = (datestr(thisDateVector,'yyyymmdd'));

excelName_LockWindow = strcat(saveDir, expFolder, '_LockingWindow_', theDate8, '.xlsx');
sheetName_LockWindow = 'LockWindow'; 
sheetName_GrandAver = 'GrandAver';

if ispc || ismac
    writetable(table_LockWindow, excelName_LockWindow, 'Sheet', sheetName_LockWindow);
    writetable(table_GrandAver, excelName_LockWindow, 'Sheet', sheetName_GrandAver);
else
    disp('Platform not supported')
end

disp('Save the data for locking windows into the excel file successfully!');

%% calculate the time windows
% find the time points where the values changes from positive to 
% negative or vice vera between 50 and 220
coluNum0 = find(strcmp(table_GrandAver.Properties.VariableNames,'P0'));
nZero = 0;
for iTime = start_Assumed:end_Assumed
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
                    if iTime > 75 
                        tempP1_End = iTime;
                        tempN1_Start = iTime + 1;
                    else
                        nZero = 0; % if the second zero point (from positive to negative) is less than 75 then restart finding zero.
                    end
                case 4
                    error('There are more than 3 changes between positive and negative. Please check manually');
            end 
        end 
    end
end 

% get all the positive time point data for grand average
grandPositive = table_GrandAver{1, coluNum0+1:end};

% lock the time window for P1
[peakP1, timePeakP1] = max(grandPositive(tempP1_Start:tempP1_End));  % get the peak values for P1 and N1
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
[peakN1, timePeakN1] = min(grandPositive(tempN1_Start:tempN1_End));
ratioValueN1 = peakN1 * ratioPeak;

for iTime_N1 = tempN1_Start:tempN1_End
    tempValue1_N1 = grandPositive(iTime_N1);
    tempValue2_N1 = grandPositive(iTime_N1+1);
    if tempValue1_N1 <= ratioValueN1 && tempValue2_N1 >= ratioValueN1
        timeWindowN1_End = iTime_N1 + 1;
    elseif tempValue1_N1 >= ratioValueN1 && tempValue2_N1 <= ratioValueN1
        timeWindowN1_Start = iTime_N1;   
    end 
end

% create a table to contain the info about time windows and save in the
% excel
timePointPeak = {timePeakP1 + tempP1_Start - 1; timePeakN1 + tempN1_Start - 1};
windowStart = {timeWindowP1_Start; timeWindowN1_Start};
windowEnd = {timeWindowP1_End; timeWindowN1_End};
rowNames = {'P1'; 'N1'};
table_TimeWindow = table(timePointPeak, windowStart, windowEnd, 'RowNames', rowNames);

if ispc || ismac
    writetable(table_TimeWindow, excelName_LockWindow, 'WriteRowNames', true,...
        'Sheet', sheetName_GrandAver, 'Range', 'B5');
else
    disp('Platform not supported')
end

disp('Save the time windows into the excel file successfully!');

%% Create the matlab data file for scalp distribution confirmation
% Preparation
% DivEpo labels
% if strcmp(experimentNum, '1')
%     labels = {'F017' 'F050'  'F100'  'F200'  'H017'  'H050'  'H100'  'H200'};
% else
%     labels = {'NF7+'  'NF5+'  'NF1+'  'NF2+'  'NH7+'  'NH5+'  'NH1+'  'NH2+' ...
%               'SF7+'  'SF5+'  'SF1+'  'SF2+'  'SH7+'  'SH5+'  'SH1+'  'SH2+'};
% end
labels = unique(table_MeanRaw{:,'label'})';
numLabels = length(labels);

% Electrodes
allElec = {'E1' 'E2' 'E3' 'E4' 'E5' 'E6' 'E7' 'E8' 'E9' 'E10' 'E11' 'E12' 'E13' 'E14' 'E15' 'E16' 'E18' 'E19' 'E20'...
 'E21' 'E22' 'E23' 'E24' 'E25' 'E26' 'E27' 'E28' 'E29' 'E30' 'E31' 'E32' 'E33' 'E34' 'E35' 'E36' 'E37' 'E38' 'E39' 'E40'...
 'E41' 'E42' 'E43' 'E44' 'E45' 'E46' 'E47' 'E48' 'E49' 'E50' 'E51' 'E52' 'E53' 'E54' 'E55' 'E56' 'E57' 'E58' 'E59' 'E60'...
 'E61' 'E62' 'E63' 'E64' 'E65' 'E66' 'E67' 'E68' 'E69' 'E70' 'E71' 'E72' 'E73' 'E74' 'E75' 'E76' 'E77' 'E78' 'E79' 'E80'...
 'E81' 'E82' 'E83' 'E84' 'E85' 'E86' 'E87' 'E88' 'E89' 'E90' 'E91' 'E92' 'E93' 'E94' 'E95' 'E96' 'E97' 'E98' 'E99' 'E100'...
 'E101' 'E102' 'E103' 'E104' 'E105' 'E106' 'E107' 'E108' 'E109' 'E110' 'E111' 'E112' 'E113' 'E114' 'E115' 'E116' 'E117'...
 'E118' 'E119' 'E120' 'E121' 'E122' 'E123' 'E124' 'E125' 'E126' 'E127' 'E128' 'Cz'};
numElec = length(allElec);

% Participants
participants = unique(table_MeanRaw{:,'ParticipantNum'})';
numParticipant = length(participants);

table_TopoData = table; % create the table for the data of scalp distribution

for iTimeWindow = 1:length(rowNames)
    startThisWindow = table_TimeWindow{iTimeWindow,'windowStart'};
    endThisWindow = table_TimeWindow{iTimeWindow, 'windowEnd'};
    
    startColuName = ['P', num2str(startThisWindow{1,1})];
    endColuName = ['P', num2str(endThisWindow{1,1})];
    
    startColuNum = find(strcmp(table_MeanRaw.Properties.VariableNames,startColuName));
    endColuNum = find(strcmp(table_MeanRaw.Properties.VariableNames,endColuName));

    for iLabel = 1:numLabels
        thisLabel = labels{1,iLabel};
        
        tempTopoData = zeros(1,numElec);
        
        for iElec = 1:numElec
            thisElec = allElec{1,iElec};
            
            logicTempRows = logical(strcmp(table_MeanRaw{:, 'label'}, thisLabel) .* ...
                strcmp(table_MeanRaw{:,'electrode'}, thisElec));
            tempRawData = table_MeanRaw{logicTempRows, startColuNum:endColuNum};
        
            % tempTopoData for this time widnow and label
            tempTopoData(1,iElec) = mean(mean(tempRawData));
        end
        
        table_TopoData(iTimeWindow,iLabel) = {tempTopoData};
        
    end
end

if ~strcmp(experimentNum, '1')
    for iLabel = 1:numLabels
        labels{1,iLabel} = labels{1,iLabel}(1:3);
    end
end

table_TopoData.Properties.VariableNames = labels;
table_TopoData.Properties.RowNames = rowNames;

fileNameBackup = strcat(saveDir, expFolder, '_TopoData_', theDate8);
save(fileNameBackup, 'table_TopoData', 'chanLocations', 'expFolder', '-v7.3') %, '-nocompression'

disp('Save the data for topograph check successfully!');
disp('Done!');
