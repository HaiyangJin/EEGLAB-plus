function pool_stdata(filepath)

if nargin < 1
    filepath = uigetdir(pwd, 'Please select the path where the single trial data are stored.');
    cd(filepath);
else
    cd(filepath);
end

binFiles = dir('*BinEpoch.mat');
ampFiles = dir('*MeanAmp.mat');
expCode = ampFiles(1).name(1:3);

% load and save bin epoch table
bintable = table;
for iBin = 1:size(binFiles, 1)
    load(binFiles(iBin).name); 
    bintable = [bintable; ST_BinEpochTable];  %#ok<AGROW>
    clear ST_BinEpochTable
end

% save the erp data
output_binerp(bintable, [], [], 0, 0, expCode);
output_binerp(bintable, [], [], 1, 0, expCode);


% load and save mean amplitude table
amptable = table;
for iAmp = 1:size(ampFiles, 1)
    load(ampFiles(iAmp).name);
    amptable = [amptable; ST_MeanAmpTable]; %#ok<AGROW>
    clear ST_MeanAmpTable
end

%% Save csv
% binfn = [expCode '_BinEpoch.csv'];
ampfn = [expCode '_MeanAmp.csv'];

% writetable(bintable, binfn);
writetable(amptable, ampfn);
disp('Tables are saved successfully!');

end