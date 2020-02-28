%% Preparation for cluster 
addpath(genpath('Common_Functions'));
Mahuika;

ID = getenv('SLURM_ARRAY_TASK_ID'); 
% ID should be 2, 3, 4, 5

eeglab;

% the study folder
expCode = ['20' ID];
saveData = 1;
isReject = 1;
% fnExtra = '_Detrend';
fnExtra = '_NoDetrend';

%% Output topo video
topovideo_table = output_topovideo(expCode, saveData, isReject, fnExtra);

fn_finalTW = dir('*_finalTW.mat');
load(fn_finalTW.name);

for iTW = 1:size(gwindowTable, 1)
    plot_topomapbin(topovideo_table, [], [], gwindowTable{iTW, {'StartTime', 'EndTime'}}, 0);
end
