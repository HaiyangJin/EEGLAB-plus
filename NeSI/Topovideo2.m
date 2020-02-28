%% Preparation for cluster 
addpath(genpath('Common_Functions'));
Mahuika;

ID = getenv('SLURM_ARRAY_TASK_ID'); 
% ID should be 201-216,301-316,401-408,501-508
% ID for response are 10501-10508,9501-9508,8501-8508,  1501-1508,2501-2508,3501-3508

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
Mahuika;
fnExtra = '_Detrend';
% fnExtra = '_NoDetrend';

% isReject = 1;
% topovideo_table = output_topovideo(expCode, saveData, isReject, fnExtra);

studyPath = [projectPath expCode filesep '04_PreProcessed_Individual' fnExtra filesep];
cd(studyPath);
load([expCode, '_TopoVideoTable']);

plot_topomapbin(topovideo_table, onsetCode);
% plot_topomapbin(topovideo_table, onsetCode, respCode);
