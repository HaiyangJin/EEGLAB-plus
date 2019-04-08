function conWindowTable = erp_binwindowpeak(conEpochTable, gwindowTable, method, isPlot)
% calculate the (local) mean amplitude for the averaged epoch data for
% every condition

if nargin < 2
    error('Not enough arguments for erp_conwindow!');
end
if nargin < 3 || isempty(method)
    method = 3;
    warning('The default method of (3) local mean amplitude is used.');
elseif method == 1
    warning('The fractional amplitude method is used for epoch of bins.');
end 
if nargin < 4
    isPlot = 0;
end

nRow = size(conEpochTable, 1);

clear tw
for iRow = 1:nRow
    thisConTable = conEpochTable(iRow, :);
    thisComp = thisConTable.Component{1};
    isComp = strcmp(thisComp, gwindowTable.Component);
    
    checkWin = gwindowTable{isComp, {'StartFrame', 'EndFrame'}};

    tw(iRow) = erp_window(thisConTable, checkWin, thisComp, method);   %#ok<AGROW>  
end

[~, isDataColu] = xposition(conEpochTable.Properties.VariableNames);

peakTable = struct2table(tw);

isDuplicated = ismember(peakTable.Properties.VariableNames, ...
    conEpochTable.Properties.VariableNames(~isDataColu));

conWindowTable = horzcat(conEpochTable(:, ~isDataColu), peakTable(:, ~isDuplicated));

% move the channel information to the last
isChanColu = cellfun(@(x) strcmp(x(1:4), 'Chan'), conWindowTable.Properties.VariableNames);
conWindowTable = horzcat(conWindowTable(:, ~isChanColu), conWindowTable(:, isChanColu));


if isPlot
    methodCell = {'ratio', 'fixedWin'};
    % Plot the grand average of the data for this component
    % Mark the time window
    gfigure = figure('NumberTitle', 'off', 'Name', 'Locking Time Window for conditions', ...
        'Renderer', 'painters', 'Position', [100 100 1000 700]);
    xStart = -200;
    xEnd = 500;
    xNames = conEpochTable.Properties.VariableNames;
    [yStart, ~, lagFrame] = xposition(xNames, xconverter(xStart));
    yEnd = xposition(xNames, xconverter(xEnd));
    yERP = conEpochTable{:, yStart: yEnd};
    xERP = xStart:lagFrame:xEnd;
    x0Axis = zeros(1, length(xERP));
    plot(xERP, yERP);  % plot the ERP data , '-k'
    
    y1=get(gca,'ylim');
    hold on
    tws = conWindowTable{:, {'StartTime', 'EndTime'}};
    %     plot(repmat(tw(:), 1, 2), repmat(y1, 4, 1), ':r');
    plot(repmat(tws(:)', 2, 1), repmat(y1', 1, size(tws, 1)*2), '-r', 'LineWidth',1);
    plot(xERP, x0Axis, '--k');  % plot the horizontal line
    plot([0 0], y1, '--k');  % plot the veritical line
    
    set(gca,'FontSize',12)
%     if size(conWindowTable.ChanCent, 2) == 2
%         legends = cellfun(@(x,y,z) sprintf('%s-%s-%s', x, y, z), conWindowTable.Component,...
%             conWindowTable.ChanCent(:,1), conWindowTable.ChanCent(:,2), 'UniformOutput', false);
%     else
%         legends = cellfun(@(x,y) sprintf('%s-%s-%s', x, y), conWindowTable.Component,...
%             conWindowTable.ChanCent(:,1), 'UniformOutput', false);
%     end
%     legend(legends);
    xlabel('Time Points (ms)', 'FontSize', 14);
    ylabel('Amplitude (\muV)', 'FontSize', 14);
    title(['Locking Time Window Based for every condition -- ' methodCell{method}], 'FontSize', 16);
    saveas(gfigure, 'TimeWindowforGrandAvg.jpg');
    
end

end