%% Output the time window for P1 and N1 (N170)
%% Save mean of raw data and peak values into excel
% select the matlab data file (table) which includes the grand average data
% for all conditions
[fileNames, saveDir] = uigetfile('*.mat', 'Please choose the ''.mat'' file contains the mean values.');
load([saveDir,fileNames]); % load the raw data

% Input info
expFolder = '202';

leftElec = 'E58';    % P7, center of the assumed cluster
rightElec = 'E96';   % P8, center of the assumed cluster
start_Assumed = 0;  % assumed start time point for P1
end_Assumed = 220;   % assumed end time point for N1
ratioPeak = 1/2;     % the ratio of peak value. (PEAK VALUE * RATIO) would be used to lock the time window
 
%% save the data for two electordes to get the grand average data for locking time windows
rowLogic = logical(strcmp(table_MeanRaw{:, 2}, leftElec) + strcmp(table_MeanRaw{:, 2}, rightElec)); %get all the rows for E58 and E96
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
    writetable(table_TimeWindow, excelName_LockWindow, 'WriteRowNames', true, 'Sheet', sheetName_GrandAver, 'Range', 'B5');
else
    disp('Platform not supported')
end

disp('Save the time windows into the excel file successfully!');
disp('Done!');