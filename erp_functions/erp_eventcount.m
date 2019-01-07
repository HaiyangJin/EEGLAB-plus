function erp_eventcount(ALLEEG)
% This function output the number of the events for every participant.

nEEG = size(ALLEEG, 2);  % number of EEG
events = unique({ALLEEG(1).event.type}); % all the events
isOn = cellfun(@(x) logical(sum(x=='+')), events);  
events_on = events(isOn);  % events for onset

numEventCell = cell(nEEG, length(events_on));
subjCell = cell(nEEG, 1);

for iEEG = 1:nEEG
        
    % name of this participant
    subjCell(iEEG, 1) = {ALLEEG(iEEG).setname(1:4)};
    
    % the number of each events for this participant
    theseEvent = {ALLEEG(iEEG).event.type};
    numEventCell(iEEG, :) = cellfun(@(x) sum(strcmp(theseEvent, x)), events_on, 'UniformOutput', false);

end

variableNames = cellfun(@(x) erase(x, "+"), events_on, 'UniformOutput', false);  % remove "+" in variable names

numEventTable = cell2table([subjCell, numEventCell], 'VariableNames', [{'SubjCode'}, variableNames]); % convert to table

% Save the file
expName = ['20' ALLEEG(1).setname(2)];
filename = [expName '_EventNumber.csv'];
writetable(numEventTable, filename);



