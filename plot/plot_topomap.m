function plot_topomap(topodata_table, foldername, timeWindow, lagForVideo, locfile)
% Plot the topo map separately or for further creating topo Video
ampLimits = [-6 6];

variableNames = topodata_table.Properties.VariableNames;
[~, isDataColu, lag] = xposition(variableNames);
dataNames = topodata_table.Properties.VariableNames(isDataColu);
if size(topodata_table, 1) > 128
    warning('There are more than 128 rows (%d) in the data set!', size(topodata_table, 1));
end
if nargin < 2 || isempty(foldername)
    foldername = 'TopoVideoFrames';
    warning('The default folder (%s) will be used to save frame topo maps!', ...
        foldername);
end
if ~exist(foldername, 'dir') && lagForVideo ~= 0
    mkdir(foldername);
end
if nargin < 3 || isempty(timeWindow)
    timeWindow = xconverter(dataNames([1, end]), 'num');
end
if nargin < 4 || isempty(lagForVideo) || lagForVideo < 0
    lagForVideo = 1;
end
if nargin < 5 || isempty(locfile)
    locfile = 'EGI_128.loc';
end


%% Preparation
% reorder the table based on the channel number
chanNum = cellfun(@(x) str2double(strrep(x, 'E', '')), topodata_table.Channel);
[~, order] = sort(chanNum);
topodata = topodata_table(order, :);

if lagForVideo ~= 0
    % save topo map for each frame
    frames = timeWindow(1) : lagForVideo * lag : timeWindow(2);
    for iFrame = frames
    
    thisMoment = xposition(variableNames, iFrame);
    thisFrameData = topodata{:, thisMoment};

    f=figure; topoplot(thisFrameData, locfile, ...
        'maplimits', ampLimits,...
        'electrodes', 'off');
    title(sprintf([num2str(iFrame), 'ms [%s_ %s]'], num2str(ampLimits(1)), ...
        num2str(ampLimits(2))), 'FontSize', 18);

    frameName = xconverter(iFrame);
    thisFn = [foldername, filesep, sprintf([strrep(foldername, filesep, '_') ...
        '_%s.png'], frameName{1})];
	print(thisFn, '-dpng'); %save as png
    
    png_trans(thisFn, 1); % resave the image with transparent background
    
	close(f);  % close current figure
    end
    
    fprintf('Save %d frame topo maps successfully!\n', length(frames));

else
    % save topo map for the averaged window
    startFrame = xposition(variableNames, timeWindow(1));
    endFrame = xposition(variableNames, timeWindow(2));
    
    thisFrameData = mean(topodata{:, startFrame : endFrame}, 2);
    
    f=figure; topoplot(thisFrameData, locfile, ...
        'maplimits', ampLimits,...
        'electrodes', 'off');
    
    title(sprintf('%s %d-%dms [%d_ %d]',foldername, timeWindow(1), timeWindow(2), ...
        ampLimits(1), ampLimits(2)), 'FontSize', 18);
    
    thisFoldername = [sprintf('%d-%d', abs(ampLimits(1)), ampLimits(2)) filesep...
    sprintf('%d-%d', timeWindow(1), timeWindow(2))];
    
    if ~exist(thisFoldername, 'dir')
        mkdir(thisFoldername);
    end

    thisFn = [thisFoldername filesep, foldername, sprintf( ...
        '_%d-%d.png', timeWindow(1), timeWindow(2))];
	print(thisFn, '-dpng'); %save as png
    
    png_trans(thisFn, 1); % resave the image with transparent background
    
	close(f);  % close current figure
end


end