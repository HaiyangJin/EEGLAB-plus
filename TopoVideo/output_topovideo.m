function topovideo_table = output_topovideo(expCode, saveData, isReject, fnExtra)
% output the data for plotting topo map or topo video

if nargin < 2
    saveData = 1;
end
if nargin < 3
    isReject = 1;
end

if ispc || ismac
    studyPath = uigetdir(pwd, ...
        'Please select the study folder:');
else
    Mahuika;
    studyPath = [projectPath expCode filesep '04_PreProcessed_Individual' fnExtra filesep];
end
fprintf('The study path is:\n%s\n', studyPath);
cd(studyPath);

trialTable = st_trialmulti('.', [], [], isReject);

[~, isDataColu] = xposition(trialTable.Properties.VariableNames);

[G, Channel, Event, urResponse, SubjCode] = findgroups(trialTable.Channel, trialTable.Event, ...
    trialTable.urResponse, trialTable.SubjCode);

DV = splitapply(@(x) mean(x, 1), trialTable{:, isDataColu}, G);
Count = splitapply(@(x) size(x, 1), trialTable.P0, G);

IV_table = table(Channel, Event, urResponse, SubjCode, Count);
DV_table = array2table(DV, 'VariableNames', trialTable.Properties.VariableNames(isDataColu));

topovideo_table = [IV_table, DV_table];
disp('Topo video data are calculated successfully!');

if saveData
    fn_topovideo = [expCode, '_TopoVideoTable'];
    save(fn_topovideo, 'topovideo_table');
    disp('Topo video data are saved successfully!');
end

end