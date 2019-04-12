function binerp_table = output_binerp(binEpochTable, onsetEvents, subjCode, isBasedResp, isWeightedMean, isCSV)
% This function aggreagte the epochs for each bin and output the table for
% plotting ERP (lines) for every conditions
%
% Author: Haiyang Jin

if nargin < 2 || isempty(onsetEvents)
    onsetEvents = unique(binEpochTable.Event);
end
nOnset = length(onsetEvents);
fprintf(['The onset events of this analysis are (%d in total): \n', ...
    repmat('%s ', 1, nOnset), '\n'], nOnset, onsetEvents{:});

if nargin < 3 || isempty(subjCode)
    subjCode = unique(binEpochTable.SubjCode);
end
nSubj = length(subjCode);
fprintf(['The participants of this analysis are (%d in total): \n', ...
    repmat('%s ', 1, nSubj), '\n'], nSubj, subjCode{:});

if nargin < 4 || isempty(isBasedResp)
    isBasedResp = 0;
end
Resp = {'AllResp', 'Resp'};

if nargin < 5 || isempty(isWeightedMean)
    isWeightedMean = 0;
end
Weighted = {'Avg', 'Weighted'};

if nargin < 6 || isempty(isCSV)
    isCSV = 1;
end

[~, isDataColu] = xposition(binEpochTable.Properties.VariableNames);


if isWeightedMean  % for Participants
    if isBasedResp
        % if weighed mean and based on responses
        [G, Component, Hemisphere, Event, Response] = findgroups(binEpochTable.Component, ...
            binEpochTable.Hemisphere, binEpochTable.Event, binEpochTable.Response);
        IV_table = table(Component, Hemisphere, Event, Response);
    else
        % if weighted mean but not based on responses
        [G, Component, Hemisphere, Event] = findgroups(binEpochTable.Component, ...
            binEpochTable.Hemisphere, binEpochTable.Event);
        IV_table = table(Component, Hemisphere, Event);
    end
    
    theTable = binEpochTable;
else
    if isBasedResp
        % if not weighted mean but based on response
        [G_subj, Component, Hemisphere, Event, Response, SubjCode] = findgroups(binEpochTable.Component, ...
            binEpochTable.Hemisphere, binEpochTable.Event, binEpochTable.Response, ...
            binEpochTable.SubjCode);
        IV_table_subj = table(Component, Hemisphere, Event, Response, SubjCode);
    else 
        % if not weighted mean and not based on response
        [G_subj, Component, Hemisphere, Event, SubjCode] = findgroups(binEpochTable.Component, ...
            binEpochTable.Hemisphere, binEpochTable.Event, binEpochTable.SubjCode);
        IV_table_subj = table(Component, Hemisphere, Event, SubjCode);
    end
    
    DV_subj = splitapply(@(x) mean(x, 1), binEpochTable{:, isDataColu}, G_subj);
    DV_subj_table = array2table(DV_subj, 'VariableNames', binEpochTable.Properties.VariableNames(isDataColu));
    
    subj_table = horzcat(IV_table_subj, DV_subj_table);
    
    if isBasedResp
        % if not weighted mean but based on response
        [G, Component, Hemisphere, Event, Response] = findgroups(subj_table.Component, ...
            subj_table.Hemisphere, subj_table.Event, subj_table.Response);
        IV_table = table(Component, Hemisphere, Event, Response);
    else
        [G, Component, Hemisphere, Event] = findgroups(subj_table.Component, ...
            subj_table.Hemisphere, subj_table.Event);
        IV_table = table(Component, Hemisphere, Event);
    end
    
    [~, isDataColu] = xposition(subj_table.Properties.VariableNames);
    theTable = subj_table;
end

DV = splitapply(@(x) mean(x, 1), theTable{:, isDataColu}, G);
DV_table = array2table(DV, 'VariableNames', theTable.Properties.VariableNames(isDataColu));

binerp_table = horzcat(IV_table, DV_table);

fn_binerp = ['BinERP_' Resp{isBasedResp + 1} '_' Weighted{isWeightedMean + 1} '.csv'];

if isCSV
    writetable(binerp_table, fn_binerp);
end

end