function st_analysis(expCode, partCode, parameters, saveAmpData, saveBinEpoch, isDistAna, toSaveFigure)

fprintf([repmat('=', 1, 60) '\n' ...
    'Fitting models for the Part %s... \n' ...
    repmat('=', 1, 60) '\n\n'], partCode);

if nargin < 3
    error('Not enough arguments for st_analysis!');
end

arguments = isfield(parameters, {'isCluster', 'isgwindow', 'isDenoise', ...
    'isColorbar', 'plotWindow'});

if ~arguments(1)
    isCluster = 1;
else
    isCluster = parameters.isCluster;
end
if ~arguments(2)
    isgwindow = 1;
else
    isgwindow = parameters.isgwindow;
end
if ~arguments(3)
    isDenoise = 1;
else
    isDenoise = parameters.isDenoise;
end
if ~arguments(4)
    isColorbar = 0;  % Do not plot
else
    isColorbar = parameters.isColorbar;
end
if ~arguments(5)
    plotWindow = [-200 996];
    %     warning('The default plot window (%d : %d) is used.', plotWindow);
else
    plotWindow = parameters.plotWindow;
end

if nargin < 4 || isempty(saveAmpData)
    saveAmpData = 1;
end
if nargin < 5 || isempty(saveBinEpoch)
    saveBinEpoch = 1;
end
if nargin < 6 || isempty(isDistAna)
    isDistAna = 0;
end
if nargin < 7 || isempty(toSaveFigure)
    toSaveFigure = 0;
end

if saveAmpData
    ST_MeanAmpTable = table;
end
if saveBinEpoch
    ST_BinEpochTable = table;
end

fprintf(['\n' repmat('=', 1, 60), ...
    '\nSettings used in this single trial analysis:\n' ...
    '  The Experiment Code: %s; \n' ...
    '  isCluster = %d; (1: cluster (7 channels); 2: only one channel)\n' ...
    '  isgwindow = %d; (1: time window from grand average; 2: time window from every condition)\n' ...
    '  isDenoise = %d; (0: raw data; 1: denoised data)\n' ...
    '  isColorbar = %d; (0: no color bar; 1: reaction time; 2: subject code)\n' ...
    '  plotWindow = %d:%d; \n'...
    repmat('=', 1, 60), '\n'], ...
    expCode, isCluster, isgwindow, isDenoise, isColorbar, plotWindow);

paraCode = strrep(num2str([isCluster isgwindow isDenoise  isColorbar]), ' ', '');

if ispc || ismac
    studyPath = uigetdir(pwd, ...
        'Please select the study folder:');
else
    Mahuika;
    studyPath = [projectPath expCode filesep '04_PreProcessed_Individual_All' filesep];
end
cd(studyPath);


%% Create folder for saving output images
if toSaveFigure
    erpimageFolder = [paraCode '_ST_erpimage' filesep];
    if ~exist(erpimageFolder, 'dir')
        mkdir(erpimageFolder);
    end
    
    subjFitFolder = [paraCode '_ST_SubFit' filesep];
    if ~exist(subjFitFolder, 'dir')
        mkdir(subjFitFolder);
    end
    
    binFitFolder = [paraCode '_ST_BinFit' filesep];
    if ~exist(binFitFolder, 'dir')
        mkdir(binFitFolder);
    end
end


%% Locate and load the time window files
% twFile = dir('finalTW');
% load([twFile.path filesep twFile.name]);
load('finalTW');
fprintf('\nLoading the time window information...\n');
if isgwindow
    tw = gwindowTable;
else
    tw = conWindowTable;
end


%% Load all the trial epoch data
fprintf('Reading the raw trial data...\n');
channels = unique(tw.ChanCluster(:));
rawTrialTable = st_trialmulti('.', channels); %

% correct the RT, as there is a offset of about 33ms (comparing with
% E-prime results)
rawTrialTable.RTBackup = rawTrialTable.RT;
rawTrialTable.RT = rawTrialTable.urRT - 33;

if isDenoise
    fprintf('\nPreparing for denoising the raw trial erp data...\n');
    denoiseFolder = ['Denoise_' paraCode filesep];
    if ~exist(denoiseFolder, 'dir')
        mkdir(denoiseFolder);
    end
    cd(denoiseFolder);
    [trialTable, noiseTable] = erp_denoisest(rawTrialTable, expCode);
    cd ..
else
    trialTable = rawTrialTable;
