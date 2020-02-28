function joint_table = join_stmeanamp_stimuli(ST_table, behavior_table, stimOnly)
% behavior_table should include a column called trialNum

if nargin < 3 || isempty(stimOnly)
    stimOnly = 1;
end

%% Preprocesse the behavior data
% remove data for practice trials
behavior_table = behavior_table(~isnan(behavior_table.durationID), :);
behavior_table.SubjCode = arrayfun(@(x) ['P' num2str(x)], behavior_table.Subject, 'UniformOutput', false);

tmpSubj = num2str(behavior_table{1, 'Subject'});
expCode = tmpSubj(1);
if strcmp(expCode, '4') % Recording erruptted for two participants (restarted later).
    isBad426 = (behavior_table.Subject == 426) & (behavior_table.Block == 6);
    isBad428 = (behavior_table.Subject == 428) & behavior_table.Session == 2 & strcmp(behavior_table.scrambleVar, 'S');
    
    behavior_table = behavior_table(~(isBad426 | isBad428), :);
elseif strcmp(expCode, '5')
    isBad = behavior_table.Subject == 500;
    behavior_table = behavior_table(~isBad, :);
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

if stimOnly
    coluNames = {'SubjCode', 'TrialNumber', 'Session', 'Block', 'Trial', ...
        'Resp_ACC', 'Resp_OnsetDelay', 'Resp_RT', 'stimName'};
    if strcmp(expCode, '5')
        beha_table = beha_table(:, {'SubjCode', 'TrialNumber', 'Session', 'Block', 'Trial', ...
            'Resp_ACC_Trial_', 'Resp_OnsetDelay_Trial_', 'Resp_RT_Trial_', 'stimName_Trial_'});
        beha_table.Properties.VariableNames = coluNames;
    else
        beha_table = beha_table(:, coluNames);
    end
end


%% Link the mean amplitude and behavior data
joint_table = join(ST_table, beha_table, 'key', {'SubjCode', 'TrialNumber'});


end