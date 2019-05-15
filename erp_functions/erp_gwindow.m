function [gwinTable, zeroTable] = erp_gwindow(gmeanTable, method, windowSize, isPlot, funvar, assumedWin)
% calculate the time windows for grand average
% windowSize: how large the grand mean time window should be? [min max step](ms)
%             windowSize = [] means no limit
% method: '1--ratio' or '2--fixWin'
%         'ratio': locate the peak value, and use the time points of the
%         ratio (e.g. 0.5, funvar) of amplitude as the time window.
%         'fixWin': locate the peak value, and use the time points of peak
%         minus and plus half fix window size as the time window.
% assumedWin: should be a cell, every row is for one component. The first
%             column is the name of the component (start with N or P). The
%             second and third columns are the aussmed start and end of
%             time windows.
% funvar: if method is 'ratio' (1), funvar refers to ratioPeak
%         if method is 'meanAmp' (2), funvar refers to nothing
%         if method is 'localMeanAmplitude' (3), funvar refers to the widow
%         size

if nargin < 2 || isempty(method)
    method = 1;
end
if nargin < 3 && method == 1
    windowSize = [36 40 .1];  % [min max]
else
    windowSize = [];
end
if nargin < 4 || isempty(isPlot)
    isPlot = 1;
end
if nargin < 5 || isempty(funvar)
    funvar = [];
end
if nargin < 6
    assumedWin = [];
end


%% Locating the time points where amplitudes are around 0
zeroTable = erp_baselinezero(gmeanTable, assumedWin);

%% calculate the time windows
% get the maximum amplitude in the frame time window and locate the latency
% for half (or specified by user). Save it as the time window for further
% analysis

nComp = size(zeroTable, 1);
% tw = struct; % time window structure
clear tw

for iComp = 1:nComp
    
    thisFunvar = funvar;
    
    if size(gmeanTable, 1) == 1
        igmean = 1;
    else
        igmean = iComp;
    end
    
    theEpochData = gmeanTable(igmean, :);
    checkWindow = zeroTable{iComp, {'windowStart', 'windowEnd'}};
    
    thisComp = zeroTable{iComp, 1};
    if iscell(thisComp); thisComp = thisComp{1}; end
    
    if ~isempty(windowSize)
        winMin = windowSize(1);
        winMax = windowSize(2);
        winStep = windowSize(3);
    end
    isWhile = 1;
    Nwhile = 0;
    funvarList = zeros(1, 3);

    while isWhile && Nwhile < 1000
        
        thisTW = erp_window(theEpochData, checkWindow, thisComp, method, thisFunvar);
        
        if ~isempty(windowSize)  % only test the window size for method 1 if necessary
            Nwhile = Nwhile + 1;

            if isempty(thisFunvar)
                funvarList(Nwhile) = 0; 
            else
                funvarList(Nwhile) = thisFunvar; 
            end
            
            isSmall = thisTW.WindowSize < winMin;
            isLarge = thisTW.WindowSize > winMax;
            
            if isSmall || isLarge
                
                if thisTW.StartFrame == checkWindow(1) && thisTW.EndFrame == checkWindow(2)
                    thisFunvar = 1.5;
                else
                    isConsistent = thisTW.PeakAmplitude > 0 == thisTW.IsPositive;
                    thisFunvar = thisTW.RatioForPeak + winStep * (isLarge - .5) * 2 * (isConsistent-.5) * 2; % (.5 - isSmall) * 2
                end
                
                if funvarList(end-1) == thisFunvar
                    winStep = winStep / 2;
                end
                
                warning(['The size of window frames for %s is %d.\n' ...
                    'The size of window times for %s is %d.\n' ...
                    'Re-computing with ratio of %d...'], ...
                    thisTW.Component, thisTW.FrameSize, ...
                    thisTW.Component, thisTW.WindowSize, ...
                    thisFunvar);
                
            else
                isWhile = 0; % stop the while loop
                
            end
        else
            isWhile = 0;
        end
        
    end
    
    tw(iComp) = thisTW; %#ok<AGROW>
    
        fprintf(['The size of window frames for %s is %d.\n' ...
        'The size of window times for %s is %d.\n'], ...
        tw(iComp).Component, tw(iComp).FrameSize, ...
        tw(iComp).Component, tw(iComp).WindowSize);
    
