%% Settings
parameters.isCluster = 1;
parameters.isgwindow = 1;
parameters.isDenoise = 0;
parameters.isColorbar = 0;
parameters.plotWindow = [-200 996];

saveAmpData = 1;
saveBinEpoch = 1;
isDistAna = 1;
isReject = 1;
toSaveFigure = 0;
% fnExtra = '_Detrend';
fnExtra = '_NoDetrend';


%% Preparation
if isunix && ~ismac
    %% Preparation for cluster
    addpath(genpath('Common_Functions'));
    Mahuika;
    
    ID = getenv('SLURM_ARRAY_TASK_ID');
    % ID should be 201-216,301-316,401-408  21-24,31-34,41-42
    
    expCode = ['20' ID(1)];
    IDs = {ID(2:end)};
    
    Mahuika;
    studyPath = [projectPath expCode filesep '04_PreProcessed_Individual' fnExtra filesep];
    
elseif ispc || ismac
    expCodeNum = [];
    while isempty(expCodeNum)
        expCodeNum = input('Please input the experiment Number (1, 2, 3, 4 or 5): ','s');
    end
    expCode = ['20' expCodeNum];
    
    ID = [];
%     switch expCodeNum
%         case '2'
%             IDs = 1:16;
%         case '3'
%             IDs = 1:16;
%         case '4'
%             IDs = 1:8;
%         case '5'
%             IDs = 1:8;
%     end
%     
%     ID = arrayfun(@(x) num2str(x, '%02d'), IDs, 'UniformOutput', false);
    
    studyPath = [uigetdir('.',...
        'Please choose the folder where the clean (PreProcessed) data are saved.'), filesep];
    
end

cd(studyPath);


%% Run this job
if ~isempty(ID)
    nPart = length(ID);
else
    nPart = 1;
end

for iPart = 1:nPart
    
    if ~isempty(ID)
        partCode = ID{iPart};
    else
        partCode = [];
    end
    
    eeglab;
    
    % % Don't fit with ex-Gaussian and don't save image (faster)
    % isDistAna = 0;  %
    % toSaveFigure = 0;    
    
    %% Conduct the single trial analysis
    st_analysis(expCode, partCode, parameters, saveAmpData, saveBinEpoch, isDistAna, isReject, toSaveFigure);
    
end