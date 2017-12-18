%% save the cluster ERP figure into PDF file and output the data for clusters
% input info

experimentNum = EEG(1).filename(2);

switch experimentNum
    case '1'
        windowsInfo = [76,132;   % time window for P1
                      144,172];    % time window for N170
        electrode = [65 90 58 96];
    case '2'
        windowsInfo = [68,124;   % time window for P1
                      136,156];    % time window for N170
        electrode = [65, 90, 64, 95];  
    case '3'
        windowsInfo = [96,124;   % time window for P1
                      144,212];    % time window for N170
        electrode = [90 65 95 64];
    case '4'
end

numElec = length(electrode);
expFolder = ['20', experimentNum];

for iElec = 1: numElec
    thisElec = electrode(iElec);

    createFigure(STUDY,ALLEEG,thisElec,1,1,1)

    figureName = [expFolder, '_Cluster_', num2str(thisElec)];  % Scramble_  Normal_
    print(figureName, '-dpdf', '-bestfit'); 
    close(2);
    
end

disp('Done!');



%%
elecNum = 90;
isCluster = 1;
outputClusterData = 1;
diffNS = 1;
