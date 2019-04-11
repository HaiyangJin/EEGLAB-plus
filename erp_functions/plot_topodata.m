function [topo_table, gtopo_table] = plot_topodata(epoch_table, gwindowTable, chanInfo, isPlot, figureSize)
% channel information
% chanInfo = EEG(1).chanlocs;
if nargin < 4 || isempty(isPlot)
    isPlot = 1;
end
if nargin < 5
    figureSize = [200, 300, 900, 750];
end

chanAll = unique(epoch_table.Channel);
nChan = length(chanAll);

if nChan ~= 128
    warning('There are only %d channel data, not all 128 channels.', nChan);
end


%% topo data
% topo data for every condition (event)
[G, Event, Channel] = findgroups(epoch_table.Event, epoch_table.Channel);
topo_table = table(Event, Channel);

% grand topo data
[GG, GChannel] = findgroups(epoch_table.Channel);
gtopo_table = table(GChannel);


varNames = epoch_table.Properties.VariableNames;
nComp = size(gwindowTable, 1);

for iComp = 1:nComp
    thisComp = gwindowTable{iComp, 'Component'}{1};
    
    startTime = gwindowTable{iComp, 'StartTime'};
    endTime = gwindowTable{iComp, 'EndTime'};
    
    startColu = xposition(varNames, xconverter(startTime));
    endColu = xposition(varNames, xconverter(endTime));
    
    % mean amplitude of the window
    epoch_table.(thisComp) = mean(epoch_table{:, startColu: endColu},2);
    
    % topo data for every condition
    topo_table.(thisComp) = splitapply(@mean, epoch_table.(thisComp), G);
    
    % grand topo data
    gtopo_table.(thisComp) = splitapply(@mean, epoch_table.(thisComp), GG);
    
end

%% plot topo map
if isPlot
    events = unique(Event);
    nEvent = length(events);
    
    % the right order of the channel data
    chanNum = cellfun(@(x) str2double(strrep(x, 'E', '')), GChannel);
    [~, order] = sort(chanNum);
    
    
    % plot topo for different events
    for iComp = 1:nComp
        thisComp = gwindowTable{iComp, 'Component'}{1};
        
        for iEvent = 1:nEvent
            thisEvent = events{iEvent};
                 
            isEvent = strcmp(topo_table.Event, thisEvent);
            topodata = topo_table{isEvent, thisComp};
            
            figureName = sprintf('%s-%s', thisComp, strrep(thisEvent, '_', '-'));
            
            plot_topo(topodata(order), chanInfo, figureName, figureSize);
            
        end
        
        % plot grand topo
        figureName = sprintf('GrandTopoMap-%s', thisComp);
        topodata = gtopo_table.(thisComp);
        
        plot_topo(topodata(order), chanInfo, figureName, figureSize);
        
    end
    
end
end

function plot_topo(topoData, chanInfo, figureName, figureSize)

topoFig = figure('Name',figureName);

topoplot(topoData, chanInfo,...  % ALLEEG(1).chanlocs, chanLocations
    ...   % set the maximum and minimum value for all the value 'maplimits', [-4 5],
    'electrodes', 'labels'); %             'channels', 'events'... % show the name of the events on their locations

colorbar; % show the color bar
title(['\fontsize{20}', figureName]);
% topoFig.Color = 'none';  % set the background color as transparent.
topoFig.Position = figureSize; % resize the window for this figure
%         set(gcf, 'Position', [200, 200, 900, 750])

% print the figure as pdf file
figurePDFName = figureName;
set(gcf,'PaperOrientation','landscape');

print(figurePDFName, '-dpdf', '-fillpage');

end