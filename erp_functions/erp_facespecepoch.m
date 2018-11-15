<<<<<<< refs/remotes/origin/master
function specEpochTable = erp_facespecepoch(epoch_table)

% remove the incorrect trials
isResp = max(cellfun(@length, epoch_table.Event)) > 4;

if isResp
    is
    isIncor = cellfun(@(x) strcmp(x(end), '0'), epoch_table.Event);
    epoch_table = epoch_table(~isIncor, :);
end

=======
function specEpochTable = erp_facespecepoch(allEpoch)
>>>>>>> First commit from Gitkraken


%% Method 1
% Specific face epoch data 
<<<<<<< refs/remotes/origin/master
isFace = cellfun(@(x) strcmp(x(2), 'F'), epoch_table{:, 'Event'});
[~, isDataColu] = xposition(epoch_table.Properties.VariableNames);
faceEpoch = epoch_table{isFace, isDataColu};  % epoch data for Face
houseEpoch = epoch_table{~isFace, isDataColu};  % epoch data for House
=======
isFace = cellfun(@(x) strcmp(x(2), 'F'), allEpoch{:, 'Event'});
faceEpoch = allEpoch{isFace, 6:end};  % epoch data for Face
houseEpoch = allEpoch{~isFace, 6:end};  % epoch data for House
>>>>>>> First commit from Gitkraken

specfaceEpoch = faceEpoch - houseEpoch;

% Independent variables
<<<<<<< refs/remotes/origin/master
specIV1 = epoch_table{isFace, 1:2};
specIV2 = cellfun(@(x) [x(1), 'D', x(3:end)], epoch_table{isFace, 3}, 'UniformOutput', false);
% specIV3 = epoch_table{isFace, 4:5};

specCell_v1 = [specIV1, specIV2, num2cell(specfaceEpoch)];

specEpochTable = cell2table(specCell_v1, 'VariableNames', epoch_table.Properties.VariableNames);
=======
specIV1 = allEpoch{isFace, 1:2};
specIV2 = cellfun(@(x) [x(1), 'D', x(3:end)], allEpoch{isFace, 3}, 'UniformOutput', false);
specIV3 = allEpoch{isFace, 4:5};

specCell_v1 = [specIV1, specIV2, specIV3 num2cell(specfaceEpoch)];

specEpochTable = cell2table(specCell_v1, 'VariableNames', allEpoch.Properties.VariableNames);
>>>>>>> First commit from Gitkraken


%% Method 2
% subj = unique(allEpoch{:, 'SubjCode'});
% chan = unique(allEpoch{:, 'Channel'});
% event = unique(allEpoch{:, 'Event'});
% comp = unique(allEpoch{:, 'Component'});
% hemi = unique(allEpoch{:, 'Hemisphere'});
% 
% specCell = cell(size(allEpoch, 2), size(allEpoch, 1)/2);
% specEpochTable1 = table;
% 
% for iSubj = 1:length(subj)
%     thisSubj = subj(iSubj);
%     
%     for iChan = 1:length(chan)
%         thisChan = chan(iChan);
%         
%         for iComp = 1:length(comp)
%             thisComp = comp(iComp);
%             
%             this = strcmp(allEpoch{:, 'SubjCode'}, thisSubj) .* ...
%                 strcmp(allEpoch{:, 'Channel'}, thisChan) .* ...
%                 strcmp(allEpoch{:, 'Component'}, thisComp); 
%                 
%             tempData = allEpoch(logical(this), :);
%             
%             isFace = cellfun(@(x) strcmp(x(2), 'F'), tempData{:, 'Event'});
%             faceEpoch = tempData{isFace, 6:end};  % epoch data for Face
%             houseEpoch = tempData{~isFace, 6:end};  % epoch data for House
%             
%             specfaceEpoch = faceEpoch - houseEpoch;
%             
%             % Independent variables
%             specIV1 = tempData{isFace, 1:2};
%             specIV2 = cellfun(@(x) [x(1), 'D', x(3:4)], tempData{isFace, 3}, 'UniformOutput', false);
%             specIV3 = tempData{isFace, 4:5};
%             
%             specCell_v1 = [specIV1, specIV2, specIV3 num2cell(specfaceEpoch)];
%             
%             tempEpochTable = cell2table(specCell_v1, 'VariableNames', tempData.Properties.VariableNames);
% 
%             specEpochTable1 = [specEpochTable1; tempEpochTable];
%             
%         
% 
%         end
%     end
% end
% 
% 
% %% Compare the two if they are the same
% table1 = sortrows(specEpochTable1, 1:5);
% table2 = sortrows(specEpochTable, 1:5);
% isequal(table1, table2)