%% display the topography to check the location of the cluster
% load the data for topography
[fileNames, saveDir] = uigetfile('*.mat', 'Please choose the ''.mat'' file contains the data for topography.');
load([saveDir,fileNames]); % load the raw data

numLabel = size(table_TopoData,2);
numPotential = size(table_TopoData,1);

%% show the figure
iPotential = [];
iLabel = [];
while isempty(iPotential)
    iPotential = input('Please enter the potential number for the topography (P1: 1; N1: 2):');
end
while isempty(iLabel)
    iLabel = input('Please enter the label number for the topography:');
end

% Name of the figure
namePart1 = table_TopoData.Properties.RowNames{iPotential,1};
namePart2 = table_TopoData.Properties.VariableNames{iLabel,1};
figureName = [expFolder, '-', namePart1, '-', namePart2];

% get the data for this potential and this label
topoData = table_TopoData{iPotential,iLabel};

topoFig = figure('Name',figureName);
topoplot_EEGlab(topoData, ALLEEG(1).chanlocs,...  % ALLEEG(1).chanlocs, chanLocations
    'maplimits', [-4 5],...   % set the maximum and minimum value for all the value
    'electrodes', 'labels'... % show the name of the labels on their locations
    ); 
colorbar; % show the color bar
title(['\fontsize{20}', figureName]);
% topoFig.Color = 'none';  % set the background color as transparent.
set(gcf, 'Position', [200, 200, 900, 750]) % resize the window for this figure

% print the figure as pdf file
figurePDFName = [saveDir, figureName]; 
print(figurePDFName, '-dpdf'); 

