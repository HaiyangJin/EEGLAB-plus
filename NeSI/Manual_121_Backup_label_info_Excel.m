%% Save labels backup into Excel
% This file is used to save the backup label info (from 12.sl cluster) into Excel

% read the label backup files from '*.mat' and save in Excel
[filenames,filePath] = uigetfile({'*.mat','MAT-files (*.mat)'},...
    'Please select all the (*.mat) files on labels for saving as Excel.', 'MultiSelect', 'on');

% create a cell to save all the backup labels
if ~iscell(filenames)
    load([filePath, filenames]); % load 'labelsBackCell'
    numFiles = 1;
    experimentName = ['20', filenames(2)];
    
    variableNames = cellfun(@(x) erase(x, '+'), labelsBackCell(1, :), 'UniformOutput', false); 
    allLabel_Table = cell2table(labelsBackCell(2:end,:), 'VariableNames', variableNames);
    filenameAllLabel = [filePath, experimentName, '_', num2str(numFiles), '_BackupLabelInfo.xlsx'];
    writetable(allLabel_Table, filenameAllLabel);
else
    tempFilename = filenames{1};
    load([filePath, tempFilename]);  % load 'labelsBackCell'
    numFiles = length(filenames);
    experimentName = ['20', tempFilename(2)];
    
    allLabelBackup = cell(numFiles + 1, size(labelsBackCell,2) +1); % create a cell to save all labels
%     allLabelBackup(1,1) = {'PariticpantNum'};
    allLabelBackup(1,2:end) = labelsBackCell(1,:); % save the first row to the cell
    
    for iFile = 1:numFiles
        clear labelsBackCell
        tempFilename = filenames{iFile};
        load([filePath, tempFilename]);  % load 'labelsBackCell'
        allLabelBackup(iFile + 1, 1) = {tempFilename(1:4)};
        allLabelBackup(iFile + 1, 2:end) = labelsBackCell(2,:);  % save the label info for this file
    end
    
    % Save the cell as table and save as excel file
    variableNames = cellfun(@(x) [x(1:3), x(5:end)], labelsBackCell(1,:), 'UniformOutput', false); 
    allLabel_Table = cell2table(allLabelBackup(2:end,:), 'VariableNames', horzcat({'PariticpantNum'}, variableNames));
    filenameAllLabel = [filePath, experimentName, '_', num2str(numFiles), '_BackupLabelInfo'];
    allLabelExcel = [filenameAllLabel '.xlsx'];
    allLabelCsv = [filenameAllLabel '.csv'];
    writetable(allLabel_Table, allLabelExcel);
    writetable(allLabel_Table, allLabelCsv);
    
end