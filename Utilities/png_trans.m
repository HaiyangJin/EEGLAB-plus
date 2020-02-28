function png_trans(fn, cutExtra)

if nargin < 2 || isempty(cutExtra)
    cutExtra = 0;
end

[thisMatrix, ~, alpha] = imread(fn);

if isempty(alpha)
    tmpalpha = zeros(size(thisMatrix, 1), size(thisMatrix, 2), 3);
    
    for i = 1:3
        thisArray = thisMatrix(:, :, i);
        
        tmpalpha(:, :, i) = arrayfun(@(x) x == 255, thisArray);
    end
    
    alpha = prod(tmpalpha, 3);
    
end

if cutExtra
    tmpAlpha = ~alpha;
    xCut = sum(tmpAlpha) ~= 0;
    yCut = sum(tmpAlpha, 2) ~= 0;
    
    isY = (find(xCut, 1) - 10) : (find(xCut, 1, 'last') + 10);
    isX = 1 : (find(yCut, 1, 'last') + 10);
    
    alpha = alpha(isX, isY);
    thisMatrix = thisMatrix(isX, isY, :);
end

imwrite(thisMatrix, fn, 'Alpha', double(~alpha));
end
