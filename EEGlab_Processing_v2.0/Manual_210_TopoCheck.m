%% display the topography to check the location of the cluster
% load the data for topography
[fileNames, saveDir] = uigetfile('*.mat', 'Please choose the ''.mat'' file contains the raw mean (topo) data for topography.');
load([saveDir,fileNames]); % load the raw data


%% show the figure (loop)
% iPotential = [];
% iLabel = [];
% while isempty(iPotential)
%     iPotential = input('Please enter the potential number for the topography (P1: 1; N1: 2):');
% end
% while isempty(iLabel)
%     iLabel = input('Please enter the label number for the topography:');
% end

for iPotential = 1:size(table_GrandTopoCheck,2)
    for iLabel = 1:numLabel
        
        % Name of the figure
%         namePart1 = table_GrandTopoCheck.Properties.RowNames{iLabel,1};
        namePart2 = table_GrandTopoCheck.Properties.VariableNames{1,iPotential};
        figureName = [namePart2];  % namePart1, '-', 
        fileName = [expFolder, '-',figureName];
        
        % get the data for this potential and this label
        GrandTopoData = table_GrandTopoCheck{iLabel, iPotential};
        
        topoFig = figure('Name',figureName);
        topoplot(GrandTopoData, ALLEEG(1).chanlocs,...  % ALLEEG(1).chanlocs, chanLocations
            ...   % set the maximum and minimum value for all the value    'maplimits', [-4 5],
            'electrodes', 'labels'); %             'electrodes', 'labels'... % show the name of the labels on their locations

        colorbar; % show the color bar
        title(['\fontsize{20}', figureName]);
        % topoFig.Color = 'none';  % set the background color as transparent.
        topoFig.Position = [200, 300, 900, 750]; % resize the window for this figure
%         set(gcf, 'Position', [200, 200, 900, 750]) 
        
        % print the figure as pdf file
        figurePDFName = [saveDir, fileName];
        print(figurePDFName, '-dpdf');
    end
end


%% show the figure (one by one)
% iPotential = [];
% iLabel = [];
% while isempty(iPotential)
%     iPotential = input('Please enter the potential number for the topography (P1: 1; N1: 2):');
% end
% while isempty(iLabel)
%     iLabel = input('Please enter the label number for the topography:');
% end
% 
% % Name of the figure
% namePart1 = table_GrandTopoCheck.Properties.RowNames{iPotential,1};
% namePart2 = table_GrandTopoCheck.Properties.VariableNames{1,iLabel};
% figureName = [expFolder, '-', namePart1, '-', namePart2];
% 
% % get the data for this potential and this label
% GrandTopoData = table_GrandTopoCheck{iPotential,iLabel};
% 
% topoFig = figure('Name',figureName);
% topoplot_EEGlab(GrandTopoData, ALLEEG(1).chanlocs,...  % ALLEEG(1).chanlocs, chanLocations
%     'maplimits', [-4 5],...   % set the maximum and minimum value for all the value
%     'electrodes', 'labels'... % show the name of the labels on their locations
%     ); 
% colorbar; % show the color bar
% title(['\fontsize{20}', figureName]);
% % topoFig.Color = 'none';  % set the background color as transparent.
% set(gcf, 'Position', [200, 200, 900, 750]) % resize the window for this figure
% 
% % print the figure as pdf file
% figurePDFName = [saveDir, figureName]; 
% print(figurePDFName, '-dpdf');
