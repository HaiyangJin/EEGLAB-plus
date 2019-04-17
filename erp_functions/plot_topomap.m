function plot_topomap(topodata_table, foldername, timeWindow, lagForVideo, locfile)
% Plot the topo map separately or for further creating topo Video
ampLimits = [-4 4];

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
if ~exist(foldername, 'dir')
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

frames = timeWindow(1) : lagForVideo * lag : timeWindow(2);
for iFrame = frames
    
    thisMoment = xposition(variableNames, iFrame);
    thisFrameData = topodata{:, thisMoment};

    f=figure; topoplot(thisFrameData, locfile, ...
        'maplimits', ampLimits,...
        'electrodes', 'off');
    title([num2str(iFrame), ' ms'], 'FontSize', 18);

    frameName = xconverter(iFrame);
    thisFn = [foldername, filesep, sprintf([foldername '_%s.png'], frameName{1})];
	print(thisFn, '-dpng'); %save as png
    
    png_trans(thisFn, 1); % resave the image with transparent background
    
	close(f);  % close current figure
end

fprintf('Save %d frame topo maps successfully!\n', length(frames));

end