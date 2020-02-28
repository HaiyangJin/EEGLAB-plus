function [coluNum, isDataColu, lagFrame] = xposition(varname, timepoint)
% Author: Haiyang Jin (hjin317@aucklanduni.ac.nz)

if nargin < 2
    timepoint = 'P0';
elseif ~iscell(timepoint) 
    timepoint = xconverter(timepoint);  % convert num 2 varname
end

% which columns are the data
isDataColu = ~cellfun(@(x) isnan(str2double(x(2:end))), varname);

% find the column number for the timepoint
coluNum = find(strcmp(varname, timepoint));

% calculate the lag from varname
positionP0 = find(ismember(varname, 'P0'));
lagFrame = str2double(varname{positionP0 + 1}(2));

end