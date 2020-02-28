% ParticipantNum
if strcmp(experimentNum, '1')
    subjCodes = 1:21; 
elseif strcmp(experimentNum, '2')
    subjCodes = 0:19;
elseif strcmp(experimentNum, '3')
    subjCodes = 1:20;
elseif strcmp(experimentNum, '4')
    subjCodes = 1:30;
end
nSubj = length(subjCodes);

