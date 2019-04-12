function urTrialInfo = st_urtrialinfo(EEG, onsetEvent, respEvent, blockEvent)
% This function tries to calculate the trial number for the data of each participant.
% Trial numbers are mainly calculated based on EEG.urevent (The raw event
% records) and EEG.event.urevent (event records for the remaining epoch)
%
% Input: EEG (for single participant)
%        onsetEvent: all the onset events
%
% Output: a table with following columns:
%         Urevent: the raw number of every onset event
%         TrialNumber: the trial number
%
% Author: Haiyang Jin (https://haiyangjin.github.io/)

events = unique({EEG.urevent.type}); % all the events for this data

if nargin < 2 || isempty(onsetEvent)
    onsetEvent = events(cellfun(@(x) strcmp(x(end), '+'), events));
end
if nargin < 3 || isempty(respEvent)
    respEvent = events(cellfun(@(x) strcmp(x(1:2), 'RE'), events));
end
if nargin < 4 || isempty(blockEvent)
    blockEvent = events(cellfun(@(x) strcmp(x(1:3), 'blo'), events));
end

% check if there is RT (latnecy) information for the events
isResp = logical(sum(ismember(respEvent, events)));
if ~isResp
    warning('No response events are found.');
end

% check if there is block information for the events
isBlock = logical(sum(ismember(blockEvent, events)));
if ~isBlock
    warning('No block events are found.');
end

% convert the urevent structure to table
rawT = struct2table(EEG.urevent);

rawT.Urevent = (1:size(rawT, 1))';  % add the row number (urevnet) to the table
rawT.IsOnset = ismember(rawT.type, onsetEvent);

% calculate the trial number
nRows = size(rawT, 1);
trialNumber = zeros(nRows, 0);
for iRow = 1:nRows
    trialNumber(iRow, 1) = sum([rawT(1:iRow,:).IsOnset]);
end
rawT.TrialNumber = trialNumber;

trial = struct;
for iTrial = 1:max(trialNumber)
    
    thisTrialT = rawT(iTrial == [rawT.TrialNumber], :); 
    theEvents = thisTrialT.type;
    
    isTempOnset = ismember(theEvents, onsetEvent);
    trial(iTrial).Urevent = thisTrialT{isTempOnset, 'Urevent'};
    trial(iTrial).Event = theEvents{isTempOnset};
    trial(iTrial).TrialNumber = iTrial;
    
    if isResp
        isTempResp = ismember(theEvents, respEvent);
        if sum(isTempResp) > 1
            warning('There are %d response events for this trial %d.', sum(isTempResp), iTrial);
            allresp = find(isTempResp);
            isTempResp = zeros(length(theEvents), 1);
            isTempResp(allresp(1)) = 1;
            isTempResp = logical(isTempResp);
        end
        trial(iTrial).urResponse = theEvents{isTempResp};
        trial(iTrial).urLatency = thisTrialT{isTempResp, 'latency'} - ...
            thisTrialT{isTempOnset, 'latency'};
        
        unitSample = 1000 ./ EEG.srate;
        trial(iTrial).urRT = trial(iTrial).urLatency * unitSample;
    end
    
    if isBlock
        isTempBlock = ismember(theEvents, blockEvent);
        if any(isTempBlock)
            trial(iTrial).urBlock = theEvents{isTempBlock};
        else
            trial(iTrial).urBlock = {''};
        end
    end
end

% convert structure to table
urTrialInfo = struct2table(trial);

end