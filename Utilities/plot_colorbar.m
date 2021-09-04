function plot_colorbar(cmap, cticks, csize)
% plot_colorbar(cmap, cticks, csize)
%
% This function save the colorbar for the heatmap. This function needs the
% export_fig toolbox (https://www.mathworks.com/matlabcentral/fileexchange/23629-export_fig) 
% in Matlab. 
%
% Inputs:
%    cmap         <string> or <numeric array> the colormap to be displayed.
%    cticks       <numeric array> ticks to be displayed. Default is
%                  [-6,-3,0,3,6]. 
%    cposition    <numeric array> the size of the colorbar. Default is
%                  [0.05, 4].
% 
% Output:
%    a png image.
%
% Created by Haiyang Jin (8-Oct-2020).

if ~exist('cmap', 'var') || isempty(cmap)
    cmap = 'jet';
end
if ~exist('cticks', 'var') || isempty(cticks)
    cticks = [-6,-3,0,3,6];
end
if ~exist('csize', 'var') || isempty(csize)
    csize = [.05 .4];
end
cposition = [.1 .1 csize];    % vertical
% cposition = [.1 .1 .4 .05]; % horizontal

f = figure;
colormap(cmap);
cbh = colorbar('southoutside'); %  'AxisLocation','in'
axis off
caxis([min(cticks), max(cticks)]);

cbh.Ticks = cticks; 

set(cbh,'FontSize', 20, 'Position',cposition)

% export_fig(f);
export_fig 'horizontal' -pdf

% cbh.TickLabels = ticklabel;
% 
% set(gcf, 'Color', 'None');
% set(gca, 'Color', 'None');

end