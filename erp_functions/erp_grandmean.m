function [grandAvgTable, allEpoch] = erp_grandmean(rawEpochTable, chanComp, isCluster)
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
%
% Output:
%        grandAvgTable: the grand average for P1 and N170 component
%        allEpoch1: the epoch data of P1 for each bin
%        allEpoch2: the epoch data of N170 for each bin

% This script aims to get the grand average data of two cluster for each
% component. In default, it will calculate the time window for P1 and N170
% of the clusters located at E58(P7) and E96(P8).
% Author: Haiyang Jin (hjin317@aucklanduni.ac.nz)

%% Default values
if nargin < 1
    error('Not enough inputs for erp_grandmean!');
elseif nargin < 2
    chanComp = {'P1', 'E65', 'E90';
                'N170', 'E58', 'E96'};
    isCluster = 1;
elseif nargin < 3
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
     thisChanCent = chanComp(iComp,2:3);
     if isCluster % channels for the two clusters
         thisChanComp = chanCluster(ismember(chanCluster(:,1), thisChanCent),:); %#ok<NODEF>
         leftChan = thisChanComp(1,:);
         rightChan = thisChanComp(2,:);
         chanCompVec = reshape(thisChanComp, 1,[]);
     else % the only two channels
         chanCompVec = chanComp(iComp,2:3);
         leftChan = chanCompVec(1,1);
         rightChan = chanCompVec(1,2);
     end
     
     xEpochData = ismember(rawEpochTable{:, 'Channel'}, chanCompVec); % channel
     
     % get the grand mean data for this component
     theEpochData = rawEpochTable{xEpochData, isDataColumn};
     meanThisComp = mean(theEpochData);
     
     % save the component name and the grand mean data
     DVComp(iComp, :) = meanThisComp;
     IVCompStr(iComp).Component = chanComp(iComp, 1); % name of this component
     IVCompStr(iComp).centralChannel = thisChanCent;
     IVCompStr(iComp).isCluster = isCluster;
     IVCompStr(iComp).LeftChannels = leftChan;
     IVCompStr(iComp).RightChannels = rightChan;
     
     %%%% save the epoch data for the component channels %%%%
     % add the Component variable
     Component = cell2table(repmat(chanComp(iComp,1), sum(xEpochData), 1), ...
         'VariableNames', {'Component'});
     theEpochComponent = [rawEpochTable(xEpochData, :), Component];
     
     % add the left or right hemisphere variable
     isLeft = ismember(theEpochComponent{:, 'Channel'}, leftChan);
     isRight = ismember(theEpochComponent{:, 'Channel'}, rightChan);
     LRChannel = cell(sum(xEpochData), 1);
     LRChannel(isLeft, :) = {'Left'};
     LRChannel(isRight, :) = {'Right'};
     LR = cell2table(LRChannel, 'VariableNames', {'Hemisphere'});
     theEpoch = [theEpochComponent, LR];

     
     if iComp == 1
         allEpoch = theEpoch;
     else
         allEpoch = [allEpoch; theEpoch];
     end
     
  
 end
 % reorder the columns of the table. Move the independent variables to front 
 allEpoch = [allEpoch(:, 1:3) allEpoch(:, end-1:end) allEpoch(:, 4:end-2)]; 
 
 meanCompTable = array2table(DVComp, 'VariableNames', ...
     rawEpochTable.Properties.VariableNames(isDataColumn));
 nameCompTable = struct2table(IVCompStr);
 
 grandAvgTable = horzcat(nameCompTable, meanCompTable);
 

end