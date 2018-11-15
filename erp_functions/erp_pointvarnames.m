function PointVarNames = erp_pointvarnames(EEG)
% EEG: from eeglab

% get the points
pointEpoch = EEG(1).times;

% the variable names for negative parts
rawVarNameN = arrayfun(@(a) ['N', num2str(a)], abs(pointEpoch(pointEpoch < 0)),...
    'UniformOutput', false);

% the variable anmes for non-negative parts (0 and positive)
rawVarNameP = arrayfun(@(a) ['P', num2str(a)], pointEpoch(pointEpoch >= 0),...
    'UniformOutput', false);

% the variable names for points
PointVarNames = horzcat(rawVarNameN, rawVarNameP);

end