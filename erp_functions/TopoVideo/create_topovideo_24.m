function create_topovideo_24(videoNames, windowPlot, windowTable)
% Create topo video for E204 and E205. 2 rows and 4 columns (without
% responses)

if nargin < 1 || isempty(videoNames)
    videoNames = 'TopoVideo';
end
if nargin < 2 || isempty(windowPlot)
    windowPlot = [-200 500];
end
if nargin < 3 || isempty(windowTable)
    lag = 4;
    TW = [1e5, 1e5+1; 1e6, 1e6+1];
else
    lag = windowTable{1, 'StartTime'} / windowTable{1, 'StartFrame'};
    TW = windowTable{:, {'StartTime', 'EndTime'}};
end

%% Record video
v = VideoWriter([videoNames '_' num2str(windowPlot(1)) '_' num2str(windowPlot(2))], 'MPEG-4');
v.Quality = 100;
open(v);

%% The layout of the video
vidSize = [50 50 1350 750];
f = figure('NumberTitle', 'off', 'Position', vidSize);

type = {'Intact', 'Scrambled'};
category = {'Face', 'House'};
duration = {'17 ms', '200 ms'};
nRow = length(type);
nColu = length(category) * length(duration);

xStart = .1;
xEnd = 0;
xDist = (1 - xStart - xEnd)/(nColu + 1);
xPosi = xStart : xDist : (1 - xDist);

yEnd = 0.01;
yStart = 0;
yDist = (1 - yStart - yEnd)/(nRow + 1);
yPosi = (1 - yEnd) : -yDist : yStart;

for iTime = windowPlot(1):lag:windowPlot(2)

    close(f);
    f = figure('Position', vidSize);
    hold on;
    
    % Texts on the frame
    % Timepoint
    annotation(f,'textbox',...
        [xPosi(1)+.05 yPosi(1)-.1 0.0 0.0],'String',{[num2str(iTime,'%0.0f') ' ms']},...
        'HorizontalAlignment','center','FitBoxToText','on','FontSize',34,'LineStyle','-');
    % mean(xPosi(length(xPosi)/2 +([.5, 1.5])))
    
    % Type (Rows)
    annotation(f,'textbox',...
        [xPosi(1) yPosi(2) 0.0 0.0],'String',type(1),...
        'HorizontalAlignment','center','FitBoxToText','on','FontSize',28,'LineStyle','none');
    annotation(f,'textbox',...
        [xPosi(1) yPosi(3) 0.0 0.0],'String',type(2),...
        'HorizontalAlignment','center','FitBoxToText','on','FontSize',28,'LineStyle','none');
    
    % Category (Columns)
    annotation(f,'textbox',...
        [mean(xPosi([2,3])) yPosi(1)-.075 0.0 0.0],'String',category(1),...
        'HorizontalAlignment','center','FitBoxToText','on','FontSize',28,'LineStyle','none');
    annotation(f,'textbox',...
        [mean(xPosi([4,5])) yPosi(1)-.075 0.0 0.0],'String',category(2),...
        'HorizontalAlignment','center','FitBoxToText','on','FontSize',28,'LineStyle','none');
    
    % Duration (Columns)
    annotation(f,'textbox',...
        [xPosi(2) yPosi(1)-.15 0.0 0.0],'String',duration(1),...
        'HorizontalAlignment','center','FitBoxToText','on','FontSize',22,'LineStyle','none');
    annotation(f,'textbox',...
        [xPosi(3) yPosi(1)-.15 0.0 0.0],'String',duration(2),...
        'HorizontalAlignment','center','FitBoxToText','on','FontSize',22,'LineStyle','none');
    annotation(f,'textbox',...
        [xPosi(4) yPosi(1)-.15 0.0 0.0],'String',duration(1),...
        'HorizontalAlignment','center','FitBoxToText','on','FontSize',22,'LineStyle','none');
    annotation(f,'textbox',...
        [xPosi(5) yPosi(1)-.15 0.0 0.0],'String',duration(2),...
        'HorizontalAlignment','center','FitBoxToText','on','FontSize',22,'LineStyle','none');
    
    % Name of component
    if iTime > TW(1, 1) && iTime < TW(1, 2)
        compName = {'P1'};
        compColor = 'red';
    elseif iTime > TW(2, 1) && iTime < TW(2, 2)
        compName = {'N170'};
        compColor = 'blue';
    else
        compName = {''};
        compColor = 'black';
    end
    annotation(f,'textbox',...
        [xPosi(1)+.05 yPosi(1)-.175 0.0 0.0],'String',compName,'color',compColor,...
        'HorizontalAlignment','center','FitBoxToText','on','FontSize',32,'LineStyle','none');
    
    % topo map 
    fn_tmp = xconverter(iTime);
    fn_frame = fn_tmp{1};
    type_NS = 'NS';
    dura_72 = '72';
    
    for iRow = 1:nRow 
        thisType = type_NS(iRow);
        
        for iColu = 1:nColu
            thisCat = category{ceil(iColu/2)}(1);
            thisDura = dura_72(mod(iColu-1, 2)+1);
        
            thisEvent = [thisType thisCat thisDura '+'];
            
            thisFrameTopo = [thisEvent '_' fn_frame '.png'];
            
            thisfn = dir([thisEvent filesep thisFrameTopo]);
            
            [rgb, ~, alpha] = imread([thisfn.folder filesep thisfn.name]);
            thisPosi = [xPosi(iColu + 1) - xDist*.45 yPosi(iRow + 1) - yDist*.7 ...
                xDist yDist];
            subplot('Position', thisPosi);
            hold on;
            
            % cut the time points on individual topo plot
            isCut = ones(size(rgb, 1), 1);
            isCut(1:48, :) = 0;
            rgb = rgb(logical(isCut), :, :);
            alpha = alpha(logical(isCut), :);
            
            temp = imshow(rgb);
            set(temp, 'AlphaData', alpha);
        
        end
    end
    
    % settings for color bar
    colorLimit = [-5 5];
    colorbar('Position', [.92 .135  0.025  .64],...
        'FontSize', 19,...
        'Ticks', colorLimit(1):colorLimit(2));
    caxis(colorLimit);
    colormap(jet);
    
    %% Record frames
    writeVideo(v, repmat(getframe(f),[1 15]));

end

%% Wrap up video
close(f);
close(v);

end

