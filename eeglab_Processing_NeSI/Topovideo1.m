%% Preparation for cluster 
addpath(genpath('Common_Functions'));
Mahuika;

ID = getenv('SLURM_ARRAY_TASK_ID'); 
% ID should be 2, 3, 4, 5

eeglab;

% the study folder
expCode = ['20' ID];
saveData = 1;
fnExtra = '_Detrend';
% fnExtra = '_NoDetrend';

%% Output topo video
output_topovideo(expCode, saveData, fnExtra);
