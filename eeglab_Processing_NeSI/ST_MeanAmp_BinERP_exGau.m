%% Preparation for cluster 
addpath(genpath('Common_Functions'));
Mahuika;

ID = getenv('SLURM_ARRAY_TASK_ID'); 
% ID should be 201-216,301-316,401-408  21-24,31-34,41-42

eeglab;

% the study folder
expCode = ['20' ID(1)];
partCode = ID(2:end);

parameters.isCluster = 1;
parameters.isgwindow = 1;
parameters.isDenoise = 0;
parameters.isColorbar = 0;
parameters.plotWindow = [-200 996];

saveAmpData = 1;
saveBinEpoch = 1;
isDistAna = 1;  
isReject = 1;
toSaveFigure = 1;
% fnExtra = '_Detrend';
fnExtra = '_NoDetrend';

% % Don't fit with ex-Gaussian and don't save image (faster)
% isDistAna = 0;  % 
% toSaveFigure = 0;



%% Conduct the single trial analysis
st_analysis(expCode, partCode, parameters, saveAmpData, saveBinEpoch, isDistAna, isReject, toSaveFigure, fnExtra);