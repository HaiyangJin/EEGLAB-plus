%% save *.mat files as Excel and pdf


% read the label backup files from '*.mat' and save in Excel
[filenames,studyPath] = uigetfile({'*.mat','MAT-files (*.mat)'},...
    'Please select all the files (*.mat) for backuping labels.', 'MultiSelect', 'on');

% load the *.mat
if ~iscell(filenames)
    load([studyPath, filenames]); % load the *.mat
    numFiles = 1;
else
    numFiles = length(filenames);
    for iFile = 1:numFiles
        load([studyPath, filenames{iFile}]);  % load all the *.mat
    end
    
end


if exist('table_MeanRaw','var')
    sheetName_MeanRaw = [expFolder,'_MeanRaw'];
    rawMeanName = strcat(studyPath, sheetName_MeanRaw);
    excelName_RawMean = strcat(rawMeanName, '.xlsx');
    
    writetable(table_MeanRaw, excelName_RawMean, 'Sheet', sheetName_MeanRaw);
end


if exist('table_GrandAver','var')
    
    sheetName_LockWindow = 'LockWindow';
    sheetName_GrandAver = 'GrandAver';
    lockWindowName = strcat(studyPath, expFolder, '_LockingWindow');
    excelName_LockWindow = strcat(lockWindowName, '.xlsx');
    
    writetable(table_GrandAver, excelName_LockWindow, 'Sheet', sheetName_GrandAver);
    writetable(table_LockWindow, excelName_LockWindow, 'Sheet', sheetName_LockWindow);
    writetable(table_TimeWindow, excelName_LockWindow, 'WriteRowNames', true,...
        'Sheet', sheetName_GrandAver, 'Range', 'B5');   
end

if exist('table_GrandTopoCheck','var')
    
    sheetName_Topo = 'TopoCheck';
    topoCheck = strcat(studyPath, expFolder, '_TopoData');
    excelName_TopoCheck = strcat(topoCheck, '.xlsx');
    
    writetable(table_GrandTopoCheck, excelName_TopoCheck, 'Sheet', sheetName_Topo);   
end

for iPotential = 1:size(table_GrandTopoCheck,2)
    
    % Name of the figure
    namePotential = table_GrandTopoCheck.Properties.VariableNames{1,iPotential};
    topoFigureName = [namePotential, '-GrandTopo-cluster']; 
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
    

disp('Done!');