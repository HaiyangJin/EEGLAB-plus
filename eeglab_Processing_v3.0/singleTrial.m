%% input information
LR = [65 90];  % the central electrodes for left and right hemisphere
Acc = {[], 0, 1};  % all the trials, incorrect trials, and correct trials
plotWindow = [-200 996];

%% Preparation for cluster 
addpath(genpath('Common_Functions/'));
Mahuika;

eeglab;

% the study folder
expFolder = '204';
thisPath = [projectPath, expFolder, '/04_PreProcessed_Individual_All/'];

%% Get the timewindow
rawEpochfile = dir([thisPath expFolder, '_RawEpoch*']);  % find the files of epochs
load([rawEpochfile.folder filesep rawEpochfile.name]);  % load the epoch files
grandAvg = erp_grandmean(table_RawEpoch);  % calculate the grand average for time window
timeWindow = erp_timewindow(grandAvg);  % calculate the time window for output the "peak"

%% Get the raw trial data for this study 
trialData = eeglab_trialmulti(thisPath);

Event = unique(trialData{:, 'Event'});  % all the events
Event = Event(~strcmp(Event, 'epoc'));  % exclude the 'epoc' event (only for one participant)

for iEvent = 1:length(Event)
    thisEvent = Event(iEvent);
    
    for iLR = 1:2
        thisLR = LR(iLR);
        
        for iAcc = 1:3
            thisAcc = Acc{iAcc};
            figTitle = [thisEvent{1}, '-', num2str(thisLR), '-', num2str(thisAcc)];
            
            % plot and save the erp images
            [figure1, clusterTrialData] = erp_erpimage(trialData, thisLR, plotWindow, thisEvent, thisAcc, [], figTitle, 1);
            saveas(figure1, ['ERPimages-', figTitle '.jpg']);
            
            for iFaceSpec = 0:1
            % calculate the amplitude for every trial and plot the
            % distribution
            clsuterTrialPeak = erp_peakoutput(clusterTrialData, timeWindow, 1, iFaceSpec);
            if iFaceSpec
                disTitle = ['FaceSpec-' figTitle];
            else
                disTitle = figTitle;
            end
            
            figure2 = figure;
            histfit(clsuterTrialPeak{:, 'N170'});
            title(disTitle)
            xlabel('Amplitude')
            ylabel('Count of Trials')
            saveas(figure2, ['Distribution-', disTitle '.jpg']); 

            end            
        end
    end

end

disp('Done');