function peakOutTable = erp_avgpeakoutput(rawEpochTable, timeWindowTable, isBinPeak)
% rawEpoch(table): The raw epoch data should be a table which includes
%                      the information of the subjectCode, experimental 
%                      independent variables, the electrode names, and the 
%                      epoch data. The variable names for the data should 
%                      be like N500, P0, P999 etc...
% timeWindowTable(table): A table for the time window information.
%                         Generated by erp_timewindow function.
% isTrialPeak(logicl): Whether calculate the peak value for each trial. The
%                      defaul is 0 (no).

% This script aims to calculate the peak amplitude for each sujbect, each 
% electrode cluster, each condition each hemisphere and even for each trial. 
% Author: Haiyang Jin (hjin317@aucklanduni.ac.nz)

%% Default values
if nargin < 2
    error('Not enough inputs for erp_avgpeakoutput!');
elseif nargin < 3
    isBinPeak = 0;
end

%% Get information from rawEpoch and timeWindowTable
orderP0 = find(ismember(rawEpochTable.Properties.VariableNames, {'P0'}));
rawEpochPosi = rawEpochTable(:, orderP0 + 1: end);
isDataColumn = varfun(@isnumeric, rawEpochTable, 'output', 'uniform');

nComp = size(timeWindowTable, 1);

LeftRight = {'Left', 'Right'};

%% calculate the peak values for each electrode, participant, condition (across the trials)
trialPeakTable = rawEpochTable(:, ~isDataColumn);

for iComp = 1: nComp
    thisComp = timeWindowTable{iComp, 'Component'}{1};
    
    % window for this component
    thisWindowStart = timeWindowTable{iComp, 'StartFrame'};
    thisWindowEnd = timeWindowTable{iComp, 'EndFrame'};
    
    % data for this window
    thisCompData = rawEpochPosi{:, thisWindowStart : thisWindowEnd};
    
    % mean data of this window
    thisCompPeak = mean(thisCompData, 2);

    trialPeakTable.(thisComp) = thisCompPeak;
end

if isBinPeak
    peakOutTable = trialPeakTable;
    return;
end

%% calculate the average peak for clusters

for iComp = 1:nComp
    thisComp = timeWindowTable{iComp, 'Component'}{1};

    for iLR = 1:2 % calculate the peak for left and right hemisphere separately
        LR = LeftRight{iLR};
        LRElec = [LR, 'Electrodes'];
        theClusterElec = timeWindowTable.(LRElec)(iComp, :);
        
        isClusterElec = ismember(trialPeakTable.electrode, theClusterElec);
        dataCluster = trialPeakTable(isClusterElec, :);
        
        % split the data into serveral groups and calculate the group mean
        [G, participantNum, label] = findgroups(dataCluster.ParticipantNum, dataCluster.label);
        thisMeanPeak = splitapply(@mean, dataCluster.(thisComp), G);
        labelLR = cellfun(@(c) [LR(1), c], label, 'UniformOutput', false);
        CentralChan = repmat(theClusterElec{1,1}, length(thisMeanPeak), 1);
        
        % create the table 
        thisPeakOut = table(participantNum, CentralChan, labelLR, thisMeanPeak);
        thisPeakOut.Properties.VariableNames{'CentralChan'} = [thisComp '_CentralChan'];
        thisPeakOut.Properties.VariableNames{'thisMeanPeak'} = thisComp;
        
        if iLR == 1
            % save the output data for left hemisphere
            LPeakOut = thisPeakOut;
        elseif iLR ==2
            % save the output data for this component
            thisCompPeakOut = vertcat(LPeakOut, thisPeakOut);
        end
        
    end
    
    if iComp == 1
        compPeakOut = thisCompPeakOut;
    else
        compPeakOut = join(compPeakOut, thisCompPeakOut);
    end
end

peakOutTable = compPeakOut;

end