 function [clusterData, peakValues, timeWindows] = erp_getpeak(studyPeak, nAvgTimepoint, isCluster)
 % General information
 % introduction: This command tried to extract the peak values for P1
 % and N170. It applies to EGI 128 electrodes cap. 
 % author: Haiyang Jin (hjin317@aucklanduni.ac.nz)
 
 %% Default values
 % the default is run for the cluster
 if nargin <1
     error('Not enough inputs!');
 elseif nargin < 2
     nAvgTimepoint = 9; % how many time points are averaged for the time window
	 isCluster = 1;
 elseif nargin <3
     isCluster = 1;
 end
 
 % the first value of each row is the central electrode, and the rest six
 % are the surrouding electrodes
 elecCluster = [65 58 59 66 70 69 64; % PO7
     90 96 91 84 83 89 95; % PO8
     58 51 59 65 64 57 50; % P7
     96 97 91 90 95 100 101; % P8
     64 57 58 65 69 68 63; % P9
     95 100 99 94 89 90 96]; % P10
 
 %% Info about electrodes and assumed time window
 % the assumed window size 
 windowSize = studyPeak.windows;
 Components = windowSize.Properties.RowNames;
 numComp = length(Components);
 
 % raw mean data
 rawMean = studyPeak.rawMean;
 subjNames = unique(rawMean{:, 'ParticipantNum'});
 numSubj = length(subjNames);
 condNames = unique(rawMean{:, 'label'});
 numCond = length(condNames);
 
 % get the central electrodes
 elecCentral = studyPeak.elec;
 
 % get the electrode(s) for this analysis
 electrodes = cell(size(elecCentral, 1), size(elecCentral, 2));
 for iComp = 1:size(elecCentral, 1)
     for iH = 1:size(elecCentral, 2)
         % the (central) electrode
         tempCent = elecCentral(iComp, iH);
         if isCluster
             tempElec = elecCluster(tempCent == elecCluster(:,1),:);
             tempElec = arrayfun(@(x) ['E', num2str(x)], tempElec, 'UniformOutput', false);
             electrodes(iComp, iH) = {tempElec};
         else
             electrodes(iComp, iH) = {tempCent};
         end
     end
 end
 clear iCom
 clear iH
 clear tempElec
 
 % How many time points should be averaged for the peak values
 nFrame = nAvgTimepoint;
 if ~logical(mod(nFrame, 2)), nFrame = nFrame - 1; end
 nSideFrame = (nFrame - 1)/2; % how many time points for one side
 
 %% Get the data for these electrodes (by each condition and each participant)
 % create the cluster table
 xClusterData = numComp * 2 * numSubj * numCond;
 yClusterData = length(rawMean.Properties.VariableNames);
 clusterData = cell2table(cell(xClusterData, yClusterData));
 clusterData.Properties.VariableNames = rawMean.Properties.VariableNames;
 
 clusterComp = cell(xClusterData, 1);
 
 
 LR = 'LR';
 n = 1;
  for iComp = 1:numComp
     % the name of this component
     thisComp = Components{iComp, 1};
     
     % left or right hemispheric electrodes
     for iLR = 1:2
         tempCent = electrodes{iComp, iLR}(1);
         
         if isCluster
             tempElecs = electrodes{iComp, iLR};
         else
             tempElecs = tempCent;
         end
         % logic for hemisphere
         isElec = ismember(rawMean{:,'electrode'}, tempElecs);
         
         % for every subjects
         for iSubj = 1:numSubj
             thisSubj = subjNames(iSubj);
             isSubj = ismember(rawMean{:,'ParticipantNum'}, thisSubj);
             
             for iCond = 1:numCond
                 thisCond = condNames(iCond);
                 isCond = ismember(rawMean{:,'label'}, thisCond);
                 
                 % get the
                 logicAll = logical(isElec .* isSubj .* isCond);
                 tempData = rawMean(logicAll, :);
                 
                 nN500 = find(ismember(rawMean.Properties.VariableNames, 'N500'));
                 tempAvg = mean(tempData{:, nN500:end});
                 
                 % save the data into ClusterData
                 clusterData{n, :} = horzcat({thisSubj, [LR(iLR), '_', tempCent{1}], thisCond}, num2cell(tempAvg));
                 
