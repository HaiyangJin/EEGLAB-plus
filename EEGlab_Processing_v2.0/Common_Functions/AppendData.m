numBlocks = 4;
for iBlock = 1:numBlocks+1
    % the file name of this segment
    if iBlock ~= 5
        tempRawName = [participantName, '00', num2str(iBlock) '.RAW'];
    else
        tempRawName = [participantName, '2002.RAW'];
    end
    
    % read this segment data
    EEG = pop_readegi([expFolderPath, tempRawName], [],[],'auto');
    [ALLEEG, ~] = pop_newset(ALLEEG, EEG, iBlock-1, 'setname', tempRawName,'gui','off');
    
end

% append the data
EEG = pop_mergeset(ALLEEG, 1:iBlock, 0);
    
    