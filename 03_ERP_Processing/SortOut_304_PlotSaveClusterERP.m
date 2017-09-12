%% save the cluster ERP figure into PDF file
% input info

electrode = [65 90 58 96];
numElec = length(electrode);
expFolder = ['20', EEG(1).filename(2)];

for iElec = 1: numElec
    thisElec = electrode(iElec);
%     createFigure(STUDY,ALLEEG,thisElec,1);
    createFigure(STUDY,ALLEEG,thisElec,1,1);

    figureName = [expFolder, '_Cluster_', num2str(thisElec)];  % Scramble_  Normal_
    print(figureName, '-dpdf', '-bestfit'); 
    close(2);
    
end

disp('Done!');
    

