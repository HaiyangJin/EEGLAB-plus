function plot_topomapbin(topovideo_table, timeWindow, isBasedResp)

if nargin < 2 
    timeWindow = [];
end
if nargin < 3 || isempty(isBasedResp)
    isBasedResp = 0;
end
    
[~, isDataColu] = xposition(topovideo_table.Properties.VariableNames);
dataNames = topovideo_table.Properties.VariableNames(isDataColu);

%% Save the topo map for each condition
events = unique(topovideo_table.Event);
nEvent = length(events);

if isBasedResp
    resp = unique(topovideo_table.urResponse);
    nResp = length(resp);
end

for iEvent = 1:nEvent
    thisEvent = events{iEvent};
    if ~exist(thisEvent, 'dir'); mkdir(thisEvent); end
    
    thisEventTable = topovideo_table(strcmp(topovideo_table.Event, thisEvent), :);
    
    if isBasedResp
        % if based on responses
        for iResp = 1:nResp
            thisResp = resp{iResp};
                        
            respTable = thisEventTable(strcmp(thisEventTable.urResponse, thisResp), :);
            
            if size(respTable, 1) > 0
                theFolder = [thisEvent filesep thisResp];
                if ~exist(theFolder, 'dir'); mkdir(theFolder); end
                
                [G_chan, Channel] = findgroups(respTable.Channel);
                DV = splitapply(@(x) mean(x, 1), respTable{:, isDataColu}, G_chan);
                DV_table = array2table(DV, 'VariableNames', dataNames);
                
                thisTable = [table(Channel), DV_table];
                plot_topomap(thisTable, theFolder, timeWindow);
                                
            end
            
        end
    else
        % if not based on response
        % calculate the weighted means for every participant at first
        [G, Channel, SubjCode] = findgroups(thisEventTable.Channel, thisEventTable.SubjCode);
%         % weighted mean (method 1)
%         sum_resp = splitapply(@sum, thisEventTable.Count, G);
%         RatioResp = thisEventTable.Count ./ sum_resp(G);
%         DV_resp =  splitapply(@(x) sum(x, 1), thisEventTable{:, isDataColu} .* RatioResp, G);
        % weighted mean (method 2)
        DV_resp = splitapply(@(x, y) sum(x .* y, 1) / sum(y, 1), thisEventTable{:, isDataColu},...
            thisEventTable.Count, G);
        DV_resp_table = array2table(DV_resp, 'VariableNames', dataNames);
        weight_table = [table(Channel, SubjCode), DV_resp_table]; 
                
        % calculate the mean of participants
        [~, isDataColuResp] = xposition(weight_table.Properties.VariableNames);
        dataNames = weight_table.Properties.VariableNames(isDataColuResp);
        [G_chan, Channel] = findgroups(weight_table.Channel);
        DV = splitapply(@(x) mean(x, 1), weight_table{:, isDataColuResp}, G_chan);
        DV_table = array2table(DV, 'VariableNames', dataNames);
        
        thisTable = [table(Channel), DV_table];
        plot_topomap(thisTable, thisEvent, timeWindow);
    end
end


end