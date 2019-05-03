%% 200 Create a new study  
% Author: Haiyang Jin (haiyang.jin@auckland.ac.nz)
% create a study for all the participants in one experiment

% This script only use one *.set file for each participant to create the
% study, the different conditions are assigned by STUDY.design (based on
% the suggestion from Makoto's PreProcessing Pipeline)

% this script saves the data into table (not a cell)


%% % Prepaparation for different platform
baselineStart = -200;
if isunix && ~ismac
    addpath(genpath('Common_Functions/'));
    Mahuika;
    % get the experiment number
    ID = getenv('SLURM_ARRAY_TASK_ID');
    display(ID);
    % to make sure the length of ID is two
    if length(ID) ~= 4
        error('There should be four digitals for the array!!!')
    else
        expCode = ID(2);    % the number of experiment
        isIndividual = str2double(ID(1));
    end
    
    % get the Job ID from Cluster
    jobID = getenv('SLURM_ARRAY_JOB_ID');
    
    expFolderCode = ['20' expCode];  % the folder for this experiment
    expFolderPath = [projectPath,expFolderCode,filesep];  % the path for this experiment

elseif ispc || ismac
    % input the number of this experiment
    expCode = [];
    while isempty(expCode)
        expCode = input('Please input the experiment Number (1, 2, 3, 4 or 5): ','s');
    end
    expFolderCode = ['20' expCode];
    
    isIndividual = [];
    while isempty(isIndividual)
        isIndividual = input('Are the ICs rejected individually (1(individually), 2(group)): ');
    end
    
else
    error('Platform not supported!');
end


%% get the folder info
indiInfoFolder = {'Individual', 'Group'};
folderInfo = indiInfoFolder{isIndividual};

% get the study path
if isunix && ~ismac
    studyPath = [expFolderPath,'04_PreProcessed_', folderInfo, filesep]; % get the study path
    fopen([studyPath jobID '_' ID '.txt'],'w+'); % create a txt file whose filename is the job ID
    
elseif ispc || ismac
    % open GUI to select the folder where the PreProcessed data are saved
    studyPath = [uigetdir('.',...
        'Please choose the folder where the clean (PreProcessed) data are saved.'), filesep];
end
cd(studyPath);


%% Preparation 
% the codes of all the participant that you want to create the study for
switch expCode
    case '1'
        subjCodes = 1:21;
    case '2'
        subjCodes = 0:19;
    case '3'
        subjCodes = 1:20;
    case '4'
        subjCodes = 1:30;
    case '5'
        subjCodes = [4, 6:8, 10:35];
end
nSubj = length(subjCodes); % the number of participants


%% create the array for the experiment desgin and then create the study
% create the experiment design
clear tempStudyDesign
clear subjList
tempStudyDesign = cell(1, nSubj);
subjList = cell(1, nSubj);

preProcessedName = ['_04_PreProcessed_' folderInfo];

for iSubj = 1:nSubj
    tempSubj = num2str(subjCodes(iSubj),['P' expCode '%02d']);
    
    % get the list of participant names for this study
    subjList{1, iSubj} = tempSubj;
    % the filename of the preprocessed file
    dataFilename = [studyPath, tempSubj, preProcessedName, '.set']; % [path 'P301_04_PreProcessed(_manual)]
    
    tempStudyDesign{1, iSubj}= {'index' iSubj ...
                                        'load' dataFilename ...
                                        'subject' tempSubj ...
                                        'condition' 'OneCondition'};
end
clear iSubj

% create the study
eeglab;
dt = datestr(now,'yymmddHH');
studyName = ['EEG_FH_', expFolderCode, '_', num2str(nSubj), '_', ...
    folderInfo, '_' dt];
[STUDY, ALLEEG] = std_editset(STUDY, ALLEEG, 'name', studyName, 'updatedat','off',...
    'commands', tempStudyDesign);

% get all the lables for this study
events = unique({STUDY.datasetinfo(1).trialinfo.type});

% make the design for this study
designName = [expFolderCode, '_', num2str(nSubj), '_', folderInfo];
STUDY = std_makedesign(STUDY, ALLEEG, 1, 'variable1','type','variable2','',...
    'name', designName,'pairing1','on','pairing2','on','delfiles','off',...
    'defaultdesign','off','values1',events, 'subjselect', subjList);

% precompute baseline
[STUDY , ALLEEG] = std_precomp(STUDY, ALLEEG, {},'interp','on','recompute','on',...
    'erp','on','erpparams',{'rmbase' [baselineStart 0] });

% save this study
% EEG = ALLEEG;
STUDY = pop_savestudy(STUDY, ALLEEG, 'filename',studyName,'filepath',studyPath);
disp(['Save the study of ', studyName, ' successfully!']);


%% %%%% 301 Output the mean of raw data into excel %%%% %%
% Output the mean for all trials for each condition, every participant, and
% every channels.

% remove the bad trials from ALLEEG
ALLEEGT = study_rejecttrials(ALLEEG);

% get the channel data for all channels
% epoch_table = study_chandata(STUDY, ALLEEG);  % cannot be used if bad trials are not removed

% save the mean of the raw data into the excel amd the backup file
if ~exist(dt, 'var'); dt = datestr(now,'yymmddHH'); end

sheetName_epoch = [expFolderCode,'_AllChanEpoch']; 
filename_epoch = strcat(studyPath, sheetName_epoch, '_', folderInfo);

filename_xlsx = strcat(filename_epoch, '_', dt, '.xlsx');
filename_mat = strcat(filename_epoch, '_', dt, '.mat');

if ispc || ismac
    writetable(epoch_table, filename_xlsx, 'Sheet', sheetName_epoch);
    save(filename_mat, 'epoch_table', '-v7.3'); %, '-nocompression'
elseif isunix
    save(filename_mat, 'epoch_table', '-v7.3'); %, '-nocompression'
else
    error('Platform not supported!')
end

disp('Save or backup the raw epoch data successfully!');


%% %%%% 302 Calculate the grand averaged ERP %%%% %%
% get the trial numbers for every condition
trialNum_table = study_trialnumbin(STUDY);  % 

% calculate the grand average
gmeanTable = erp_gmean_assum(epoch_table, trialNum_table);  % Weighted mean
% gmeanTable = erp_gmean(epoch_table);  % (normal) mean

%% %%%% 303 Lock the time windows %%%% %%
% 2. then calculate the time windows for this grand average.
[gwindowTable, zeroTable] = erp_gwindow(gmeanTable); 
% [gwindowTable2, zeroTable2] = erp_gwindow(gmeanTable, 2);  % method 2
if isunix && ~ismac; close; end

% save grand average ERP into the excel amd the backup file
gwinFilename = strcat(studyPath, expFolderCode, '_Grand_', folderInfo);
gwinSheetname = [expFolderCode,'_GWindow']; 
zeroSheetname = [expFolderCode,'_Zeros'];
gmeanSheetName = [expFolderCode,'_GMean']; 

if ~exist(dt, 'var'); dt = datestr(now,'yymmddHH'); end

filename_xlsx = strcat(gwinFilename, '_', dt, '.xlsx');
filename_mat = strcat(gwinFilename, '_', dt, '.mat');

if ispc || ismac
    writetable(gwindowTable, filename_xlsx, 'Sheet', gwinSheetname);
    writetable(gmeanTable, filename_xlsx, 'Sheet', gmeanSheetName);
    writetable(zeroTable, filename_xlsx, 'Sheet', zeroSheetname);
    save(filename_mat, 'gmeanTable', 'zeroTable', 'gwindowTable',...
        'trialNum_table', '-v7.3'); %, '-nocompression'
elseif isunix
    save(filename_mat, 'gmeanTable', 'zeroTable', 'gwindowTable',...
        'trialNum_table', '-v7.3'); %, '-nocompression'
else
    error('Platform not supported!')
end

disp('Save or backup the Grand information successfully!');


%% %%%% 304 Save the scalp distribution to check the location of peak %%%% %%
% get topo data and grand topo data
chanInfo = ALLEEG(1).chanlocs;
[topo_table, gtopo_table] = plot_topodata(epoch_table, gwindowTable, chanInfo);

gtopoSheetname = 'GrandTopo'; 
topoSheetname = 'Topo';
topoFilename = strcat(studyPath, expFolderCode, '_TopoData_', folderInfo);


if ~exist(dt, 'var'); dt = datestr(now,'yymmddHH'); end

filename_xlsx = strcat(topoFilename, '_', dt, '.xlsx');
filename_mat = strcat(topoFilename, '_', dt, '.mat');

if ispc || ismac
    writetable(topo_table, filename_xlsx, 'Sheet', topoSheetname);
    writetable(gtopo_table, filename_xlsx, 'Sheet', gtopoSheetname);
    save(filename_mat, 'topo_table', 'gtopo_table', 'chanInfo', '-v7.3'); %, '-nocompression'
elseif isunix
    save(filename_mat, 'topo_table', 'gtopo_table', 'chanInfo', '-v7.3'); %, '-nocompression'
else
    error('Platform not supported!')
end

disp('Save the data for topograph check successfully!');


%% All done successfully!
disp('Done!!!');

if ispc || ismac
    beep;
    pause(0.3);
    beep;
    pause(0.3);
    beep;
end
