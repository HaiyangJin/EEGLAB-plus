% Author: Haiyang
%% After the preprocessing, save the files into different folders.

expPath = ['/gpfs1m/projects/uoa00424/'];
cd(expPath);

% ADJUSTFilenames = 'P*ADJUST*txt';
% movefile(ADJUSTFilenames, [expPath, 'ADJUST', filesep]);


% 
% OutFilenames = '*_*out';
% movefile(OutFilenames, [expPath, 'Out', filesep]);


for iFolder = 3 % fileFolder = '201';
    fileFolder = ['20', num2str(iFolder)];
    expPath = ['/gpfs1m/projects/uoa00424/', fileFolder, filesep];
    % expPath = ['C:\Users\hjin317\Google Drive\2_EEG_DataAnalysis\202_Scramble&LumiMatch\'];
    cd(expPath);
    
    % save the Raw data to RawData
    rawFilenames = 'P*Raw data*';
    movefile(rawFilenames, [expPath, '01_RawData', filesep]);
    
    
    % save the ICAed to ICAed
    ICAedFilenames = 'P*ICAed*';
    movefile(ICAedFilenames, [expPath, '02_ICAed', filesep]);
    
    
    %save the PreProcessed to PreProcessed
    preFilenames = 'P*PreProcessed*';
    movefile(preFilenames, [expPath, '03_PreProcessed', filesep]);
    
end
