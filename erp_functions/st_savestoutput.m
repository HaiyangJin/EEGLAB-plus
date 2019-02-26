function [conTable, subjTable, paraCode] = st_savestoutput(expCode) %#ok<STOUT>
% save the output from single trial analysis in Cluster

oldPath = pwd;
if nargin < 1 || isempty(expCode)
    thePath = uigetdir('.', 'Please select the folder where the exGaussian files are stored...');
    cd(thePath);
end

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

cd(oldPath);

end

function table = removeVarT(table, VarNames)

allVarnames = table.Properties.VariableNames;
isDeleted = ismember(allVarnames, VarNames);

table = table(:, ~isDeleted);

end