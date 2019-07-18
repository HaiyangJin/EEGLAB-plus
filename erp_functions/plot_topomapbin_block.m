function plot_topomapbin_block(topovideo_table, onsetCode, respCode, timeWindow, lagForVideo)
% save the topo map for the onset events (with response events)
% topovideo_table: the output from output_topovideo
% onsetCode: (double)
% respCode: (double)
% blockCode: (double)
% timeWindow: [double, double]
% lagForVideo (plot averaged topo map when 0)

events = unique(topovideo_table.Event);
nEvent = length(events);
if nargin < 2 || isempty(onsetCode)
    onsetCode = 1:nEvent;
end
responses = unique(topovideo_table.urResponse);
nResp = length(responses);
if nargin < 3 || isempty(respCode)
    respCode = [];
elseif respCode == 'all'
    respCode = 1:nResp;
end
isBasedResp = ~isempty(respCode);
if nargin < 5 
    timeWindow = [];
end
if nargin < 6 || isempty(lagForVideo) || lagForVideo < 0
    lagForVideo = 0;
end

[~, isDataColu] = xposition(topovideo_table.Properties.VariableNames);
dataNames = topovideo_table.Properties.VariableNames(isDataColu);

%% Save the topo map for each condition

if isBasedResp
    isEvent = respCode > nResp;
    if sum(isEvent)
        error('There is no corresponding response event for respCode %d.\n',...
            respCode(isEvent));
    end
end

for iEvent = onsetCode
    thisEvent = events{iEvent};
    
    if ~exist(thisEvent, 'dir') && lagForVideo ~= 0; mkdir(thisEvent); end
    
    thisEventTable = topovideo_table(strcmp(topovideo_table.Event, thisEvent), :);
    
    % if based on responses
    for iResp = respCode
        thisResp = responses{iResp};
        
        respTable = thisEventTable(strcmp(thisEventTable.urResponse, thisResp), :);
        
        blocks = unique(respTable.Block);
        
        if ~isempty(blocks)
        
        for iBlock = 1:length(blocks)
            thisBlock = blocks{iBlock};
            blockTable = respTable(strcmp(respTable.Block, thisBlock), :);
            
            theFolder = [thisEvent '-Blo' thisBlock '-'];
            
            if size(blockTable, 1) > 0
                theFolder = [theFolder thisResp];
%                 if ~exist(theFolder, 'dir'); mkdir(theFolder); end
                
                [G_chan, Channel] = findgroups(blockTable.Channel);
                DV = splitapply(@(x) mean(x, 1), blockTable{:, isDataColu}, G_chan);
                DV_table = array2table(DV, 'VariableNames', dataNames);
                
                thisTable = [table(Channel), DV_table];
                plot_topomap(thisTable, theFolder, timeWindow, lagForVideo);
                
            end
        end
        end
    end
end

end
