function plot_chanlocation(plotchans, chan_locs)

if ~exist('plotchans', 'var') || isempty(plotchans)
    plotchans = [];  % i.e. all channels
end

if ~exist('chan_locs', 'var') || isempty(chan_locs)
    chan_locs = 'EGI_128.loc';
end


plotchans = [65 58 59 66 70 69 64,... % PO7
    90 96 91 84 83 89 95];

topoplot([], chan_locs, 'plotchans', plotchans, ...
    'emarker', {'.', 'r', 40, 1});

set(gcf, 'color', 'none');    
set(gca, 'color', 'none');
    
export_fig('filename', 'chanlocation.png', 'transparent');

end