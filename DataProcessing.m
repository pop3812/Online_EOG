%1초마다 호출된다.
%호출될 때마다 RawData에 있는 값 중 필요한 것을 골라 처리해야 한다.
%RawData는 512Hz로 샘플링 되어 있으며,
%여기서는 64 Hz 단위로 데이터를 사용한다.
function DataProcessing()
    tic
    global rawData; % Laxtha 장비에서 데이터가 들어오는 변수
    global p;

%   global g_handles;
%    plot(g_handles.axes_source,rawData.Value);
%    return;
    
    d = reshape(rawData.Value, p.BufferLength_Laxtha, p.ChNum);
    
    % Calculation of Horizontal and Vertical Components
    Vx = d(:,1) - d(:,2);
    Vy = d(:,3) - d(:,4);
    d = [Vx, Vy];

    % Noise Removal by Applying Median Filter using Buffer
    for i=1:p.BufferLength_Laxtha
        p.buffer_4medianfilter.add(d(i,:));
        if(p.buffer_4medianfilter.datasize < p.medianfilter_size)
            return;
        else
            d(i,:)= median(p.buffer_4medianfilter.data);
        end
    end

    % Apply Baseline Drift Removal Algorithm using Median Value
    % - assuming constant baseline drift for local time window
    if(p.raw_dataqueue.datasize < p.median_window_size)
        % Data Add to raw data queue
        for i=1:p.BufferLength_Laxtha
            p.raw_dataqueue.add(d(i,:));
        end
    else
        % Baseline Drift of previous buffer data
        baseline_drift_cur = median(p.raw_dataqueue.data);
        baseline_drift_cur = repmat(baseline_drift_cur, ...
            p.BufferLength_Laxtha, 1);
        
        % Data Add to raw data queue
        for i=1:p.BufferLength_Laxtha
            p.raw_dataqueue.add(d(i,:));
        end
        
        % Baseline Drift Removal
        d = d - baseline_drift_cur;
        
    end
    
    % Histogram Calculation for future use (e.g. threshold decision)
    [p.histogram, p.hist_centers] = hist(d, p.hist_bin_size);
    % Normaization
    p.histogram = p.histogram./p.BufferLength_Laxtha;
    
    % Data Add to data queue
    for i=1:p.BufferLength_Laxtha
        p.dataqueue.add(d(i,:));
        idx_cur = p.dataqueue.datasize; % current index calculation
    end
    
% Eye Blink Detection (Not in use for now)
% 
%          [range, t, nDeletedPrevRange] = eogdetection_msdw_online( ...
%              p.dataqueue, p.v_dataqueue, p.acc_dataqueue, idx_cur, ...
%              p.min_window_width, p.max_window_width, p.threshold, ...
%              p.prev_threshold, p.msdw, p.windowSize4msdw, ...
%              p.indexes_localMin, p.indexes_localMax, ...
%              p.detectedRange_inQueue, p.min_th_abs_ratio, ...
%              p.nMinimalData4HistogramCalculation, ...
%              p.msdw_minmaxdiff, p.histogram, p.nBin4Histogram, ...
%              p.alpha, p.v);
%          if t>0
%              p.prev_threshold = t;
%          end
%          if size(range,1)>0
%             % p.detectedRange_inQueue.add(range);
%          end

    drawData_withRange();
    toc
end

function drawData_withRange()
    global p;
    global g_handles;
    
    % Graph shifts to the left @ every second
    data_to_show = circshift(p.dataque.data, -p.dataque.index_start);
    
    plot(g_handles.axes_source, data_to_show);
    
    grid on;
    line([0 p.queuelength], [0 0], 'color', 'black');
    xlim([0 p.queuelength]);
    
    bar(g_handles.hist_plot, p.hist_centers, p.histogram);
    
    drawRange();
end
    
function drawRange()
    global p;
    global g_handles;
    axes(g_handles.axes_source);
    nRange = p.detectedRange_inQueue.datasize;
    y = get(gca,'YLim');
    y = (y(1) +y(2))/2;
    x = get(gca,'XLim');
    
    for i=1:nRange
        pos = mod(p.dataqueue.index_start + p.detectedRange_inQueue.get(i) - 2,p.dataqueue.length)+1;
  %      pos = pos * resamplingRate;
        if pos(1)>pos(2)
            line([pos(1) x(2)] , [y, y],'color','red');
            line([x(1) pos(2)] , [y, y],'color','red');
        else
            line(pos, [y, y],'color','red');
        end
    end
end