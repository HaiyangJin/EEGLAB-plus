function st_analysis(expCode, partCode, isgwindow, plotWindow, isCluster)

fprintf([repmat('=', 1, 60) '\n' ...
    'Fitting models for the Part %s... \n' ...
    repmat('=', 1, 60) '\n\n'], partCode);



if nargin < 2
    isgwindow = 1;
end
if nargin < 3
    plotWindow = [-200 996];
    warning('The default plot window (%d : %d) is used.', plotWindow);
end
if nargin < 4
    isCluster = 1;
end

if ispc || ismac
    studyPath = uigetdir(pwd, ...
        'Please select the study folder:');
else
    Mahuika;
    studyPath = [projectPath expCode filesep '04_PreProcessed_Individual_All' filesep];
end
cd(studyPath);


%% Create folder for saving output images
erpimageFolder = ['ST_erpimage' filesep];
if ~exist(erpimageFolder, 'dir')
    mkdir(erpimageFolder);
end

subjFitFolder = ['ST_SubFit' filesep];
if ~exist(subjFitFolder, 'dir')
    mkdir(subjFitFolder);
end

conFitFolder = ['ST_ConFit' filesep];
if ~exist(conFitFolder, 'dir')
    mkdir(conFitFolder);
end


%% Locate and load the time window files
% twFile = dir('finalTW');
% load([twFile.path filesep twFile.name]);
load('finalTW');

if isgwindow
    tw = gwindowTable;
else
    tw = conWindowTable;
end


%% Load all the trial epoch data
trialTable = st_trialmulti; % 


%% information for this study
% from trial epoch data table
event = unique(trialTable.Event);  % all the events
isOnsetEvent = cellfun(@(x) any(x(1)=='NS'), event);
if ~all(isOnsetEvent)
   error(['Some events are not onset events.\n' ...
       'Event:' repmat(' %s', 1, sum(~isOnsetEvent)) '.'], event{~isOnsetEvent}); 
end
nEvent = length(event);

% from time window table
components = unique(tw.Component);
nComp = length(components);

% other fixed information
LR = {'Left', 'Right'};
correctStr = {'all', 'incorrect', 'correct'};
if ~strcmp(expCode, '205')
    accCode = {[], '0', '1'};  % all the trials, incorrect trials, and correct trials
else
    error('Please set up the response code for E205!');
end

if isCluster; clusterStr = 'Cluster'; else clusterStr = 'SingleChannel'; end 
subjFit = struct;
nSubRow = 0;
conFit = struct;
nConRow = 0;

