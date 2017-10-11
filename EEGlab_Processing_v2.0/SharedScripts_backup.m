%% clsuter realted
% get all participant names
ID = getenv('SLURM_ARRAY_TASK_ID'); 
experimentNum = ID(1);    % the number of experiment

jobID = getenv('SLURM_ARRAY_JOB_ID');
fopen([outputPath jobID '_' ID '.txt'],'w+'); % create a txt file whose filename is the job ID


%% 1.5 after components rejected
ADJUSTOutputName = [participantName,'_ADJUST_',dt,'.txt'];
preProcessedName = strcat(participantName, '_03_PreProcessed_',dt,'.set');

%% 2.0 info about study
% DivEpo labels
if strcmp(experimentNum, '1')
    labels = {'F017' 'F050'  'F100'  'F200'  'H017'  'H050'  'H100'  'H200'};
elseif strcmp(experimentNum, '2') || strcmp(experimentNum, '3')
    labels = {'NF7+'  'NF5+'  'NF1+'  'NF2+'  'NH7+'  'NH5+'  'NH1+'  'NH2+' ...
              'SF7+'  'SF5+'  'SF1+'  'SF2+'  'SH7+'  'SH5+'  'SH1+'  'SH2+'};
elseif strcmp(experimentNum, '4')
    labels = {'NF7+'  'NF2+'  'NH7+'  'NH2+'  'SF7+'  'SF2+'  'SH7+'  'SH2+'};
end
numLabel = length(labels); % the number of labels





% ParticipantNum
if strcmp(experimentNum, '2')
    theParticipants = 0:19; 
else
    theParticipants = 1:20;
end


epochStart =  -0.5;
epochEnd = 1;

