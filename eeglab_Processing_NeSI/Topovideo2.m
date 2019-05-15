%% Preparation for cluster 
addpath(genpath('Common_Functions'));
Mahuika;

ID = getenv('SLURM_ARRAY_TASK_ID'); 
% ID should be 201-216,301-316,401-408,501-508

eeglab;

% the study folder
expCode = ['20' ID(end-2)];
% windowPlot = [];
onsetCode = str2double(ID(end-1:end));
if length(ID) <= 3
    respCode = [];
elseif length(ID) <= 5
    respCode = str2double(ID(1:end-3));
end


%% Output topo video
% topovideo_table = output_topovideo(expCode, saveData);

Mahuika;
fnExtra = '_Detrend';
% fnExtra = '_NoDetrend';
studyPath = [projectPath expCode filesep '04_PreProcessed_Individual' fnExtra filesep];
cd(studyPath);
load([expCode, '_TopoVideoTable']);

plot_topomapbin(topovideo_table, onsetCode);
% plot_topomapbin(topovideo_table, onsetCode, respCode);
