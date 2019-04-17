function pool_stdata(filepath, fn_outPre)

if nargin < 1 || isempty(filepath)
    filepath = uigetdir(pwd, 'Please select the path where the single trial data are stored.');
    cd(filepath);
else
    cd(filepath);
end
binFiles = dir('*BinEpoch.mat');
ampFiles = dir('*MeanAmp.mat');

isBinFile = ~isempty(binFiles);
isAmpFile = ~isempty(ampFiles);

if nargin < 2 || isempty(fn_outPre)
    if isBinFile
        fn_outPre = binFiles(1).name(1:3); % expCode
    else
        fn_outPre = ampFiles(1).name(1:3); % expCode
    end
end

%% Process bin erp files
if isBinFile
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
    fprintf('Bin epoch data are saved successfully for %s!\n', fn_outPre);
end


%% Process mean amp files
if isAmpFile
    % load and save mean amplitude table
    amptable = table;
    for iAmp = 1:size(ampFiles, 1)
        load(ampFiles(iAmp).name);
        amptable = [amptable; ST_MeanAmpTable]; %#ok<AGROW>
        clear ST_MeanAmpTable
    end
    
    % Save csv
    % binfn = [expCode '_BinEpoch.csv'];
    ampfn = [fn_outPre '_MeanAmp.csv'];
    
    % writetable(bintable, binfn);
    writetable(amptable, ampfn);
    fprintf('Mean amplitude data are saved successfully for %s!\n', fn_outPre);
end

end