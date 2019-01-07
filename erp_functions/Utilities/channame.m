function chanOutput = channame(chanInput)
% Convert the channel number (numeric or string) to channel name (cell)
% Author: Haiyang Jin (hjin317@aucklanduni.ac.nz)

if isnumeric(chanInput) % if input is numeric array
    % convert numbers to cell
    chanOutput = num2names(chanInput);
    
elseif ischar(chanInput) % if input is char array
    % convert one string to a cell
    isSpace = find(chanInput == ' ');
    if isSpace > 0
        cells = strsplit(chanInput, ' ');
        
        chanOutput = cell2names(cells);
        
    elseif strcmp(chanInput(1), 'E')
        chanOutput = {chanInput};
        
    else
        % add the 'E' if it's missing in the string
        chanOutput = {['E' chanInput]};
    end
    
elseif iscell(chanInput) % if input is cell array
    isNum = cellfun(@(x) isnumeric(x), chanInput);
    
    if any(isNum) % if within the cell is numeric
        num = cell2num(chanInput);
        chanOutput = num2names(num);
    else
        isCell = cellfun(@(x) iscell(x), chanInput);
        if any(isCell) % if within the cell is cell
            chanOutput1Cell = cellfun(@(x) x{1}, chanInput(isCell), 'UniformOutput', false);
            chanOutput0Cell = chanInput(~isCell);
            chanOutput = horzcat(chanOutput1Cell, chanOutput0Cell);

        else
            chanOutput = cell2names(chanInput);
        end
    end
     
end

% convert from numeric array to channel names (cell)
    function chanOutput = num2names(chanInput)
        chanOutput = arrayfun(@(x) ['E' num2str(x)], chanInput, 'UniformOutput', false);
    end

% convert from cell array to channel names (cell)
    function chanOutput = cell2names(chanInput)
        isE = cellfun(@(x) 'E' == x(1), chanInput);
        chanOutput1E = cellfun(@(x) x, chanInput(isE), 'UniformOutput', false);
        chanOutput0E = cellfun(@(x) ['E', x], chanInput(~isE), 'UniformOutput', false);
     
        chanOutput = horzcat(chanOutput1E, chanOutput0E);
    end

end