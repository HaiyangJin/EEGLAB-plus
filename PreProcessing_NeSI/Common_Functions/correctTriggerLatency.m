function EEG = correctTriggerLatency(EEG,delaySize)
%Takes the EEG structure and an onset delay (in ms), and moves all triggers
%forward by the onset delay.
%Note: Every trigger gets adjusted which may not be appropriate if different
%events have different latencies eg. responses probably don't have
%the same delay as visual stimuli so if you care about the timing of
%reponses then probably don't use this.

%adjusts the delay in ms to number of data points, accounting for
%sampling rate
samplingRateFix = 1000/EEG.srate;
adjustedDelaySize = delaySize/samplingRateFix;

%moves trigger latency by required number of data points
for j = 1:size(EEG.event,2)
    EEG.event(j).latency = EEG.event(j).latency + adjustedDelaySize;
end