end

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
if ~strcmp(expCode, '205')
    respCode = {[], '0', '1'};  % all the trials, incorrect trials, and correct trials
else
    respCode = {[], '11', '12', '13', '14', '15', '51', '52', '53', '54', '55'};
end
respStr = horzcat('all', cellfun(@(x) ['RESP' x], respCode(2:end), 'UniformOutput', false));

if isCluster; clusterStr = 'Cluster'; else clusterStr = 'SingleChannel'; end %#ok<SEPEX>
subjFit = struct;
nSubRow = 0;
binFit = struct;
nBinRow = 0;

switch length(partCode)
    case 1
        eventRange = (1:4) + (str2double(partCode) - 1) * 4; % (1:nEvent/2) + nEvent/2 * NS
        Ntotal = nEvent/4;
    case 2
        eventRange = str2double(partCode);
        Ntotal = nEvent;
end

for iEvent = eventRange
    thisEvent = event{iEvent};
    
    for iComp = 1:nComp
        thisComp = components{iComp};
        
        for iLR = 1:2
            thisLR = LR{iLR};
            
            theCentChans = tw{iComp, 'ChanCent'};
            theCentChan = theCentChans{iLR};
            
            for iResp = 1:length(respCode)
                thisResp = respCode{iResp};
                thisRespStr = respStr{1, iResp};
                
                %% Plot erp-images
                figTitle = sprintf([repmat('%s-', 1, 5) '%s'], ...
                    thisComp, thisEvent, thisLR, theCentChan, thisRespStr, clusterStr);
                
                fprintf(['\n' repmat('-', 1, 80) '\n' ...
                    'Plotting the ERP-image for the condition: %s...\n'], figTitle);
                
                %%%%%  plot and save the erp images  %%%%%
                [outFigure, clusterTrialTable] = erp_erpimage(trialTable, theCentChan, ...
                    plotWindow, thisEvent, thisResp, [], figTitle, isCluster);
                
                if ~isempty(outFigure) && toSaveFigure
                    %                     saveas(erpfigure, [erpimageFolder 'erpimage-', figTitle '.jpg']);
                    print([erpimageFolder 'erpimage-', figTitle], '-dpng', '-r300');  % '-dtiffn'
                    
                    fprintf(['Successfully plot the ERP-image for condition: %s.\n' ...
                        repmat('-', 1, 80) '\n\n' ], figTitle);
                end
                
                % Denoise the data
                if isDenoise
                    [~, clusterNoiseTable] = erp_erpimage(noiseTable, theCentChan, ...
                        plotWindow, thisEvent, thisResp, [], figTitle, isCluster);
                    if toSaveFigure
                        %                         saveas(erpfigure, [erpimageFolder 'Noise-ERPimages-', figTitle '.jpg']);
                        print([erpimageFolder 'Noise-ERPimages-', figTitle], '-dpng', '-r300');  % '-dtiffn'
                        fprintf(['Successfully plot the Noise ERP-image for condition: %s.\n' ...
                            repmat('-', 1, 80) '\n\n' ], figTitle);
                    end
                end
                
                % only continue when there are some data in the table 
                if ~isempty(clusterTrialTable) 
                    
                    clusterTrialTable.Response = cellfun(@(x) regexp(x, '\d*', 'Match'), clusterTrialTable.urResponse);
                    clusterTrialTable.Hemisphere = repmat({thisLR}, size(clusterTrialTable, 1), 1);
                    clusterTrialTable.Component = repmat({thisComp}, size(clusterTrialTable, 1), 1);

                    if saveBinEpoch && isempty(thisResp)  % only save data when it is for all trials
                        % save the bin epoch table for the current bin
                        ST_BinEpochTable = [ST_BinEpochTable; clusterTrialTable]; %#ok<AGROW>
                    end

                    % calculate the amplitude for every trial and plot the
                    % distribution
                    trialMeanAmp = st_meanamp(clusterTrialTable, tw, thisComp);
                    if isDenoise
                        noiseMeanAmp = st_meanamp(clusterNoiseTable, tw, thisComp);
                    end
                    
                    if saveAmpData && isempty(thisResp) % only save data when it is for all trials
                        % save the mean amplitude for every single trial
                        
