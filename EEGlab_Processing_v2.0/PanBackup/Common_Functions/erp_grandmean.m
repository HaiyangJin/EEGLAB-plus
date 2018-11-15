function grandAvgTable = erp_grandmean(rawEpochTable, chanComp, isCluster)
% rawMeanEpoch(table): The raw epoch data should be a table which includes
%                      the information of the subjectCode, experimental 
%                      independent variables, the electrode names, and the 
%                      epoch data. The variable names for the data should 
%                      be like N500, P0, P999 etc...
% elecCent(cell): The central electrodes of the two clusters for every
%                 component. Each row is for one component, and the first
%                 column is for the name of the component (e.g. 'P1',
%                 'N170'). The second and third columns are the central
%                 electrodes, which, in default, are E58(P7) and E96(P8) for
%                 P1 and N170.
% isCluster(logical): Whether the grand average mean is calculated for the
%                     whole cluster instead of the only electrode. Default
%                     is 1.

% This script aims to get the grand average data of two cluster for each
% component. In default, it will calculate the time window for P1 and N170
% of the clusters located at E58(P7) and E96(P8).
% Author: Haiyang Jin (hjin317@aucklanduni.ac.nz)

%% Default values
if nargin < 1
    error('Not enough inputs for erp_grandmean!');
elseif nargin < 2
    chanComp = {'P1', 'E58', 'E96';
                'N170', 'E58', 'E96'};
    isCluster = 1;
elseif nargin <3
    isCluster = 1;
end

% load the channel information
channelFiles;
 
 %% Calculate the grand mean for each component
 % erp components
 nComp = size(chanComp, 1); % number of components
 
 % create a matrix for the grand mean of each component
 isDataColumn = varfun(@isnumeric, rawEpochTable, 'output', 'uniform');
 DVComp = zeros(nComp, sum(isDataColumn));
 IVCompStr = struct;
 
 for iComp = 1:nComp
     thisChanCent = chanCent(iComp,2:3);
     if isCluster % channels for the two clusters
         chanComp = chanCluster(ismember(chanCluster(:,1),thisChanCent),:);
         leftChan = chanComp(1,:);
         rightChan = chanComp(2,:);
         chanCompVec = reshape(chanComp, 1,[]);
     else % the only two channels
         chanCompVec = chanComp(iComp,2:3);
         leftChan = chanCompVec(1,1);
         rightChan = chanCompVec(1,2);
     end
     
     xEpochData = ismember(rawEpochTable{:, 'channel'}, chanCompVec);
     theEpochData = rawEpochTable{xEpochData, isDataColumn};
     meanThisComp = mean(theEpochData);
     
     % save the component name and the grand mean data
     DVComp(iComp, :) = meanThisComp;
     IVCompStr(iComp).Component = chanComp(iComp, 1); % name of this component
     IVCompStr(iComp).centralChannel = thischanComp;
     IVCompStr(iComp).isCluster = isCluster;
     IVCompStr(iComp).LeftChannels = leftChan;
     IVCompStr(iComp).RightChannels = rightChan;
 end
 
 meanCompTable = array2table(DVComp, 'VariableNames', ...
     rawEpochTable.Properties.VariableNames(isDataColumn));
 nameCompTable = struct2table(IVCompStr);
 
 grandAvgTable = horzcat(nameCompTable, meanCompTable);

end