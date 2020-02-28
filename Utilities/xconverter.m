function output = xconverter(input, outputformat)
% Convert the time points to table variable names (cell)
% input:  EEG from eeglab (struct)
%         varnames: will be converted to 'num' (cell)
%         num will be converted 'varnames' (double)
% outputformat:
%         'varnames' (varialbe names format (cell)) (default)
%         'num'
% Author: Haiyang Jin (hjin317@aucklanduni.ac.nz)

if isstruct(input)  % check if it is EEG
    
    if nargin < 2
        outputformat = 'varname';
    end
    
    EEG = input;
    
    % info about epoch start and end point
    epochStart = EEG(1).xmin*1000; % -200;
    epochEnd = EEG(1).xmax*1000; % 1499;
    epochLength = EEG.pnts; % (epochEnd-epochStart+1)/lag;
    
    % create the Variable Names for meanRaw_DVs
    lag = 1000 / double(EEG(1).srate);
    pntsEpoch = epochStart:lag:epochEnd;
    
    if strcmp(outputformat, 'num')
        output = pntsEpoch;
    elseif strcmp(outputformat, 'varname')
        output = num2varname(pntsEpoch);
    end
    
    if length(output) ~= epochLength
        error('The time points in the output is not the same as that in EEG!');
    end
    
elseif iscell(input)
    % convert from variable names to numbers
    output = varname2num(input);
elseif isnumeric(input)
    % convert from numbers to variable names
    output = num2varname(input);
end

% function converting numbers to variable names
    function varname = num2varname(num)
        varnameN = arrayfun(@(x) ['N' num2str(abs(x))], num(num < 0), 'UniformOutput', false);
        varnameP = arrayfun(@(x) ['P' num2str(abs(x))], num(num >= 0), 'UniformOutput', false);
        varname = horzcat(varnameN, varnameP);
    end

% function converting variable names to numbers
    function num = varname2num(varname)
        isN = cellfun(@(x) strcmp(x(1), 'N'), varname);
        numN = cellfun(@(x) -str2double(x(2:end)), varname(isN));
        numP = cellfun(@(x) str2double(x(2:end)), varname(~isN));
        num = horzcat(numN, numP);
    end

end