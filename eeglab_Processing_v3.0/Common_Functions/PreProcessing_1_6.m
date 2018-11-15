%%%% 101 Load raw data and save it
    [ALLEEG , ~, ~, ALLCOM] = eeglab;  % start the eeglab
    pop_editoptions( 'option_storedisk', 1, 'option_savetwofiles', 1, 'option_saveversion6', 1, ...
        'option_single', 0, 'option_memmapdata', 0, 'option_eegobject', 0, 'option_computeica', 1, ...
        'option_scaleicarms', 1, 'option_rememberfolder', 1, 'option_donotusetoolboxes', 0, ...
        'option_checkversion', 1, 'option_chat', 0); % uncheck 'If set, use single precision under...'
    
    if appendNeeded
        AppendData;
    elseif oneRawFile
        rawName = [thisSubjCode, '.RAW'];
        EEG = pop_readegi([expPath, rawName], [],[],'auto');
    else
        rawName = [thisSubjCode, '001.RAW'];
        EEG = pop_readsegegi([expPath, rawName]); %'C:\EEG data\202_EEG&Mask\P021\P021001.RAW')
    end
%     [~, EEG] = pop_newset(ALLEEG, EEG, 1,'setname',rawFilename,'gui','off');
%     EEG = pop_saveset(EEG, 'filename',rawFilename,'filepath',expFolderPath); % save the raw data as backup
    
    %%%% 102 Change time point
    EEG = correctTriggerLatency(EEG,50);
    
    %%%% 103 Re-sample to 250 Hz
    EEG = pop_resample( EEG, 250);
    
    %%%% 104 Filter the data between 1-Hz (high) and 50 Hz (low)
    EEG  = pop_basicfilter( EEG,  1:128 , 'Cutoff', [highFilter(iProcess) 50], ...
        'Design', 'butter', 'Filter', 'bandpass', 'Order',  4, 'RemoveDC', 'on' );
    
    %%%% 105 Import channel info
    EEG = pop_chanedit(EEG, 'load',{strcat(projectPath,'GSN-HydroCel-129.sfp') 'filetype' 'autodetect'},...
        'setref',{'4:132' 'Cz'},'changefield',{132 'datachan' 0});
    
    %%%% 106 Remove line noise using CleanLine
    EEG = pop_cleanline(EEG, 'bandwidth', 2,'chanlist', 1:EEG.nbchan, ...
        'computepower', 0, 'linefreqs', [50 100 150 200 250], 'normSpectrum', 0, ...
        'p', 0.01, 'pad', 2, 'plotfigures', 0, 'scanforlines', 1, 'sigtype', 'Channels',...
        'tau', 100, 'verb', 1, 'winsize', 4, 'winstep', 4);