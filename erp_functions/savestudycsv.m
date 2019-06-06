function savestudycsv(expCode, topoChanComp, analysisCode, isCluster) 
if nargin < 4
    isCluster = 1;
end

% output filenames
grandFilename = [expCode '_01_Grand_' analysisCode];
chandataFilename = [expCode '_02_AllChanEpoch_' analysisCode];
peakFilename = [expCode '_03_LocalMeanAmp_' analysisCode];
topoFilename = [expCode '_00_TopoData_' analysisCode];


%% load grand mean, grand time window, allChanTable and topoData
% grand mean and time window
pathMat = ['from210' filesep];
grandFile = dir([pathMat expCode, '_Grand*.mat']);
load([pathMat filesep grandFile.name]);

% load AllChanEpoch
epochFile = dir([pathMat expCode, '_AllChanEpoch*.mat']);
load([pathMat filesep epochFile.name]);

% load topo data
topoFile = dir([pathMat expCode, '_TopoData*.mat']);
load([pathMat filesep topoFile.name]);


%% double check the channels for peak 
% check if the chanComp and topoChan are the same
% chanComp: the channels got by checking the topo map
% topoChan: the assumed channels for components
isSameChan = checktopochan(topoChanComp, gwindowTable); %#ok<NODEF>

if ~isSameChan
    gmeanTable = table;
    
    % recalculate the grand mean for the chanComp
    for iComp = 1:size(topoChanComp, 1)
        chanCent = topoChanComp(iComp, 2:3);
%         thisgmeanTable = erp_gmean(epoch_table, trialNum_table, chanCent);  % Weighted mean (not accurate)
        thisgmeanTable = erp_gmean_subj(binavg_table, trialNum_table, chanCent);  
        thisgmeanTable.Component = topoChanComp(iComp, 1);
        gmeanTable = vertcat(gmeanTable, thisgmeanTable); %#ok<AGROW>
    end
    
    % reclculate the time window
    [gwindowTable, zeroTable] = erp_gwindow(gmeanTable); 
    if isunix && ~ismac; close; end

    % recreate the topomap
    [topo_table, gtopo_table] = plot_topodata(binavg_table, gwindowTable, chanInfo);
  
end


%% save as csv
writetable(gwindowTable, [grandFilename, '_gwindow.csv']);
writetable(gmeanTable, [grandFilename, '_gmean.csv']);
writetable(zeroTable, [grandFilename, '_zero.csv']);
writetable(binavg_table, [chandataFilename, '.csv']);

% save the grand xlsx
writetable(gwindowTable, [grandFilename, '_.xlsx'], 'Sheet', 'gwindow');
writetable(gmeanTable, [grandFilename, '_.xlsx'], 'Sheet', 'gmean');
writetable(zeroTable, [grandFilename, '_.xlsx'], 'Sheet','zero');

% save the topo xlsx
writetable(topo_table, [topoFilename, '.xlsx'], 'Sheet', 'TopoData');
writetable(gtopo_table, [topoFilename, '.xlsx'], 'Sheet', 'GrandTopoData');
writetable(cell2table(topoChanComp), [topoFilename, '.xlsx'], 'Sheet', 'TopoChan');


%% calculate the amplitude for every bin
% get the epoch data for every condition
conEpochTable = erp_binepochtable(binavg_table, gwindowTable, isCluster);
% get the local mean amplitude information for every bin
conWindowTable_local = erp_binwindowpeak(conEpochTable, gwindowTable);  % local mean amplitude
conWindowTable_meanAmp = erp_binwindowpeak(conEpochTable, gwindowTable, 2); % mean amplitude

% Output the (local) mean amplitude
writetable(conWindowTable_local, [peakFilename '_local.csv']);
writetable(conWindowTable_meanAmp, [peakFilename '_meanAmp.csv']);


%% Face specific ERPs
% specEpochTable = erp_facespecepoch(binavg_table);
% 
% specConEpochTable = erp_binepochtable(specEpochTable, gwindowTable, isCluster);
% % Output the peak value
% specConWindowTable = erp_binwindowpeak(specConEpochTable, gwindowTable);
% writetable(specConWindowTable, [peakFilename '_spec.csv']);


%% save final grand time window and condition time window for single trial analysis
if strcmpi(analysisCode, 'all')
    save([expCode '_finalTW'], 'gwindowTable', 'conWindowTable_local');
end

end