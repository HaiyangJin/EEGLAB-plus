function pool_exgaussian(filepath, fn_outPre)

if nargin < 1 || isempty(filepath)
    filepath = uigetdir(pwd, 'Please select the path where the single trial data are stored.');
    cd(filepath);
else
    cd(filepath);
end

egFiles = dir('*exGaussian_Output.mat');

if nargin < 2 || isempty(fn_outPre)
    fn_outPre = egFiles(1).name(1:3); % expCode
end


% read and save exgaussian fit data
binTable = table;
subjTable = table;

for iFile = 1:size(egFiles, 1)
    
    load(egFiles(iFile).name);

    binTable = [binTable; binFitTable]; %#ok<AGROW>
    subjTable = [subjTable; subjFitTable]; %#ok<AGROW>
    
end

% remove the message from the table
binTable = removeVarT(binTable, {'Message'});
subjTable = removeVarT(subjTable, {'Message'});


writetable(binTable, [fn_outPre '_Bin_exGaussian.csv']);
writetable(subjTable, [fn_outPre '_Subj_exGaussian.csv']);

fprintf('Ex-Gaussian fit data are saved successfully for %s!\n', fn_outPre); 

end

function table = removeVarT(table, VarNames)

allVarnames = table.Properties.VariableNames;
isDeleted = ismember(allVarnames, VarNames);

table = table(:, ~isDeleted);

end
