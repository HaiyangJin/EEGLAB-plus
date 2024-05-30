function EEG = eeg_loadcnt(cntfile, saveset)
% EEG = eeg_loadcnt(cntfile, saveset)
%
% Load and append cnt files (from Neuroscan).
%
% Inputs:
%    cntfile     <str> wildcard string to be used to identify the cnt files
%                 to be loaded. 
%             OR <cell str> cnt files to be loaded.
%    saveset     <boo> whether to save the loaded and appended data
%                 locally. Default to 1 (true).
%
% Output:
%    EEG         <struct> the output EEG data.
%
% Created by Haiyang Jin (2024-May-30)

%% Deal with inputs
if ~exist('saveset', 'var') || isempty(saveset)
    saveset = 1;
end

% identify cnt files to be loaded
if iscell(cntfile)
    % make sure all input files exist
    tmpexist = cellfun(@(x) logical(exist(x, "file")), cntfile);
    assert(all(tmpexist), 'Not all files in cntfile are available.')

    cntfiles = cntfile;
else
    % find all matching files
    dirlist = dir(cntfile);
    cntfiles = fullfile({dirlist.folder}, {dirlist.name})';    
end

% make sure the (first) file is cnt file
[cntdir, cntfn, cntext] = fileparts(cntfiles{1});
assert(strcmp(cntext, '.cnt'), 'The first input file is not a cnt file.')

%% Load and append data
ALLEEG = cellfun(@(x) pop_loadcnt(x, 'dataformat', 'auto', 'memmapfile', ''), ...
    cntfiles, 'uni', true);

EEG = pop_mergeset(ALLEEG, 1, 0);

%% Save data locally
if saveset
    EEG = pop_saveset(EEG, 'filename',[cntfn '_raw.set'], 'filepath',cntdir);
end

end