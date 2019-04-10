function binEpochTable = erp_binepochtable(epoch_table, gwindowTable, isCluster)
% This function reads epoch_table for all channels and output the mean of
% the cluster for each hemisphere for every bin.
% (averaged epoch data for every condition) The data usually got from the STUDY in eeglab  

% Output:
% binEpochTable: epoch table for every condition

% Input:
% gwindowTable: the grand time window table
% isCluster: 

if nargin < 3
    isCluster = 1;
end

%% channel information
centChan = gwindowTable.ChanCent;
if isCluster
    peakChannel = cellfun(@clusterchan, centChan, 'UniformOutput', false);
else
    peakChannel = centChan;
end

%% calculate the average peak for clusters
LeftRight = {'Left', 'Right'};

nComp = size(gwindowTable, 1);
for iComp = 1:nComp
    thisComp = gwindowTable{iComp, 'Component'}{1};
    
    for iLR = 1:2 % calculate the peak for left and right hemisphere separately
        LR = LeftRight{iLR};
        theClusterChan = peakChannel{iComp, iLR};
        thisCentChan = centChan{iComp, iLR};
        
        % channels
        isClusterChan = ismember(epoch_table.Channel, theClusterChan);
        dataCluster = epoch_table(isClusterChan, :);
        
        % get information form dataCluster
        coluNames = dataCluster.Properties.VariableNames;
        [~, isDataColu] = xposition(coluNames);
        dataNames = coluNames(isDataColu);
        
        % split the data into serveral groups and calculate the group mean
        [G, SubjCode, Event] = findgroups(dataCluster.SubjCode, dataCluster.Event);
        
        % create an empty table
        dataPeakOut = table;
        for i = 1:length(dataNames)
            dataPeakOut.(dataNames{i}) = splitapply(@(x) mean(x, 1), dataCluster.(dataNames{i}), G);
        end
        
        EventLR = cellfun(@(c) [LR(1), c], Event, 'UniformOutput', false);
        nRow = size(dataPeakOut, 1);
        ChanCent = repmat({thisCentChan}, nRow, 1);
        ChanCluster = repmat({theClusterChan}, nRow, 1);
        Hemisphere = repmat({LR}, nRow, 1);
        Component = repmat({thisComp}, nRow, 1);
        isCluster = ones(nRow, 1);
        
        % create the table
        thisPeakOut = horzcat(table(SubjCode, Component, ChanCent, ChanCluster, EventLR, Hemisphere, isCluster), dataPeakOut);
        
        if iLR == 1
            % save the output data for left hemisphere
            LPeakOut = thisPeakOut;
        elseif iLR ==2
            % save the output data for this component
            thisCompPeakOut = vertcat(LPeakOut, thisPeakOut);
        end
        
    end
    
    if iComp == 1
        compPeakOut = thisCompPeakOut;
    else
        compPeakOut = vertcat(compPeakOut, thisCompPeakOut); %#ok<AGROW>
    end
end

binEpochTable = compPeakOut;