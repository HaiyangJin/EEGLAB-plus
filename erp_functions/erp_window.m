function tw = erp_window(epochTable, checkWindow, compName, method, funvar)
% locate the time window for one epoch with different methods
% epochTable(table): one epoch data
% checkWindow(number array): exp: [start end] (Frame)
% compName: eg. P1, N170

if size(epochTable, 1) > 1
    warning('Function erp_window will only process the first epoch.');
end
if nargin < 4 || isempty(method)
    method = 1;
end
if nargin < 5
    funvar = [];
end
remarks = '';

xNames = epochTable.Properties.VariableNames;
[posiP0, ~, lagFrame] = xposition(xNames);

isPositive = strcmp(compName(1), 'P');
isNegative = strcmp(compName(1), 'N');

grandAvgPosi = epochTable(1, posiP0 + 1: end);
thisCheckStart = checkWindow(1);
thisCheckEnd = checkWindow(2);
thisGrandAvg = grandAvgPosi{1, thisCheckStart : thisCheckEnd};

% find the peak value
if isPositive
    [peak, peakFrame] = max(thisGrandAvg);
elseif isNegative
    [peak, peakFrame] = min(thisGrandAvg);
end

switch method
    case 1  % method 1 -- fractional (output: the grand window)
        % mainly used for grand average (fractional)
        methodName = 'fractionalGrand';
        if isempty(funvar)
            funvar = 0.5;
        end
        ratioPeak = funvar;
        
        % calculate the reference amplitude
        refAmp = ratioPeak * peak;
        
        % find the time point for the refAmp
        for iFrame = thisCheckStart : thisCheckEnd
            tempAmp1 = grandAvgPosi{1, iFrame};
            tempAmp2 = grandAvgPosi{1, iFrame + 1};
            
            if tempAmp1 <= refAmp && refAmp <= tempAmp2
                if isPositive; startFrame = iFrame; end
                if isNegative; endFrame = iFrame + 1; end
            elseif tempAmp1 >= refAmp && refAmp >= tempAmp2
                if isPositive; endFrame = iFrame + 1; end
                if isNegative; startFrame = iFrame; end
            end
            
        end
        
        % tw
        tw.ReferenceAmplitude = refAmp;
        tw.RatioForPeak = ratioPeak;
        
        
    case 2  % method 2 -- mean amplitude (output: peak)
        methodName = 'MeanAmplitude';
        tw.MeanAmp = mean(thisGrandAvg);
        
        startFrame = thisCheckStart;
        endFrame = thisCheckEnd;
        
    case 3  % method 3 -- local mean amplitude (output: peak, latency, condition windows)
        methodName = 'localMeanAmplitude';
        % find the time points where the peak is (the peak is the max or min values
        % among the nearest X data points)
        if isempty(funvar)
            funvar = 24;
        end
        windowSize = funvar;
        windowSize4Peak = round(windowSize/lagFrame);  % the size of the time window for get the averaged peak
        % how many data points do you want to average for the peak (Note: it is the time point, not the durations (ms))
        if ~mod(windowSize4Peak, 2)
            points4Peak = windowSize4Peak + 1;
        else
            points4Peak = windowSize4Peak;
        end
        
        pointSide4Peak = (points4Peak - 1)/2;
        
        startFrame = peakFrame - pointSide4Peak + thisCheckStart - 1;
        endFrame =  peakFrame + pointSide4Peak + thisCheckStart - 1;
        
        thisWindow = grandAvgPosi{1, startFrame : endFrame};

        tw.LocalMeanAmp = mean(thisWindow); 
        tw.OldWindowStart = thisCheckStart;
        tw.OldWindowEnd = thisCheckEnd;
end
if ~exist('startFrame', 'var')
    startFrame = thisCheckStart;
    remarks = sprintf('Assumed start point is used for %s.', compName);
    warning(remarks); %#ok<SPWRN>
end
if ~exist('endFrame', 'var')
    endFrame = thisCheckEnd;
    remarks = sprintf('Assumed end point is used for %s.', compName);
    warning(remarks); %#ok<SPWRN>
end

startAmp = grandAvgPosi{1, startFrame};
endAmp = grandAvgPosi{1, endFrame};

tw.MethodCode = method;
tw.Method = methodName;
tw.Component = compName;
tw.StartFrame = startFrame;
tw.PeakFrame = thisCheckStart + peakFrame - 1;
tw.EndFrame = endFrame;
tw.StartTime = startFrame * lagFrame;
tw.PeakTime = tw.PeakFrame * lagFrame;
tw.EndTime = endFrame * lagFrame;
tw.WindowSize = (endFrame - startFrame) * lagFrame;
tw.StartAmplitude = startAmp;
tw.PeakAmplitude = peak;
tw.EndAmplitude = endAmp;
if method == 1
tw.ChanCluster = epochTable.ChanCluster;
tw.ChanCent = epochTable.ChanCent;
tw.Remarks = remarks;

end