end

gwinTable = horzcat(struct2table(tw), zeroTable(:, 'nTrans'));


%% Plot the grand average ERP and the time windows
if isPlot
    methodCell = {'ratio', 'fixedWin', 'EvenWinAroundPeak'};
    % Plot the grand average of the data for this component
    % Mark the time window
    gfigure = figure('NumberTitle', 'off', 'Name', 'Locking Time Window Based on the Grand Average ERP',...
        'Renderer', 'painters', 'Position', [100 100 1000 700]);
    xStart = -200;
    xEnd = 996; % 500;
    xNames = gmeanTable.Properties.VariableNames;
    [yStart, ~, lagFrame] = xposition(xNames, xconverter(xStart));
    yEnd = xposition(xNames, xconverter(xEnd));
    yERP = gmeanTable{:, yStart: yEnd};
    xERP = xStart:lagFrame:xEnd;
    x0Axis = zeros(1, length(xERP));
    plot(xERP, yERP);  % plot the ERP data , '-k'
    
    y1=get(gca,'ylim');
    hold on
    tws = gwinTable{:, {'StartTime', 'EndTime'}};
    %     plot(repmat(tw(:), 1, 2), repmat(y1, 4, 1), ':r');
    plot(repmat(tws(:)', 2, 1), repmat(y1', 1, size(tws, 1)*2), '-r', 'LineWidth',1);
    plot(xERP, x0Axis, '--k');  % plot the horizontal line
    plot([0 0], y1, '--k');  % plot the veritical line
    
    set(gca,'FontSize',12)
    if size(gmeanTable.ChanCent, 2) == 2
        legends = cellfun(@(x,y,z) sprintf('%s-%s-%s', x, y, z), gmeanTable.Component,...
            gmeanTable.ChanCent(:,1), gmeanTable.ChanCent(:,2), 'UniformOutput', false);
    else
        legends = cellfun(@(x,y) sprintf('%s-%s-%s', x, y), zeroTable.Component,...
            gmeanTable.ChanCent(:,1), 'UniformOutput', false);
    end
    legend(legends);
    xlabel('Time Points (ms)', 'FontSize', 14);
    ylabel('Amplitude (\muV)', 'FontSize', 14);
    title(['Locking Time Window Based on the Grand Average ERP -- ' methodCell{method}], 'FontSize', 16);
    saveas(gfigure, 'TimeWindowforGrandAvg.jpg');
end

end
%
% gwinTable = erp_gwindow_ratio(gmeanTable, zeroTable, isPlot, funvar);
% gwinTable = erp_gwindow_fixWin(gmeanTable, zeroTable, isPlot, funvar);



%% Method 1
% grandAvg(table): the grand average of all of the epoch data (generated by
%                  erp_grandmean.m
% ratioPeak(numeric(0~1)): the percentage of the peak amplitude will be used to calculate
%                          the window size
% assumedTimeWindow(cell): the assumed time windows at the very beginning for
%                          each component. Each row is for one component
%                          and the first column are the names of the
%                          component, the second and the third columns are
%                          the assumed start and end time points (ms).

% This script aims to get the time window for the grand average data.
% Firstly, it select the maximum (P1) and minmum (N170) amplitude for
% a large window. Then find the time points for half of the peak amplitude.
% These time points are the boundary of the time window.
% Grand Mean ==> Peak (Amplitude)  ==> Time points for half (or other ratio) Amplitude

% author: Haiyang Jin (hjin317@aucklanduni.ac.nz)

%% Method 2
