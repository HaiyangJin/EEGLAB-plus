function epoch_table = study_chandata(STUDY, ALLEEG, channel)
% Output the channel data for the current study
% STUDY: from eeglab
% EEG: from eeglab
% channel: The channel whose data you want to output (e.g. [65 90]),
%          default is all the channels. 

if nargin < 2
    error('Not enough input arguments.');
end
if nargin < 3
    channel = {STUDY.changrp.channels};  % by default
end

% check and convert the format of channel if necessary
channel = channame(channel);
nChan = length(channel);  % number of channels

% create a table for saving channel data
epoch_table = table;

for iChan = 1:nChan
    thisChan = channel(iChan); 

    % the erpdata of this channel from the study
    [STUDY, erpdata, erptimes] = std_erpplot(STUDY,ALLEEG,'channels',thisChan,'noplot', 'on');
    chanData = cell2mat(cellfun(@(x) x', erpdata, 'UniformOutput', false));
    
    DV_table = array2table(chanData, 'VariableNames', xconverter(erptimes));
    
    % Independent variables for this section
    SubjCode = {STUDY.design.cell.case}';  % subject code
    Channel = repmat(thisChan, length(SubjCode), 1);  % Channel name 
    Event = cellfun(@(x) x(1), {STUDY.design.cell.value}'); 
    
    IV_table = table(SubjCode, Channel, Event);
    
    thisChanTable = horzcat(IV_table, DV_table);
    
    epoch_table = vertcat(epoch_table, thisChanTable); %#ok<AGROW>
    
end

end