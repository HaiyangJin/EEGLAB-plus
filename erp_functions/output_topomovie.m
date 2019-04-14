function topomovie_table = output_topomovie(expCode, saveData)
% output the data for plotting topo map or topomovie

if nargin < 2
    saveData = 1;
end

if ispc || ismac
    studyPath = uigetdir(pwd, ...
        'Please select the study folder:');
else
    Mahuika;
    studyPath = [projectPath expCode filesep '04_PreProcessed_Individual_All' filesep];
end
cd(studyPath);

trialTable = st_trialmulti;

[~, isDataColu] = xposition(trialTable.Properties.VariableNames);

[G, Channel, Event, urResponse, SubjCode] = findgroups(trialTable.Channel, trialTable.Event, ...
    trialTable.urResponse, trialTable.SubjCode);

DV = splitapply(@(x) mean(x, 1), trialTable{:, isDataColu}, G);
Count = splitapply(@(x) size(x, 1), trialTable.P0, G);

IV_table = table(Channel, Event, urResponse, SubjCode, Count);
DV_table = array2table(DV, 'VariableNames', trialTable.Properties.VariableNames(isDataColu));

topomovie_table = [IV_table, DV_table];
disp('Topo movie data are calculated successfully!');

if saveData
    fn_topomovie = [expCode, '_TopoMovieTable'];
    save(fn_topomovie, 'topomovie_table');
    disp('Topo movie data are saved successfully!');
end

end