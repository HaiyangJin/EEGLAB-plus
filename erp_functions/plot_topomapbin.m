function plot_topomapbin(topovideo_table, onsetCode, respCode, timeWindow)
% save the topo map for the onset events (with response events)
% topovideo_table: the output from output_topovideo
% onsetCode: (double)
% respCode: (double)
% timeWindow: [double, double]

events = unique(topovideo_table.Event);
nEvent = length(events);
if nargin < 2 || isempty(onsetCode)
    onsetCode = 1:nEvent;
end
if nargin < 3
    respCode = [];
end
isBasedResp = ~isempty(respCode);
if nargin < 4 
    timeWindow = [];
end

[~, isDataColu] = xposition(topovideo_table.Properties.VariableNames);
dataNames = topovideo_table.Properties.VariableNames(isDataColu);

%% Save the topo map for each condition

if isBasedResp
    responses = unique(topovideo_table.urResponse);
    nResp = length(responses);
    isEvent = respCode > nResp;
    if sum(isEvent)
        error('There is no corresponding response event for respCode %d.\n',...
            respCode(isEvent));
    end
end

for iEvent = onsetCode
    thisEvent = events{iEvent};
    if ~exist(thisEvent, 'dir'); mkdir(thisEvent); end
    
    thisEventTable = topovideo_table(strcmp(topovideo_table.Event, thisEvent), :);
    
    if isBasedResp
        % if based on responses
        for iResp = respCode
            thisResp = responses{iResp};
                        
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