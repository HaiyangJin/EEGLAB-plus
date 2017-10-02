%% Save mean of raw data and peak values into excel
[fileNames, saveDir] = uigetfile('*.mat', 'Please choose the ''.mat'' file contains the mean and peak values.', 'MultiSelect', 'on');

expFolder = '202';

%% save the mean data into Excel
load([saveDir,fileNames{1}]);

% save the mean of the raw data into the excel
thisDateVector = now;
theDate8 = (datestr(thisDateVector,'yyyymmdd'));

sheetName_MeanRaw = [expFolder,'_MeanRaw']; 
fileName = strcat(saveDir, expFolder, '_RawData_', theDate8, '.xlsx');
% fileNameBackup = strcat(saveDir, sheetName_MeanRaw, '_', theDate8, '.mat');

if ispc || ismac
    writetable(table_MeanRaw, fileName, 'Sheet', sheetName_MeanRaw);
%     save(fileNameBackup, 'cell_MeanRaw', '-v7.3') %, '-nocompression'
% elseif isunix
%     save(fileNameBackup, 'cell_MeanRaw', '-v7.3') %, '-nocompression'
else
    disp('Platform not supported')
end
% Mean Raw data
% rawSheetName = '201_meanEEGData';  
% xlswrite(fileName,meanRawData,rawSheetName);

disp('Save the mean data into the excel successfully!');


%% save the peak values into Excel
load([saveDir,fileNames{2}]);
% save the peak value into the excel or variable
sheetName_PeakValue = [expFolder,'_PeakValues']; 
% if ~exist(fileName)
%     fileName = strcat(saveDir, sheetName_PeakValue, '_', theDate8,'.xlsx');
% end
% fileNameBackup = strcat(saveDir,sheetName_PeakValue, '_', theDate8,'.mat');

if ispc || ismac
    writetable(table_PeakValues, fileName, 'Sheet', sheetName_PeakValue);
%     save(fileNameBackup, 'cell_PeakValue', '-v7.3') %, '-nocompression'
% elseif isunix
%     save(fileNameBackup, 'cell_PeakValue', '-v7.3') %, '-nocompression'
else
    disp('Platform not supported')
end

disp('Save the peak values into the excel file successfully!');

%% save the data for two electordes to get the grand average data for locking time windows
% leftElec = 'E58'; % P7
% rightElec = 'E96'; % P8
% rowLogic = logical(strcmp(table_MeanRaw{:, 2}, leftElec) + strcmp(table_MeanRaw{:, 2}, rightElec)); %get all the rows for E58 and E96
% table_LockWindow = table_MeanRaw(rowLogic, :);
% coluNumGrand = size(table_LockWindow,2);
% table_GrandAver = table;
% 
% % add the variable names again and the grand average row
% rowGrandValue = num2cell(mean(table_LockWindow{:,4:end}));
% rowGrand = horzcat({'GrandAverage', [leftElec,rightElec], 'All'},rowGrandValue);
% table_GrandAver(1,1:coluNumGrand) = rowGrand;
% table_GrandAver.Properties.VariableNames = table_LockWindow.Properties.VariableNames;
% table_LockWindow = vertcat(table_LockWindow, rowGrand);
% 
% 
% excelName_LockWindow = strcat(saveDir, expFolder, '_LockingWindow_', theDate8, '.xlsx');
% sheetName_LockWindow = 'LockWindow'; 
% sheetName_GrandAver = 'GrandAver';
% 
% if ispc || ismac
%     writetable(table_LockWindow, excelName_LockWindow, 'Sheet', sheetName_LockWindow);
%     writetable(table_GrandAver, excelName_LockWindow, 'Sheet', sheetName_GrandAver);
% else
%     disp('Platform not supported')
% end
% 
% disp('Save the data for locking windows into the excel file successfully!');