%                         trialMeanAmp.Hemisphere = repmat({thisLR}, size(trialMeanAmp, 1), 1);
%                         trialMeanAmp.ACC = repmat({thisAcc}, size(trialMeanAmp, 1), 1);
                        ST_MeanAmpTable = [ST_MeanAmpTable; trialMeanAmp]; %#ok<AGROW>
                    end
                    
                    if isDistAna
                        %% fit ex-gaussian function for every subject (for every bin)
                        %%%%% fit exGaussian and save the parameters %%%%%
                        
                        %%%%% for every participant with loop %%%%%
                        subjBin = unique(trialMeanAmp.SubjCode);  % subject codes in this condition
                        nSubjBin = length(subjBin);
                        
                        for iSubj = 1:nSubjBin
                            thisSubj = subjBin{iSubj};
                            
                            isSubj = strcmp(trialMeanAmp.SubjCode, thisSubj);
                            subjData = trialMeanAmp{isSubj, 'MeanAmp'};
                            
                            if length(subjData) <= 4
                                output.Count = length(subjData);
                                output.model = sprintf('Only %d data point(s)', output.Count);
                                mu = NaN;
                                sigma = NaN;
                                tau = NaN;
                                output.iterations = NaN;
                                output.funcCount = NaN;
                                output.algorithm = '';
                                output.message = sprintf('Only %d data point(s) for this bin.', output.Count);
                            else
                                fprintf(['\n' repmat('%%', 1, 50) '\n' ...
                                    'Fitting the ex-Gaussian model for Participant ' ...
                                    thisSubj ' in the ' figTitle ' condition...\n']);
                                
                                switch isColorbar
                                    case 1
                                        colorData = trialMeanAmp{isSubj, 'RT'};
                                    case 2
                                        colorData = []; % trialMeanAmp{isSubj, 'SubjCode'};
                                    case 0
                                        colorData = [];
                                end
                                
                                [mu, sigma, tau, output] = erp_eg_fitplot(subjData, colorData, plotWindow);
                                
                                if toSaveFigure
                                    subjTitle = [thisSubj '-' figTitle];
                                    title(subjTitle)
                                    %                             saveas(fitfig, [subjFitFolder 'Distribution-', subjTitle '.jpg']);
                                    print([subjFitFolder 'Distribution-', subjTitle], '-dpng', '-r300');  % '-dtiffn'
                                end
                                
                            end
                            
                            % levels of conditions
                            nSubRow = nSubRow + 1;
                            subjFit(nSubRow).SubjCode = {thisSubj};
                            subjFit(nSubRow).Event = {thisEvent};
                            subjFit(nSubRow).Component = {thisComp};
                            subjFit(nSubRow).Hemisphere = {thisLR};
                            subjFit(nSubRow).Channels = {theCentChan};
                            subjFit(nSubRow).AllTrial = {thisRespStr};
                            subjFit(nSubRow).Count = output.count;
                            subjFit(nSubRow).Model = output.model;
                            subjFit(nSubRow).mu = mu;
                            subjFit(nSubRow).sigma = sigma;
                            subjFit(nSubRow).tau = tau;
                            subjFit(nSubRow).Iterations = output.iterations;
                            subjFit(nSubRow).funcCount = output.funcCount;
                            subjFit(nSubRow).Algorithm = output.algorithm;
                            subjFit(nSubRow).Message = {output.message};
                            
                            subjFit(nSubRow).isAd = output.isAd;
                            subjFit(nSubRow).AdP = output.AdP;
                            subjFit(nSubRow).isJb = output.isJb;
                            subjFit(nSubRow).JbP = output.JbP;
                            subjFit(nSubRow).isL = output.isL;
                            subjFit(nSubRow).LP = output.LP;
                            
                        end
                        
                        clear subjBin
                        clear nSubjBin
                        clear thisSubj
                        
                        %% fit the ex-guassian distribution for every bin (across subjects)
                        
                        % calculate the face specific peak
                        disOutput = 0;
                        isFaceEvent = thisEvent(2) == 'F';
                        if isFaceEvent
                            subjCodeFace = unique(trialMeanAmp.SubjCode);
                            theHouseEvent = strrep(thisEvent, 'F', 'H');
                            
                            [tempImage, clusterHosueData] = erp_erpimage(trialTable, theCentChan, ...
                                plotWindow, theHouseEvent, thisResp, [], [], isCluster);
                            close(tempImage);
                            
                            if ~isempty(clusterHosueData)
                                
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
                                        warning('Something is wrong with faceSpecPeak');
                                    end
                                    
                                end
                                
                                disOutput = [0, 1];
                            end
                        end
                        
                        if isDenoise
                            disOutput = [disOutput, 2]; %#ok<AGROW>
                        end
                        
                        % save the distributions
                        for iFaceSpec = disOutput %%%%%%%%%%%%%%%%%%%%%%
                            switch iFaceSpec
                                case 1
                                    disTitle = ['FaceSpec-' figTitle];
                                    meanAmpData = faceSpecPeak.faceSpecMeanAmp;
                                    rtTable = faceSpecPeak;
                                case 0
                                    disTitle = figTitle;
                                    meanAmpData = trialMeanAmp.MeanAmp;
                                    rtTable = trialMeanAmp;
                                case 2
                                    disTitle = ['Noise-' figTitle];
                                    meanAmpData = noiseMeanAmp.MeanAmp;
                                    rtTable = noiseMeanAmp;
                            end
                            
                            fprintf(['The number of data points used for plotting ' ...
                                '%s is %d.\n'], disTitle, length(meanAmpData));
                            
                            fprintf(['\n' repmat('%%', 1, 50) '\n' ...
                                'Fitting the ex-Gaussian model for the ' disTitle ' condition...\n']);
                            
                            if length(meanAmpData) <= 4
                                output.Count = length(meanAmpData);
                                output.model = sprintf('Only %d data point(s)', output.Count);
                                mu = NaN;
                                sigma = NaN;
                                tau = NaN;
                                output.iterations = NaN;
                                output.funcCount = NaN;
                                output.algorithm = '';
                                output.message = sprintf('Only %d data point(s) for this bin.', output.Count);
                            else
                                switch isColorbar
                                    case 1
                                        colorData = rtTable.RT;
                                    case 2
                                        colorData = rtTable.SubjCode;
                                    case 0
                                        colorData = [];
                                end
                                
                                [mu, sigma, tau, output] = erp_eg_fitplot(meanAmpData, colorData, plotWindow);
                                title(disTitle)
                                if toSaveFigure
                                    %                             saveas(fitfig, [conFitFolder 'Distribution-', disTitle '.jpg']);
                                    print([binFitFolder 'Distribution-', disTitle], '-dpng', '-r300');  % '-dtiffn'
                                end
                            end
                            
                            nBinRow = nBinRow + 1;
                            binFit(nBinRow).Event = {thisEvent};
                            binFit(nBinRow).Component = {thisComp};
                            binFit(nBinRow).Hemisphere = {thisLR};
                            binFit(nBinRow).Channels = {theCentChan};
                            binFit(nBinRow).AllTrial = {thisRespStr};
                            binFit(nBinRow).isFaceSpec = iFaceSpec;
                            binFit(nBinRow).Count = output.count;
                            binFit(nBinRow).Model = output.model;
                            binFit(nBinRow).mu = mu;
                            binFit(nBinRow).sigma = sigma;
                            binFit(nBinRow).tau = tau;
                            binFit(nBinRow).Iterations = output.iterations;
                            binFit(nBinRow).funcCount = output.funcCount;
                            binFit(nBinRow).Algorithm = output.algorithm;
                            binFit(nBinRow).Message = {output.message};
                            binFit(nBinRow).isDenoise = isDenoise;
                            
                            binFit(nBinRow).isAd = output.isAd;
                            binFit(nBinRow).AdP = output.AdP;
                            binFit(nBinRow).isJb = output.isJb;
                            binFit(nBinRow).JbP = output.JbP;
                            binFit(nBinRow).isL = output.isL;
                            binFit(nBinRow).LP = output.LP;
                        end
                    end
                end
            end
        end
    end
end


%% save the exgaussian output table
if isDistAna
    subjFitTable = struct2table(subjFit);
    binFitTable = struct2table(binFit);
    save([studyPath expCode '_' paraCode '_' partCode '_exGaussian_Output'], 'subjFitTable', 'binFitTable', 'partCode', 'paraCode');
    
    % save the file as *.csv
    if ispc || ismac
        subjFitTable = subjFitTable(:, 1:end-1);
        binFitTable = binFitTable(:, 1:end-1);
        writetable(subjFitTable, [partCode '_Subj_Output.csv']);
        writetable(binFitTable, [partCode '_BinFitTable.csv']);
    end
end

if saveAmpData
    save([studyPath expCode '_' paraCode '_' partCode '_ST_MeanAmp'], 'ST_MeanAmpTable');
end
if saveBinEpoch
    save([studyPath expCode '_' paraCode '_' partCode '_ST_BinEpoch'], 'ST_BinEpochTable'); 
end

fprintf('\nMission (Fitting model) Completed for %s/%d of the Experiment %s.\n', partCode, Ntotal, expCode);
