function trialEpochTable = erp_binavg(allTrialEpoch, isBinAvg, isReject)

if nargin < 2 || isempty(isBinAvg)
    isBinAvg = 0;
end
if nargin < 3 || isempty(isReject)
    isReject = 0;
end


%% remove the bad trials
if isReject
    allTrialEpochRej = allTrialEpoch(~allTrialEpoch.Reject, :);
else
    allTrialEpochRej = allTrialEpoch;
end

%% save bin averaged data
if isBinAvg
    [~, isDataColu] = xposition(allTrialEpochRej.Properties.VariableNames);
    
    [G, Channel, Event, urResponse, SubjCode] = findgroups(allTrialEpochRej.Channel, allTrialEpochRej.Event, ...
        allTrialEpochRej.urResponse, allTrialEpochRej.SubjCode);
    
    DV = splitapply(@(x) mean(x, 1), allTrialEpochRej{:, isDataColu}, G);
    Count = splitapply(@(x) size(x, 1), allTrialEpochRej.P0, G);
    
    IV_table = table(Channel, Event, urResponse, SubjCode, Count);
    DV_table = array2table(DV, 'VariableNames', allTrialEpochRej.Properties.VariableNames(isDataColu));
    
    trialEpochTable = [IV_table, DV_table];
else
    trialEpochTable = allTrialEpochRej;
end