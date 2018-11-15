function  trialTable = eeg_trialdata(EEG, eventResp, isacc)
% EEG: from eeglab
% event(cell): event of the epochs
% eventResp(cell): event of the reponses
% isacc(logical): do you include accuracy data?

%% Default values
if nargin < 1
    error('Not enough inputs for eeg_trialdata!');
elseif nargin < 2
    eventResp = {'RES0' 'RES1'};
    isacc = 1;
elseif nargin < 3
    isacc = 1;
end

% check if there is RT (latnecy) information for the events
isRT = logical(sum(ismember(eventResp, {EEG.event.type})));


%% get information from EEG
nChan = EEG.nbchan;
nPoint = EEG.pnts;
nTrial = EEG.trials;
pointVarNames = erp_pointvarnames(EEG);


%% get the information about each trial
trialVarNames = {'Subjcode', 'Channel', 'Event', 'ACC', 'RT'};

if isRT
    latency = eeg_getepochevent( EEG, eventResp,[],'latency');
    if ~isacc, trialVarNames = trialVarNames(1, [1:3, 5]); end
else
    trialVarNames = trialVarNames(1, 1:3);
    warning('Resposne data are not available.');
end

trialData = zeros(nChan * nTrial, nPoint);
trialInfo = cell(nChan * nTrial, length(trialVarNames));

for iTrial = 1:nTrial
    % xIndex for this trial
    thisTrial = (iTrial-1)*nChan + (1:nChan);
    
    % data for this trial
    trialData(thisTrial, :) = EEG.data(:,:,iTrial);
    
    % channel for this trial
    trialInfo(thisTrial, 2) = {EEG.urchanlocs.labels}';
    
    % Event type for this trial
    thisEventType = EEG.epoch(iTrial).eventtype;
    trialInfo(thisTrial, 3) = thisEventType(1); % Independent Variable
    
    if isacc % if there is accuracy data
        if length(thisEventType) < 3 % Accuracy
            trialInfo(thisTrial, 4) = {NaN};
        else
            trialInfo(thisTrial, 4) = {str2double(thisEventType{3}(end))};
        end
    end
    
    if isRT, trialInfo(thisTrial, 5) = {latency(1, iTrial)}; end% Response times
    
end

trialInfo(:, 1) = {EEG.setname(1:4)}; % save the participant code

% convert trial information and trial data into table
trialInfoTable = cell2table(trialInfo, 'VariableNames', trialVarNames);
trialDataTable = array2table(trialData, 'VariableNames', pointVarNames);

trialTable = horzcat(trialInfoTable, trialDataTable);


end

