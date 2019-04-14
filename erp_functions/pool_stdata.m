function pool_stdata(filepath, fn_outPre)

if nargin < 1
    filepath = uigetdir(pwd, 'Please select the path where the single trial data are stored.');
    cd(filepath);
else
    cd(filepath);
end
binFiles = dir('*BinEpoch.mat');
ampFiles = dir('*MeanAmp.mat');

if nargin < 2 || isempty(fn_outPre)
    fn_outPre = ampFiles(1).name(1:3); % expCode
end

% load and save bin epoch table
bintable = table;
for iBin = 1:size(binFiles, 1)
    load(binFiles(iBin).name); 
    bintable = [bintable; ST_BinEpochTable];  %#ok<AGROW>
    clear ST_BinEpochTable
end

% save the erp data
output_binerp(bintable, [], [], 0, 0, fn_outPre);
output_binerp(bintable, [], [], 1, 0, fn_outPre);


% load and save mean amplitude table
amptable = table;
for iAmp = 1:size(ampFiles, 1)
    load(ampFiles(iAmp).name);
    amptable = [amptable; ST_MeanAmpTable]; %#ok<AGROW>
    clear ST_MeanAmpTable
end

%% Save csv
% binfn = [expCode '_BinEpoch.csv'];
ampfn = [fn_outPre '_MeanAmp.csv'];

% writetable(bintable, binfn);
writetable(amptable, ampfn);
fprintf('Tables are saved successfully for %s!', fn_outPre);

end