%                  clusterData{n, 'ParticipantNum'} = thisSubj;
%                  [~, id] = lastwarn; warning('off', id);
%                  clusterData{n, 'electrode'} = {[LR(iLR), '_', tempCent{1}]};
%                  [~, id] = lastwarn; warning('off', id);
%                  clusterData{n, 'label'} = thisCond;
%                  [~, id] = lastwarn; warning('off', id);
%                  clusterData{n, nN500:end} = num2cell(tempAvg);
                 
                 % save the componet name
                 clusterComp{n, 1} = thisComp;
                 
                 n = n + 1;
             end
         end
     end
 end
 clear n
 clear iComp
 clear thisComp
 
 clusterComp = cell2table(clusterComp, 'VariableNames', {'Component'});
 clusterData = horzcat(clusterComp, clusterData); % output 1

 %% calculate the time window for each components
 % get the sample rate of this data set
 nP4 = find(ismember(clusterData.Properties.VariableNames, 'P4'));
 nPnext = nP4 + 1;
 nextTimepoint = clusterData.Properties.VariableNames{nPnext}(2:end);
 perFrame = str2double(nextTimepoint) - 4;
 srate = 1000 / perFrame;
 n = 1;
 nFail = 0;
nn = 0;
xxx = zeros(10000,3);

 for iComp = 1:numComp
     % the name of this component
     thisComp = Components{iComp, 1};
     
     % EEG data from 0 to the end for this component
     compData = clusterData(ismember(clusterData{:,'Component'}, thisComp), nP4:end);
     numX = size(compData, 1); % number of rows for this component
     
     % assumed time window for this component
     updateStartFrame = studyPeak.windows{thisComp, 'windowStartFrame'}{1};
     updateEndFrame = studyPeak.windows{thisComp, 'windowEndFrame'}{1};
     
     peakNotInWindow = 1;
     while peakNotInWindow % if some data points are out of the time window, restart
         % create a table to save the peak value for this component
         peakVar = {'Amplitude', 'Latency'};
         tempPeakTable = cell2table(cell(numX, length(peakVar)));
         tempPeakTable.Properties.VariableNames = peakVar;
         
         thisStartFrame = updateStartFrame;
         thisEndFrame = updateEndFrame;

         % check if the peak (range) is in this window (every subj, condition)
         for iX = 1:numX
             thisCompTable = compData(iX, thisStartFrame:thisEndFrame);
             thisCompData = cell2mat(thisCompTable{1,:});
             nWindowSize = size(thisCompData, 2);
             
             % get the peak value and the frame
             if strcmp(thisComp(1), 'P')
                 [~, peakFrame] = max(thisCompData);
             elseif strcmp(thisComp(1), 'N')
                 [~, peakFrame] = min(thisCompData);
             end
             
             % check if the peak window covers the peak value points
             if peakFrame - nSideFrame < 1
                 updateStartFrame = updateStartFrame - 1;
                 restart = 1;
             elseif peakFrame + nSideFrame > nWindowSize
                 updateEndFrame = updateEndFrame + 1;
                 restart = 1;
             else
                 avgPeak = mean(thisCompData(peakFrame-nSideFrame : peakFrame+nSideFrame));
                 avgFrame = (peakFrame + thisStartFrame) * perFrame;
                 tempPeakTable(iX, :) = {{avgPeak}, {avgFrame}}; 
                 restart = 0;
             end
             nn = nn + 1;
             xxx(nn, :) = [iX, thisStartFrame, thisEndFrame];
             
             if restart, nFail = nFail + 1; break; end
             
             if iX == numX, peakNotInWindow = 0; end
                 
         end
         
         
     end
     
     
     
 end
 
     
 
 end