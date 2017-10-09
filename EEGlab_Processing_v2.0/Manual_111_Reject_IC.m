%% Reject ICs manually
% This script is to reject the ICs manually.
% 1. create a study without design
% 2. precompute spectrum (optionally with scalp maps)
% 3. Cluster all ICs just by using spectra
% 4. Create the same number of clusters
% 5. To check every cluster manually and write down the bad ones


%% Preparation
% select all the ICAed files for rejecting ICs
[ICAedFilenames, ICAedPath] = uigetfile({'*.set', 'eeg lab files (*.set)'; ...
    '*.*',  'All Files (*.*)'}, ...
    'Please select all the ICAed files (*.mat) that you want to reject IC this time', ...
    'MultiSelect', 'on');

% select two or more
if strcmp((ICAedFilenames(1)), 'P')
    numParticipant = 1;
else
    numParticipant = length(ICAedFilenames);
end

%%%% 1. create a study without design
% make a temp study design to create the study
clear tempLoad
tempLoad = cell(1, numParticipant);
clear tempSubject
tempSubject = cell(1, numParticipant);
clear tempCondition
tempCondition = cell(1, numParticipant);

for iParticipant = 1:numParticipant
    ICAedThisFilename = ICAedFilenames{iParticipant}; % the fielname of this ICAed file
    ICAedFile = [ICAedPath, ICAedThisFilename]; % the path of this ICAed file
    
    % the design for this participant
    tempLoad(1, iParticipant) = {{'index' iParticipant 'load' ICAedFile}};
    tempSubject(1, iParticipant) = {{'index' iParticipant 'subject' ICAedThisFilename(1:4)}};
    tempCondition(1, iParticipant) = {{'index' iParticipant 'condition' 'OneCondition'}};
        
end
% get the temp study design
tempStudyDesign = horzcat(tempLoad, tempSubject, tempCondition);
% get the study name
studyName = ['20', ICAedThisFilename(2), '_', num2str(numParticipant), '_RejectingIC'];

% create the study for rejecting ICs
[STUDY, ALLEEG] = eeglab;
[STUDY, ALLEEG] = std_editset(STUDY, ALLEEG, 'name', studyName, ...
    'commands',tempStudyDesign, 'updatedat','on','savedat','on','rmclust','on' );

%%%% 2. precompute spectrum (optionally with scalp maps)
[STUDY, ALLEEG] = std_precomp(STUDY, ALLEEG, 'components','recompute','on',...
    'scalp','on','spec','on','specparams',{'specmode' 'fft' 'logtrials' 'off'});

%%%% 3. Cluster all ICs just by using spectra
[STUDY, ALLEEG] = std_preclust(STUDY, ALLEEG, 1, ...
    {'spec' 'npca' 30 'norm' 1 'weight' 1 'freqrange' [3 50] });

%%%%% save the study for rejecting
EEG = ALLEEG;
STUDY = pop_savestudy( STUDY, EEG, 'filename',studyName,'filepath',ICAedPath);
disp(['Save the study of ', studyName, ' successfully!']);

%%%% redraw
[EEG, ALLEEG , ~] = eeg_retrieve(ALLEEG,1);
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'retrieve', 1:size(ALLEEG,2),...
    'study',1); CURRENTSTUDY = 1;
eeglab redraw;

%% Manually then
%%%% 4. Create the same number of clusters
% 124
% [STUDY] = pop_clust(STUDY, ALLEEG, 'algorithm','kmeans','clus_num',  numCluster , 'outliers',  3 );

%%%% 5. To check every cluster manually and write down the bad ones
% set the frequency as 3-60 Hz
STUDY = pop_specparams(STUDY, 'topofreq',NaN,'freqrange',[0 60] );
goodICs = [];

for iCluster = 2:size(STUDY.cluster,2)
    % draw the figure for spectrum, topography and dipolar
    STUDY = std_specplot(STUDY,ALLEEG,'clusters',iCluster);
    set(gcf,'Position',[100 100 600 500]);
    STUDY = std_topoplot(STUDY,ALLEEG,'clusters',iCluster);
    set(gcf,'Position',[720 100 500 500]);
    STUDY = std_dipplot(STUDY,ALLEEG,'clusters',iCluster);
    set(gcf,'Position',[1250 100 600 500]);
    
    % wait for a key press
    w = waitforbuttonpress;
    if w ~= 0 % if bad IC, click mouse
        goodICs = [goodICs, iCluster]; %#ok<AGROW>
    end
    close(2:4);
    disp(iCluster);
end

disp(goodICs);

%%  Std selectICsByCluster
% copy the badICs from Matlab and run the selectICsByCluster

%% rename the files which has been deleted the bad components
% select all the bad ICs rejected files for renaming
[ICRejectedFilenames, ICRejectedPath] = uigetfile({'*.set;*.fdt', 'eeglab files (*.set,*.fdt)';...
    '*.*',  'All Files (*.*)'}, ...
    'Please select all the ICAs rejected files (*.mat) that you want to rename',...
    'MultiSelect', 'on');

% rename the files
if strcmp(ICRejectedFilenames(1), 'P') % if there is only one file
    oldFile = [ICRejectedPath, ICRejectedFilenames];
    newFile = [ICRejectedPath, ICRejectedFilenames(1:6), '3_Rejected_manual', ICRejectedFilenames(end-3:end)]; 
    movefile(oldFile, newFile); % rename this file as PreProcessed file
else
    numFiles = length(ICRejectedFilenames);
    for iFile = 1:numFiles
        thisFilename = ICRejectedFilenames{iFile};
        oldFile = [ICRejectedPath, thisFilename];
        newFile = [ICRejectedPath, thisFilename(1:6), '3_Rejected_manual', thisFilename(end-3:end)];
        movefile(oldFile, newFile);
    end
end

disp('Rename all the Rejected files successfully.');

