if strcmp(subjCode, 'P500')
    % append data in for P500
    nBlock = 0;
    for iName = {'P5001', 'P5002'}
        
        for iBlock = 1:3
            % the file name of this segment
            tempRawName = [iName{1}, '00', num2str(iBlock) '.RAW'];
            
            % read this segment data
            EEG = pop_readegi([expFolderPath, tempRawName], [],[],'auto');
            
            % save the new data set
            tempFileName = tempRawName(1:find(tempRawName == '.')-1);
            [ALLEEG, ~] = pop_newset(ALLEEG, EEG, nBlock, 'setname', tempFileName,'savenew', tempFileName,'gui','off');
            nBlock = nBlock + 1;
        end
    end
    
    % append the data
    EEG = pop_mergeset(ALLEEG, 1:nBlock-1, 0);
    
elseif strcmp(subjCode, 'P503')
    numBlocks = 4;
    % Append data for P503
    for iBlock = 1:numBlocks+1+1
        % the file name of this segment
        if iBlock <= 4
            tempRawName = [subjCode, '00', num2str(iBlock) '.RAW'];
        else
            tempRawName = [subjCode, '0200' num2str(iBlock-4) '.RAW'];
        end
        
        % read this segment data
        EEG = pop_readegi([expFolderPath, tempRawName], [],[],'auto');
        
        % save the new data set
        tempFileName = tempRawName(1:find(tempRawName == '.')-1);
        [ALLEEG, ~] = pop_newset(ALLEEG, EEG, iBlock-1, 'setname', tempFileName,'savenew', tempFileName,'gui','off');
        
    end
    
    % append the data
    EEG = pop_mergeset(ALLEEG, 1:iBlock, 0);
    
else
    % Append data in E204
    numBlocks = 4;
    for iBlock = 1:numBlocks+1
        % the file name of this segment
        if iBlock ~= 5
            tempRawName = [subjCode, '00', num2str(iBlock) '.RAW'];
        else
            tempRawName = [subjCode, '2002.RAW'];
        end
        
        % read this segment data
        EEG = pop_readegi([expFolderPath, tempRawName], [],[],'auto');
        
        % save the new data set
        tempFileName = tempRawName(1:find(tempRawName == '.')-1);
        [ALLEEG, ~] = pop_newset(ALLEEG, EEG, iBlock-1, 'setname', tempFileName,'savenew', tempFileName,'gui','off');
        
    end
    
    % append the data
    EEG = pop_mergeset(ALLEEG, 1:iBlock, 0);
    
    
end
