%% Preparation for cluster 
addpath(genpath('Common_Functions'));
Mahuika;

ID = getenv('SLURM_ARRAY_TASK_ID'); 
% ID should be 2, 3, 4, 5

eeglab;

% the study folder
expCode = ['20' ID];
saveData = 1;
windowPlot = [];

%% Output topo video
% topovideo_table = output_topovideo(expCode, saveData);

Mahuika;
studyPath = [projectPath expCode filesep '04_PreProcessed_Individual_All' filesep];
cd(studyPath);
load([expCode, '_TopoVideoTable']);

plot_topomapbin(topovideo_table, windowPlot);
