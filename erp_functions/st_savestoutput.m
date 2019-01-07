function [conTable, subjTable, paraCode] = st_savestoutput(expCode) %#ok<STOUT>
% save the output from single trial analysis in Cluster

files = dir([expCode '*exGaussian_Output.mat']);

nFile = size(files, 1);

conTable = table;
subjTable = table;

for iFile = 1:nFile

    load(files(iFile).name);
    
    if ~exist('paraCodeOld', 'var')
        paraCodeOld = paraCode;
    elseif ~strcmp(paraCodeOld, paraCode)
        error('The parameter codes are different for the loaded data!')
    end
    
    subjFitTable = removeVarT(subjFitTable, {'Message'});
    conFitTable = removeVarT(conFitTable, {'Message'});
    %     writetable(subjFitTable, [NScon '_Subj_Output.csv']);
    %     writetable(conFitTable, [NScon '_ConFitTable.csv']);
    
    conTable = vertcat(conTable, conFitTable); %#ok<AGROW>
    subjTable = vertcat(subjTable, subjFitTable); %#ok<AGROW>
    
end

writetable(conTable, [expCode '_' paraCode '_ConFitTable.csv']);
writetable(subjTable, [expCode '_' paraCode '_Subj_Output.csv']);

end

function table = removeVarT(table, VarNames)

allVarnames = table.Properties.VariableNames;
isDeleted = ismember(allVarnames, VarNames);

table = table(:, ~isDeleted);

end