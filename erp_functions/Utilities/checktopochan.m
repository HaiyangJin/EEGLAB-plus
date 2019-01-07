function isSameChan = checktopochan(topoChanComp, gwindowTable)

usedChan = gwindowTable{:, 'ChanCent'};

topoChan = topoChanComp(:, 2:3);

isSameChan = isequal(topoChan, usedChan);

end