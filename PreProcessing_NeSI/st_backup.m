%% Preparation for cluster 
addpath(genpath('Common_Functions'));
Mahuika;
ID = getenv('SLURM_ARRAY_TASK_ID');

eeglab;

% the study folder
partCode = ID(2);
expCode = ['20' ID(1)];
isgwindow = 1;
plotWindow = [-200 996];
isCluster = 1;

%% Conduct the single trial analysis
st_analysis(expCode, partCode, isgwindow, plotWindow, isCluster);