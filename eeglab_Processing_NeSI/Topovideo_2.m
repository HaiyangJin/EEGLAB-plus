%% Preparation for cluster 
addpath(genpath('Common_Functions'));
Mahuika;

ID = getenv('SLURM_ARRAY_TASK_ID'); 
% ID should be 201-216,301-316,401-408,501-508  21-24,31-34,41-42

eeglab;

% the study folder
expCode = ['20' ID(1)];
windowPlot = [];
eventCode = str2double(ID(2:end));


%% Output topo video
% topovideo_table = output_topovideo(expCode, saveData);

Mahuika;
studyPath = [projectPath expCode filesep '04_PreProcessed_Individual_All' filesep];
cd(studyPath);
load([expCode, '_TopoVideoTable']);

plot_topomapbin(topovideo_table, windowPlot, eventCode);