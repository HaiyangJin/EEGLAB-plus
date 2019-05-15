function zeroTable = erp_baselinezero(gmeanTable, assumedWin)

if nargin < 2 || isempty(assumedWin)
    assumedWin = {...
        'P1', 70, 140; ...
        'N170', 100, 250};
%     warning('Assumed window is used for locating the Zero transaction.');
end


%% Get information from the grandAvg table
% Find where the data after onset of the simuli
xNames = gmeanTable.Properties.VariableNames;
[posiP0, ~, lagFrame] = xposition(xNames);

% frame point of the start and end of each window
assumedFrame = cellfun(@(x) round(x/lagFrame), assumedWin(:,2:3));

%% Locate the frame of amplitude 0 muV
nComp = size(assumedWin, 1);

% create cell for saving window size
zeroTrans = struct;

for iComp = 1:nComp
    thisComp = assumedWin{iComp, 1};
    thisStart = assumedFrame(iComp, 1);
    thisEnd = assumedFrame(iComp, 2);
    
    if strcmp(thisComp(1), 'P')
        PN = 1;
        startMax = 110;  % the maximum start time point
    elseif strcmp(thisComp(1), 'N')
        PN = -1;
        startMax = 220;  % the maximum start time point
    end

    nTrans = 0;
    
    for iFrame = thisStart:thisEnd
        tempAmp1 = PN * gmeanTable{1, posiP0 + iFrame};
        tempAmp2 = PN * gmeanTable{1, posiP0 + iFrame + 1};
        
            if tempAmp1 * tempAmp2 <= 0 % there is a change between positive and negative
                nTrans = nTrans + 1;  % number of changes at 0
                
                if tempAmp1 < tempAmp2 && nTrans == 1 % from negative to positive
                    theCompStart = iFrame + 1;
                    
                elseif tempAmp1 > tempAmp2  % from positive to negative
                    
                    switch nTrans
                        case 1
                            if iFrame < startMax/lagFrame  
                                nTrans = 0;
                            else
                                theCompStart = thisStart;
                                theCompEnd = iFrame;
                                warning(['Please check manually! The start of %s '...
                                    'time window is set as the assumed start point.'], thisComp);
                                nTrans = 2;
                            end
                            
                        case 2
                            theCompEnd = iFrame;
                    end
                end
            end
        
        if nTrans == 2; break; end
    end
 
    switch nTrans 
        case 0
            theCompStart = thisStart;
            theCompEnd = thisEnd;
            warning(['Please check manully! Both the start and end of %s '...
            'time window was set as the assumed start points.'], thisComp);
        case 1
        theCompEnd = thisEnd;
        warning(['Please check manully! The end of %s '...
            'time window was set as the assumed start point.'], thisComp);
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% backup at the end of this code %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % save the time window data
    zeroTrans(iComp).Component = thisComp;
    zeroTrans(iComp).windowStart = theCompStart;
    zeroTrans(iComp).windowEnd = theCompEnd;
    zeroTrans(iComp).nTrans = nTrans;
    
    clear theCompStart
    clear theCompEnd
        
end

% zeroTable = struct2table(zeroTrans);
zeroTable = struct2table(zeroTrans, 'RowNames', {zeroTrans.Component});


end