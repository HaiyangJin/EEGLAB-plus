function joint_table = join_stmeanamp_stimuli(ST_table, behavior_table)
% behavior_table should include a column called trialNum

%% Preprocesse the behavior data
% remove data for practice trials
behavior_table = behavior_table(~isnan(behavior_table.durationID), :);
behavior_table.SubjCode = arrayfun(@(x) ['P' num2str(x)], behavior_table.Subject, 'UniformOutput', false);

tmpSubj = behavior_table{1, 'Subject'};
if strcmp(tmpSubj(1), '4') % Recording erruptted for two participants (restarted later).
    isBad426 = (behavior_table.Subject == 426) & (behavior_table.Block == 6);
    isBad428 = (behavior_table.Subject == 428) & behavior_table.Session == 2 & strcmp(behavior_table.scrambleVar, 'S');
    
    behavior_table = behavior_table(~(isBad426 | isBad428), :);
end

% reorder the behavioral table (with trial number (order))
beha_table = sortrows(behavior_table, {'Subject', 'Session', 'Block', 'Trial'});


% calculate the trialNum
G_subj = findgroups(beha_table.Subject);
totalTrialNum = splitapply(@length, beha_table.Subject, G_subj); 
trialNumArray = arrayfun(@(x) (1:x), totalTrialNum, 'UniformOutput', false);
trialNum = [];
for iSubj = 1 : length(totalTrialNum)
    thistrialnum = trialNumArray{iSubj, 1}';
    trialNum = [trialNum; thistrialnum]; %#ok<AGROW>
end
beha_table.TrialNumber = trialNum;


%% Link the mean amplitude and behavior data
joint_table = join(ST_table, beha_table, 'key', {'SubjCode', 'TrialNumber'});


end