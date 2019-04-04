function theChanCluster = clusterchan(centChan)
% Output the names of all channels for the cluster (central channels)
% author: Haiyang Jin (hjin317@aucklanduni.ac.nz)

% the first value of each row is the central electrode, and the rest six
% are the surrouding electrodes
clusterArray = [65 58 59 66 70 69 64; % PO7
    90 96 91 84 83 89 95; % PO8
    58 51 59 65 64 57 50; % P7
    96 97 91 90 95 100 101; % P8
    64 57 58 65 69 68 63; % P9
    95 100 99 94 89 90 96; % P10
    69 64 65 70 74 73 68;
    89 95 94 88 82 83 90]; %

clusterNames = channame(clusterArray);
allCentChan = clusterNames(:, 1);



if nargin < 1
    centChan = allCentChan;
else
    centChan = channame(centChan);
    
    % check if the cluster information for this chan is preloaded
    isClusterLoaded = ismember(centChan, clusterNames(:, 1));
    
    if ~all(isClusterLoaded)
        error('The cluster information for Channel %s cannot be found!\n', ...
            centChan{~isClusterLoaded});
    end
    
end

isC = cellfun(@(x) any(strcmp(centChan, x)), allCentChan);

theChanCluster = unique(clusterNames(isC, :));

end

