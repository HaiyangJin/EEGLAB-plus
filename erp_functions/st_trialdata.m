function  trialEpochTable = st_trialdata(EEG, respEvent, isacc)
% EEG: from eeglab
% event(cell): event of the epochs
% respEvent(cell): event of the reponses
% isacc(logical): do you include accuracy data?

% Only works for individual EEG dataset (not study)

%% Default values
if nargin < 1
    error('Not enough inputs for eeg_trialdata!');
end
if nargin < 2
    %     respEvent = {'RES0' 'RES1'};
    events = unique({EEG.event.type});
    respEvent = events(cellfun(@(x) strcmp(x(1:2), 'RE'), events));
end
if nargin < 3
    isacc = 1;
end

% check if there is RT (latnecy) information for the events
isRT = logical(sum(ismember(respEvent, {EEG.event.type})));


%% get information from EEG
nTrial = EEG.trials;
lagFrame = 1000 / EEG.srate;
varNames = xconverter(EEG.xmin * 1000 : lagFrame : EEG.xmax * 1000);


%% get the information about each trial

if isRT
    latency = eeg_getepochevent(EEG, respEvent,[],'latency');  % the latency of the response events
else
    warning('Resposne data are not available.');
end

% IV
Channel = {EEG.urchanlocs.labels}';
nRow = length(Channel);

trialEpochTableIV = table;
trialEpochTableDV = table;

for iTrial = 1:nTrial
    % DV
    % data for this trial
    thisTrialData = EEG.data(:,:,iTrial);
    
    % IV
    theEvents = EEG.epoch(iTrial).eventtype;
    isOnset = cellfun(@(x) x(end) == '+', theEvents);
    if sum(isOnset) > 1
        warning(['There are more than one onset events in this epoch!\n'...
            'filename: %s'], EEG.setname);
    end
    Event = repmat(theEvents(isOnset), nRow, 1);
    
    
    if isacc % if there is accuracy data
        isResp = cellfun(@(x) strcmp(x(1:2), 'RE'), theEvents);
        if any(isResp) % Accuracy
            respStr = theEvents{isResp};
            Response = repmat({respStr(regexp(respStr, '\d'))}, nRow, 1);  % only get the numbers
        else
            Response = repmat({''}, nRow, 1);
        end
    end
    
    if isRT  % Response times
        RT = repmat(latency(1, iTrial), nRow, 1);
    end
    
    thisIVTable = table(Channel, Event, Response, RT);
    thisDVTable = array2table(thisTrialData, 'VariableNames', varNames);
    
    trialEpochTableIV = vertcat(trialEpochTableIV, thisIVTable); %#ok<AGROW>
    trialEpochTableDV = vertcat(trialEpochTableDV, thisDVTable); %#ok<AGROW>
end

% save the participant code
trialEpochTableIV.SubjCode = repmat({EEG.setname(1:4)}, size(trialEpochTableIV, 1), 1);

trialEpochTable = horzcat(trialEpochTableIV, trialEpochTableDV);


%% get information from EEG (backup)
% nChan = EEG.nbchan;
% nPoint = EEG.pnts;
% 
% 
% %% get the information about each trial
% trialVarNames = {'SubjCode', 'Channel', 'Event', 'Response', 'RT'};
% 
% if isRT
%     latency = eeg_getepochevent( EEG, respEvent,[],'latency');  % the latency of the response events
%     if ~isacc, trialVarNames = trialVarNames(1, [1:3, 5]); end
% else
%     trialVarNames = trialVarNames(1, 1:3);
%     warning('Resposne data are not available.');
% end
% 
% trialData = zeros(nChan * nTrial, nPoint);
% trialInfo = cell(nChan * nTrial, length(trialVarNames));
% 
% 
% for iTrial = 1:nTrial
%     % xIndex for this trial
%     thisTrial = (iTrial-1)*nChan + (1:nChan);
%     
%     % data for this trial
%     trialData(thisTrial, :) = EEG.data(:,:,iTrial);
%     
%     % channel for this trial
%     trialInfo(thisTrial, 2) = {EEG.urchanlocs.labels}';
%     
%     % Event type for this trial
%     theEvents = EEG.epoch(iTrial).eventtype;
%     trialInfo(thisTrial, 3) = theEvents(1); % Independent Variable
%     
%     if isacc % if there is accuracy data
%         isResp = cellfun(@(x) strcmp(x(1:2), 'RE'), theEvents);
%         if any(isResp) % Accuracy
%             respStr = theEvents{isResp};
%             
%             trialInfo(thisTrial, 4) = {regexp(respStr, '\d')};
%         else
%             trialInfo(thisTrial, 4) = {NaN};
%         end
%     end
%     
%     if isRT, trialInfo(thisTrial, 5) = {latency(1, iTrial)}; end% Response times
%     
% end
% 
% trialInfo(:, 1) = {EEG.setname(1:4)}; % save the participant code
% 
% % convert trial information and trial data into table
% trialInfoTable = cell2table(trialInfo, 'VariableNames', trialVarNames);
% trialDataTable = array2table(trialData, 'VariableNames', varNames);
% 
% trialEpochTable = horzcat(trialInfoTable, trialDataTable);

end
