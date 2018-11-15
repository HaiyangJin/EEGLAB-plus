% the first value of each row is the central electrode, and the rest six
% are the surrouding electrodes
chanCluster = [65 58 59 66 70 69 64; % PO7
    90 96 91 84 83 89 95; % PO8
    58 51 59 65 64 57 50; % P7
    96 97 91 90 95 100 101; % P8
    64 57 58 65 69 68 63; % P9
    95 100 99 94 89 90 96]; % P10
chanSum = unique(chanCluster(:));

chanCluster = arrayfun(@(e) ['E', num2str(e)], chanCluster, 'UniformOutput', false);
chanSum = arrayfun(@(e) ['E', num2str(e)], chanSum, 'UniformOutput', false);

