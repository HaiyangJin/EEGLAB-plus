function gmeanTable = erp_gmean_assum(epoch_table, trialNum_table, chanCentTable, isCluster)

if nargin < 3
    chanCentTable = {'P1', '65', '90';
                     'N170', '58', '96'};
    fprintf('\nThe default channels are used for P1 and N170.\n');
end
if nargin < 4
    isCluster = [];
end

gmeanTable = table;
for iComp = 1:size(chanCentTable, 1)
    chanCent = chanCentTable(iComp, 2:3);
%     thisgmeanTable = erp_gmean(epoch_table, trialNum_table, chanCent, isCluster);  % Weighted mean
    thisgmeanTable = erp_gmean_subj(epoch_table, trialNum_table, chanCent, isCluster);  % Weighted mean

    thisgmeanTable.Component = chanCentTable(iComp, 1);
    
    gmeanTable = vertcat(gmeanTable, thisgmeanTable);   %#ok<AGROW>

end

end