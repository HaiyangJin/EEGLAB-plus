% Preparation for cluster 
eeglabPath = '/home/hjin317/eeglab/';
addpath(eeglabPath);  % add the path for eeglab
eeglab;

functionPath = '/gpfs1m/projects/uoa00424/Common_Functions/';
addpath(functionPath);

thisPath = '/gpfs1m/projects/uoa00424/204/04_PreProcessed_Individual_All/';
trialData = eeglab_trialmulti(thisPath);

Event = unique(trialData{:, 'Event'});

LR = [65 90];

Acc = {[], 0, 1};

for iEvent = 1:length(Event)
    thisEvent = Event(iEvent);
    
    for iLR = 1:2
        thisLR = LR(iLR);
        
        for iAcc = 1:3
            thisAcc = Acc{iAcc};
            title = [thisEvent{1}, '-', num2str(thisLR), '-', num2str(thisAcc)];
            figure1 = erp_erpimage(trialData, thisLR, [-200 996], thisEvent, thisAcc, [], title);
            saveas(figure1, [title '.jpg']);
        end
    end

end

disp('Done');


% test = trialData(logical(ismember(trialData{:, 'Event'}, {'NF7+'}) .* ismember(trialData{:, 'ACC'}, 0)), :);
% erp_erpimage(test, 65)