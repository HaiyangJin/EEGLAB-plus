function trialNum_table = study_trialnumbin(STUDY, subjCode)
% Output the number of trials for each condition for every participant
% Author: Haiyang Jin (hjin317@aucklanduni.ac.nz)

subjCodeAll = {STUDY.datasetinfo.subject};
if nargin < 2
    subjCode = subjCodeAll;
end

isSubj = strcmp(subjCode, subjCodeAll);
if sum(isSubj) == 0
    error('No data are found for the participants.');
end

% create table for saving trial number for each bin
trialNum_table = table;
for iSubj = 1:length(subjCodeAll)
    
    if isSubj(iSubj)
        thisSubj = subjCodeAll{1, iSubj};
        allEvents = {STUDY.datasetinfo(iSubj).trialinfo.type};
        
        [G, Event] = findgroups(allEvents);
        Count = splitapply(@length, allEvents, G);
        
        Event = Event';
        Count = Count';
        SubjCode = repmat({thisSubj}, length(Event), 1);
        
        thisTrial_table = table(SubjCode, Event, Count);
        
        trialNum_table = vertcat(trialNum_table, thisTrial_table); %#ok<AGROW>
        
    end
    
end

end
