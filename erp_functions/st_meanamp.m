function stmeanampTable = st_meanamp(trialTable, checkWindowTable, compName)
% calculate the mean amplitude of the single trial

% If the checkWindowTable is a grand time window, the mean amplitude will
% be calculated with the same grand time window. If the checkWidowTable is
% the time window table for different conditions, the mean amplitude will
% be calculated with differernt time windows for different conditions (but
% the time window for all the trials in the same condition will be the
% same).

method = 2; % mean amplitude

isgwindow = length(checkWindowTable{1, 'ChanCent'}) == 2;

% get the checkWindow
if isgwindow  % is gwindowTable
    isComp = strcmp(checkWindowTable.Component, compName);
    checkWindow = checkWindowTable{isComp, {'StartFrame', 'EndFrame'}};
else
    isComp = strcmp(compName, checkWindowTable.Component);
    tmpEvents = cellfun(@(x, y) strrep(x, y(1), ''), checkWindowTable.EventLR, ...
        checkWindowTable.Hemisphere, 'UniformOutput', false);
    isEvent = strcmp(unique(trialTable.Event), tmpEvents); 
    
    thisWindowTable = checkWindowTable(logical(isComp .* isEvent), :);
end


nRow = size(trialTable, 1);
clear stamp  % single trial amplitude
for iRow = 1:nRow
    % this row table
    thisEpoch = trialTable(iRow, :);
    
    if ~isgwindow
        isSubjCode = strcmp(thisEpoch.SubjCode, thisWindowTable.SubjCode);
        isChannel = strcmp(thisEpoch.Channel, thisWindowTable.ChanCent);
        
        isX = logical(isSubjCode .* isChannel);

        checkWindow = thisWindowTable{isX, {'StartFrame', 'EndFrame'}};
    end
    
    stamp(iRow) = erp_window(thisEpoch, checkWindow, compName, method); %#ok<AGROW>
    
end


% combine the mean amplitude and trial epoch table
[~, isDataColu] = xposition(trialTable.Properties.VariableNames);

meanAmpTable = struct2table(stamp);

isDuplicated = ismember(meanAmpTable.Properties.VariableNames, ...
    trialTable.Properties.VariableNames(~isDataColu));

stmeanampTable = horzcat(trialTable(:, ~isDataColu), meanAmpTable(:, ~isDuplicated));


end