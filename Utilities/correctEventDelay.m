function EEG = correctEventDelay(EEG, delaySize, events)
%Takes the EEG structure and an onset delay (in ms), and moves all triggers
%forward by the onset delay.
%Note: Every trigger gets adjusted which may not be appropriate if different
%events have different latencies eg. responses probably don't have
%the same delay as visual stimuli so if you care about the timing of
%reponses then probably don't use this.

allEvents = {EEG.urevent.type};
if nargin < 3 || isempty(events)
    isOnset = cellfun(@(x) strcmp(x(4), '+'), allEvents);
%     onsetEvents = allEvents(isOnset);
else
    isOnset = cellfun(@(x) ismember(x, events), allEvents);
end 


%adjusts the delay in ms to number of data points, accounting for
%sampling rate
samplingRateFix = 1000/EEG.srate;
adjustedDelaySize = delaySize/samplingRateFix;

%moves trigger latency by required number of data points
for j = 1:size(EEG.event,2)
    if isOnset(j) 
        EEG.event(j).latency = EEG.event(j).latency + adjustedDelaySize;
    end
end

% EEG.event.latency = ([EEG.urevent.latency] + adjustedDelaySize*isOnset)';

fprintf(['The latency of following events were offset by %d.\n'...
    repmat('%s, ', 1, length(events)-1) '%s.\n'], delaySize, events{1, :});

end
