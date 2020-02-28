function numTable = ureventnumber(EEG, events)

% events (cell)

allEvents = {EEG.urevent.type};
if naring < 2 || isempty(events)
    events = unique(allEvents);
else
    isNot = ~ismember(events, allEvents);
    
    if any(isNot)
        error('Cannot find the event ''%s'' in the EEG data!\n', events{isNot}); 
    end
end

Ncell = cellfun(@(x) sum(strcmp(x, allEvents)), events, 'UniformOutput', false);

numCell = [events; Ncell];

for tmpstr = {'+', '-'}
    events = cellfun(@(x) strrep(x, tmpstr{1}, ''), events, 'UniformOutput', false);
end

numTable = cell2table(numCell, 'VariableNames', events);