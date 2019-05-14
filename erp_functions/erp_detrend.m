function trialEpochDetrend = erp_detrend(trialEpochTable, startTime, endTime)
% detrend the epoch data from certain start point to certian end point
% trialEpochTable: epoch data table from st_trialdata, allTrialTable, or
%                  similar
% startTime: start time point (double)
% endTime: end time point (double)

if nargin < 2
    startTime = -200;
end
if nargin < 3
    endTime = 800;
end

[startCol, isDataColu] = xposition(trialEpochTable.Properties.VariableNames, startTime);
endCol = xposition(trialEpochTable.Properties.VariableNames, endTime);

% DVs (the data)
toBeDetrend = trialEpochTable(:, startCol:endCol);

% detrend the data
nRowData = size(toBeDetrend, 1);
detrendedData = zeros(nRowData, size(toBeDetrend, 2));
        
for iRowData = 1 : nRowData
    detrendedData(iRowData, :) = detrend(toBeDetrend{iRowData, :});
end

detrend_DV = array2table(detrendedData, 'VariableNames', toBeDetrend.Properties.VariableNames);


% IVs to be saved
detrend_IV = trialEpochTable(:, ~isDataColu);

trialEpochDetrend = [detrend_IV, detrend_DV];

sprintf('Epoch data are detrended from %d to %d...', startTime, endTime);

end


