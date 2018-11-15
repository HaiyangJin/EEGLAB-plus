% %% Instruction:
% % Does not do the down sampling.
% 
% %% add eeglab path
% % addpath('/home/hjin317/eeglab/');
% 
% %% run eeglab
% % eeglab;
% 
% %% 00 Preparation
% loadPath = '/gpfs1m/projects/uoa00424/201/03_Rejected_Group/';
cd('/gpfs1m/projects/uoa00424/201/03_Rejected_Group/');
% % loadPath = 'C:\EEG data\201_N170&Time Course\';
% % participateName = 'P001';  %P001
% %ID = getenv('SLURM_ARRAY_TASK_ID')
% %participateName = num2str(str2num(ID),'P1%02d')  %P001
% 
% %ICAName = strcat(participateName, '_02_ICAed')
% %labels = {  'F017'  'F050'  'F100'  'F200'  'H017'  'H050'  'H100'  'H200'  };
% %epochStart =  -0.25;
% %epochEnd = 1;
% 
% %% file names 
% fileName = '*.fdt';
% fileName2 = strcat(participateName, '_01_Raw data.fdt')
% 
% %% file destination 
% destFile = [loadPath, 'All_21/']
% 
% %% move files 
% % movefile(fileName, destFile);
% movefile(fileName2, destFile);
% % 
% % EEG.srate = 250
% % lag = 1000 ./ double(EEG.srate)
% 



%%

% Get all PDF files in the current folder
files = dir('*.fdt');
% Loop through each
for id = 1:length(files)
    % Get the file name (minus the extension)
    [~, f] = fileparts(files(id).name);
      % Convert to number
    newname = [f(1:17), 'Group', f(25:end)];
    movefile(files(id).name, newname);
end