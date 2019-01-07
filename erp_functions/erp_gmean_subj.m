function gmeanTable = erp_gmean_subj(epoch_table, trialNum_table, chanCent, isCluster)
% epochData_table (table): The raw epoch data should be a table which includes
%                      the information of the subjectCode, experimental
%                      independent variables, the electrode names, and the
%                      epoch data. The variable names for the data should
%                      be like N500, P0, P999 etc...
%                      This can be got from study_chandata.

% elecCent(cell or numeric array): The central electrodes of the two clusters.
%                 Default: (E58(P7) and E96(P8)

%                 component. Each row is for one component, and the first
%                 column is for the name of the component (e.g. 'P1',
%                 'N170'). The second and third columns are the central
%                 electrodes, which, in default, are E58(P7) and E96(P8) for
%                 P1 and N170.

% isCluster(logical): Whether the grand average mean is calculated for the
%                     whole cluster instead of the only electrode. Default
%                     is 1.
%
% Output:
%        grandAvgTable: the grand average for P1 and N170 component

% This script aims to get the grand average data of two cluster for each
% component. In default, it will calculate the time window for P1 and N170
% of the clusters located at E58(P7) and E96(P8).
% Author: Haiyang Jin (hjin317@aucklanduni.ac.nz)

%% Default values
if nargin < 1
    error('Not enough input arguments for erp_grandmean!');
end
if nargin < 2
    isWeighted = 0;
elseif isempty(trialNum_table)
    isWeighted = 0;
else
    isWeighted = 1;  % to calculate the weight mean for every participant
end
if nargin < 3 || isempty(chanCent)
    chanCent = [65 90];
    warning('The default channels (%d and %d) are used for erp_grandmean.\n', ...
        chanCent);
end
if nargin < 4 || isempty(isCluster)
    isCluster = 1;
end

% load the channel information
chanCent = channame(chanCent);
if isCluster
    chanCluster = clusterchan(chanCent)';
else
    chanCluster = chanCent;
end

%% Calculate the grand mean
% if the channel should be included for grand average
isChan = arrayfun(@(x) any(strcmp(x, chanCluster)), epoch_table.Channel); % isX
chan_table = epoch_table(isChan, :);
clear epoch_table

%%% calculate the grand (weighted) mean for every participant %%%
subjCodes = unique(chan_table.SubjCode);
nSubj = length(subjCodes);

[~, isData] = xposition(chan_table.Properties.VariableNames);
gmean_subj = zeros(nSubj, sum(isData));

% calculate the weight of each condition for every participant and then
% calculate the mean
for iSubj = 1:nSubj
    thisSubj = subjCodes{iSubj, 1};
    subjData = chan_table(strcmp(thisSubj, chan_table.SubjCode), :);
    
    if isWeighted
        data_table = join(subjData, trialNum_table);
        trialNum = sum(data_table.Count);
        data_table.Weight = data_table.Count ./ trialNum;
    else
        data_table = subjData;
        data_table.Weight = repmat(1/size(data_table, 1), size(data_table, 1), 1);
    end
    
    [~, isData] = xposition(data_table.Properties.VariableNames);

    gmean_subj(iSubj, :) = sum(data_table{:, isData} .* repmat(data_table.Weight, 1, sum(isData))); % mean of the data

end

% calculate the grand mean for all the participants
grand_data = mean(gmean_subj);

grandData_table = array2table(grand_data, 'VariableNames', ...
    data_table.Properties.VariableNames(isData));

% save the channel names
ChanCent = chanCent;
ChanCluster = chanCluster;
chan_table = table(ChanCent, ChanCluster);

gmeanTable = horzcat(chan_table, grandData_table);

end