for iEvent = (1:4) + (str2double(partCode) - 1) * 4 % (1:nEvent/2) + nEvent/2 * NS
    thisEvent = event{iEvent};
    
    for iComp = 1:nComp
        thisComp = components{iComp};
        
        for iLR = 1:2
            thisLR = LR{iLR};
            
            theCentChans = tw{iComp, 'ChanCent'};
            theCentChan = theCentChans{iLR};

            for iAcc = 1:length(correctStr)
                thisAcc = accCode{iAcc};
                isCorStr = correctStr{1, iAcc};
                
                
                %% Plot erp-images 
                figTitle = sprintf([repmat('%s-', 1, 5) '%s'], ...
                    thisComp, thisEvent, thisLR, theCentChan, isCorStr, clusterStr);
                
                fprintf(['\n' repmat('-', 1, 80) '\n' ...
                    'Plotting the ERP-image for the condition: %s...\n'], figTitle);
                
                %%%%%  plot and save the erp images  %%%%%
                [erpfigure, clusterTrialTable] = erp_erpimage(trialTable, theCentChan, ...
                    plotWindow, thisEvent, thisAcc, [], figTitle, isCluster);
                saveas(erpfigure, [erpimageFolder 'ERPimages-', figTitle '.jpg']);
                
                fprintf(['Successfully plot the ERP-image for condition: %s.\n' ...
                    repmat('-', 1, 80) '\n\n' ], figTitle); 
                
                % calculate the amplitude for every trial and plot the
                % distribution
                trialMeanAmp = st_meanamp(clusterTrialTable, tw, thisComp); 
                
                
                %% fit ex-gaussian function for every subject
                %%%%% fit exGaussian and save the parameters %%%%% 
                
                %%%%% for every participant with loop %%%%%
                subjCond = unique(trialMeanAmp.SubjCode);  % subject codes in this condition
                nSubjCond = length(subjCond);  
                
                for iSubj = 1:nSubjCond
                    thisSubj = subjCond{iSubj};
                    
                    isSubj = strcmp(trialMeanAmp.SubjCode, thisSubj);
                    subjData = trialMeanAmp{isSubj, 'MeanAmp'};
                    
                    if length(subjData) <= 1
                        model = 'Only one data point';
                        mu = NaN;
                        sigma = NaN;
                        tau = NaN;
                        output.iterations = NaN;
                        output.funcCount = NaN;
                        output.algorithm = '';
                        output.message = 'Only one data poin for this bin.';
                    else
                        fprintf(['\n' repmat('%%', 1, 50) '\n' ...
                            'Fitting the ex-Gaussian model for Participant ' ...
                            thisSubj ' in the ' figTitle ' condition...\n']);
                        
                        [mu, sigma, tau, model, ~, ~, output, fitfig] = erp_eg_fitplot(subjData);
                        
                        subjTitle = [thisSubj '-' figTitle];
                        title(subjTitle)
                        saveas(fitfig, [subjFitFolder 'Distribution-', subjTitle '.jpg']);
                        
                    end
                    
                    % levels of conditions
                    nSubRow = nSubRow + 1;
                    subjFit(nSubRow).SubjCode = {thisSubj};
                    subjFit(nSubRow).Event = {thisEvent};
                    subjFit(nSubRow).Component = {thisComp};
                    subjFit(nSubRow).Hemisphere = {thisLR};
                    subjFit(nSubRow).Channels = {theCentChan};
                    subjFit(nSubRow).AllTrial = {isCorStr};
                    subjFit(nSubRow).Model = {model};
                    subjFit(nSubRow).mu = mu;
                    subjFit(nSubRow).sigma = sigma;
                    subjFit(nSubRow).tau = tau;
                    subjFit(nSubRow).Iterations = output.iterations;
                    subjFit(nSubRow).funcCount = output.funcCount;
                    subjFit(nSubRow).Algorithm = output.algorithm;
                    subjFit(nSubRow).Message = {output.message};
                                          
                end
                
                clear subjCond
                clear nSubjCond
                clear thisSubj
   
                %% fit the ex-guassian distribution for every condition 
      
                % calculate the face specific peak
                isFaceEvent = thisEvent(2) == 'F';
                if isFaceEvent
                    subjCodeFace = unique(trialMeanAmp.SubjCode);
                    theHouseEvent = strrep(thisEvent, 'F', 'H');
                    
                    [tempImage, clusterHosueData] = erp_erpimage(trialTable, theCentChan, ...
                        plotWindow, theHouseEvent, thisAcc, [], [], isCluster);
                    close(tempImage);
                    
                    clsuterHousePeak = st_meanamp(clusterHosueData, tw, thisComp);
                    %                     clsuterHousePeak = erp_peakoutput(clusterHosueData, timeWindow, 1);
                    
                    [G, SubjCodeHouse] = findgroups(clsuterHousePeak.SubjCode);
                    Amplitude = splitapply(@mean, clsuterHousePeak.MeanAmp, G);
                    thisHouseTable = table(SubjCodeHouse, Amplitude);
                    
                    fprintf('The number of participants in this condition is %d.\n', length(subjCodeFace));
                    faceSpecPeak = table;
                    for iSubj = 1:length(subjCodeFace)
                        thisSubjFace = subjCodeFace{iSubj};
                        
                        thisFaceSpecPeak = trialMeanAmp(strcmp(trialMeanAmp.SubjCode, thisSubjFace), :);
                        
                        if ismember(thisSubjFace, SubjCodeHouse)
                            houseAmp = thisHouseTable{strcmp(thisHouseTable.SubjCodeHouse, thisSubjFace), 2};
                        else
                            houseAmp = 0;
                        end
                        
                        thisFaceSpecPeak.faceSpecMeanAmp = thisFaceSpecPeak.MeanAmp ...
                            - houseAmp;
                        
                        faceSpecPeak = vertcat(faceSpecPeak, thisFaceSpecPeak); %#ok<AGROW>
                        
                        if size(faceSpecPeak, 1) > size(trialMeanAmp, 1)
                            warning('something is wrong with faceSpecPeak');
                        end
                        
                    end
                    
                    disOutput = [0, 1];
                else
                    disOutput = 0;
                end
                
                % save the distributions
                for iFaceSpec = disOutput %%%%%%%%%%%%%%%%%%%%%%
                    
                    if iFaceSpec
                        disTitle = ['FaceSpec-' figTitle];
                        meanAmpData = faceSpecPeak.faceSpecMeanAmp;
                    else
                        disTitle = figTitle;
                        meanAmpData = trialMeanAmp.MeanAmp;
                    end
                                        
                    fprintf(['The number of data points used for plotting ' ...
                        '%s is %d.\n'], disTitle, length(meanAmpData));
                    
                    fprintf(['\n' repmat('%%', 1, 50) '\n' ...
                        'Fitting the ex-Gaussian model for the ' figTitle ' condition...\n']);
                    if length(meanAmpData) <= 1
                        model = 'Only one data point';
                        mu = NaN;
                        sigma = NaN;
                        tau = NaN;
                        output.iterations = NaN;
                        output.funcCount = NaN;
                        output.algorithm = '';
                        output.message = 'Only one data poin for this bin.';
                    else
                        
                        [mu, sigma, tau, model, ~, ~, output, fitfig] = erp_eg_fitplot(meanAmpData);
                        
                        title(disTitle)
                        saveas(fitfig, [conFitFolder 'Distribution-', disTitle '.jpg']);
                    end
                    
                    nConRow = nConRow + 1;
                    conFit(nConRow).Event = {thisEvent};
                    conFit(nConRow).Component = {thisComp};
                    conFit(nConRow).Hemisphere = {thisLR};
                    conFit(nConRow).Channels = {theCentChan};
                    conFit(nConRow).AllTrial = {isCorStr};
                    conFit(nConRow).isFaceSpec = iFaceSpec;
                    conFit(nConRow).Model = {model};
                    conFit(nConRow).mu = mu;
                    conFit(nConRow).sigma = sigma;
                    conFit(nConRow).tau = tau;
                    conFit(nConRow).Iterations = output.iterations;
                    conFit(nConRow).funcCount = output.funcCount;
                    conFit(nConRow).Algorithm = output.algorithm;
                    conFit(nConRow).Message = {output.message};
                    
                end
            end
        end
    end
end


%% save the exgaussian output table
subjFitTable = struct2table(subjFit);
conFitTable = struct2table(conFit);
save([studyPath expCode '_' partCode '_exGaussian_Output'], 'subjFitTable', 'conFitTable', 'partCode');

% save the file as *.csv
if ispc || ismac
    subjFitTable = subjFitTable(:, 1:end-1);
    conFitTable = conFitTable(:, 1:end-1);
    writetable(subjFitTable, [partCode '_Subj_Output.csv']);
    writetable(conFitTable, [partCode '_ConFitTable.csv']);
end

Ntotal = nEvent/4;
fprintf('\nMission (Fitting model) Completed for %s/%d of the Experiment %s.\n', partCode, Ntotal, expCode);
end