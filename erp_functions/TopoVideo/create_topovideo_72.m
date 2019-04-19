function create_topovideo_72(videoNames, windowPlot, windowTable, isResp)
% Create topo video without responses for E204 and E205. 
% Create topo vidoe with responses for E204 only


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
if nargin < 4 || isempty(isResp)
    isResp = 0;
end
if isResp
    duration = {'17 ms inc', '17 ms cor', '200 ms'};
    response = {'RES0', 'RES1'};
    dura_72 = '772';
    respLabel = 'Resp';
    xColorbar = .9414;
    screenRatio = .45;
else
    duration = {'17 ms', '200 ms'};
    dura_72 = '72';
    respLabel = 'All';
    xColorbar = .92;
    screenRatio = .52;
end

%% Record video
v = VideoWriter([videoNames '_' respLabel '_' num2str(windowPlot(1)) '_' num2str(windowPlot(2))], 'MPEG-4');
v.Quality = 100;
open(v);

%% The layout of the video
winX = 1600;
winY = round(winX * screenRatio);
winStart = [50, 50];
vidSize = [winStart(1) winStart(2) winStart(1)+winX winStart(2)+winY];
f = figure('NumberTitle', 'off', 'Position', vidSize);

type = {'Intact', 'Scrambled'};
category = {'Face', 'House'};
nDura = length(duration);
nRow = length(type);
nColu = length(category) * nDura;

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
        [xPosi(1)+.025 yPosi(1)-.05 0.0 0.0],'String',{[num2str(iTime,'%0.0f') ' ms']},...
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
        [mean(xPosi(2:(nColu/2 + 1))) yPosi(1)-.075 0.0 0.0],'String',category(1),...
        'HorizontalAlignment','center','FitBoxToText','on','FontSize',28,'LineStyle','none');
    annotation(f,'textbox',...
        [mean(xPosi((nColu/2 + 2):nColu+1)) yPosi(1)-.075 0.0 0.0],'String',category(2),...
        'HorizontalAlignment','center','FitBoxToText','on','FontSize',28,'LineStyle','none');
    
    % Duration (Columns)
    for iDura = 1:nColu
        annotation(f,'textbox',...
            [xPosi(iDura+1) yPosi(1)-.15 0.0 0.0],'String',duration(mod(iDura-1, nDura)+1),...
            'HorizontalAlignment','center','FitBoxToText','on','FontSize',22,'LineStyle','none');
    end
    
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
        [xPosi(1) yPosi(1)-.13 0.0 0.0],'String',compName,'color',compColor,...
        'HorizontalAlignment','center','FitBoxToText','on','FontSize',32,'LineStyle','none');
    
    % topo map 
    fn_tmp = xconverter(iTime);
    fn_frame = fn_tmp{1};
    type_NS = 'NS';
    
    for iRow = 1:nRow 
        thisType = type_NS(iRow);
        
        for iColu = 1:nColu
            tmpCol = mod(iColu-1, nDura)+1;
            thisCat = category{ceil(iColu/nDura)}(1);
            thisDura = dura_72(tmpCol);
        
            thisEvent = [thisType thisCat thisDura '+'];
            
            if isResp && thisDura == '7'
                thisResp = response{tmpCol};
                thisFrameTopo = [thisEvent '_' thisResp '_' fn_frame '.png'];
                thisfn = dir([thisEvent filesep thisResp filesep thisFrameTopo]);        
            else
                thisFrameTopo = [thisEvent '_' fn_frame '.png'];
                thisfn = dir([thisEvent filesep thisFrameTopo]);
            end
            
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
    colorbar('Position', [xColorbar  .135  0.025  .64],...  % .92  .9414
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

