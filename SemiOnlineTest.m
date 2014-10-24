%time_elapsed 
function [range_Total, nFP, nFN, nGT] = SemiOnlineTest(subject_index, nTotalSec_2watch, nSec_4Division, alpha, InitTime_4Histogram_inSec, v)
%SEMIONLINETEST Summary of this function goes here
    clear dataqueue;
    clear v_dataqueue;
    clear acc_dataqueue;
    clear msdw;
    clear windowSize4msdw;
    clear indexes_localMax;
    clear indexes_localMin;
    clear detectedRange_inQueue;
    clear msdw_minmaxdiff;
    clear buffer_4medianfilter;
     
    
%   Detailed explanation goes here
    folder = 'D:\_Project\Data\LGData\Session_1';
    
    bDisplayOn = 0;

    min_window_width = 6;  %6 = 6/64  = about 93.8 ms
    max_window_width = 15;  %14 = 14/64  = 448/2048 = about 220 ms
    samplingFrequency2Use = 64;
    id_channel2use = 21;
    
   % threshold = 140;
   threshold  =-1;
    min_th_abs_ratio = 0.4;
    
    nBin4Histogram = 20; %Histogram을 작성하는 데에 사용할 bin의 수
    
%    i=10;
    filename = sprintf('attention_session1 (%02d).bdf',subject_index);
    RawData = pop_biosig([folder '/' filename]); % BDF file open
    resamplingRate = RawData.srate/samplingFrequency2Use;
    
    folder_GT = 'D:/_Project/Data/LGData_Txt/Session1_GroundTruth';
    filepaths_GT = load_files_in_folder(folder_GT,'*.range');
    range_groundTruth = load(filepaths_GT{subject_index});
    samplingFrequency_inGT = 64;
    
    %data = RawData.data(id_channel2use,1:resamplingRate:RawData.pnts);
    
    queuelength = 300* samplingFrequency2Use;
    
    
    dataqueue   = circlequeue(queuelength,1);
    v_dataqueue  = circlequeue(queuelength,1);
    acc_dataqueue = circlequeue(queuelength,1);
    msdw = circlequeue(queuelength,1);
    windowSize4msdw = circlequeue(queuelength,1);
    indexes_localMax = circlequeue(queuelength/2,1);
    indexes_localMin = circlequeue(queuelength/2,1);
    detectedRange_inQueue =  circlequeue(queuelength/2,2);
    msdw_minmaxdiff =  circlequeue(queuelength/2,1); %msdw 를 local min과 max와의 차이 형태로 변환시키는 데이터
    msdw_minmaxdiff.data(:,:) = Inf;
    
    histogram = accHistogram;
    
    
    nRow = size(RawData.data,2);
    
    dataqueue.data(:,:) = NaN;
    medianfilter_size = 5;
    buffer_4medianfilter = circlequeue(medianfilter_size,1);
    
    %히스토그램과 관련된 변수설정
    %bHistogramAvailable = 0;
    nMinimalData4HistogramCalculation = round(InitTime_4Histogram_inSec*samplingFrequency2Use); %5초. queuelength 보다 짧아야 한다. histogram을 만드는데 필요한 데이터 point의 개수가 아닌, source 데이터의 길이를 의미한다.
    
    % Accuracy Test 를 위한 변수
    range_Total = zeros(nRow/resamplingRate/2,2);
    nRangeTotal = 0;
    

    
   % time_elapsed = zeros(nRow,1);
    
    %for debugging
    threshold_changes   = zeros(nRow,1);
    t = 0;
    prev_threshold = -1;
    
    for i=1:nRow
        %Data In
        if mod(i-1,resamplingRate)==0
            new_idx = (i-1)/resamplingRate;
            d = RawData.data(id_channel2use,i);

            %Apply Median Filter using buffer
            buffer_4medianfilter.add(d);
            if(buffer_4medianfilter.datasize<medianfilter_size)
                continue;
            else
                d= median(buffer_4medianfilter.data);
            end

            %data add to queue
            dataqueue.add(d);
            idx_cur = dataqueue.datasize; % index calculation
          %  s = clock;
            if dataqueue.datasize ==nMinimalData4HistogramCalculation
            end
            if new_idx+1>=200*64
                aaa=3;
            end
            %[range, t, nDeletedPrevRange] = eogdetection_msdw_online(dataqueue, v_dataqueue, acc_dataqueue, idx_cur, min_window_width, max_window_width, threshold, prev_threshold, msdw, windowSize4msdw, indexes_localMin, indexes_localMax, detectedRange_inQueue, min_th_abs_ratio, nMinimalData4HistogramCalculation, msdw_minmaxdiff, histogram, nBin4Histogram,i/RawData.srate);
            [range, t, nDeletedPrevRange] = eogdetection_msdw_online(dataqueue, v_dataqueue, acc_dataqueue, idx_cur, min_window_width, max_window_width, threshold, prev_threshold, msdw, windowSize4msdw, indexes_localMin, indexes_localMax, detectedRange_inQueue, min_th_abs_ratio, nMinimalData4HistogramCalculation, msdw_minmaxdiff, histogram, nBin4Histogram, alpha, v);
            
            %Accuracy 검증을 위한 전체 range 저장
            if ~isempty(range)
                nRangeTotal = (nRangeTotal-nDeletedPrevRange)+1;
                if new_idx<=queuelength
                    range_Total(nRangeTotal,:) = range/samplingFrequency2Use;
                else
                    range_Total(nRangeTotal,:) = (new_idx - (queuelength-1) + (range-1))/samplingFrequency2Use;
                end
            end
            
           % e = clock;
           % time_elapsed(i,:) = etime(e,s);
        end
        if i>1
            threshold_changes(i,1) = threshold_changes(i-1,1);
        end
        if t>0
            threshold_changes(i,1) = t;
            prev_threshold = t;
        end

        x =  -queuelength+1: 0;
        x = x/samplingFrequency2Use;
        
        if bDisplayOn ==1 && mod(i-1, RawData.srate)==0
            subplot(6,4,[1:4]);
            plot(dataqueue.data);
            xlim([0 queuelength]);
            drawRange(dataqueue,detectedRange_inQueue);
            subplot(6,4,[5:8]);
%             plot(v_dataqueue.data);
%             xlim([0 queuelength]);
%             subplot(7,4,[9:12]);
%             plot(acc_dataqueue.data);
%             xlim([0 queuelength]);
           % subplot(5,4,[9:12]);
            plot(x,msdw.data);
            xlim([-queuelength/samplingFrequency2Use 0]);
            subplot(6,4,[9:12]);
            plot(indexes_localMin.data,msdw_minmaxdiff.data);
            %plot(msdw_minmaxdiff.data);
            %xlim([0 queuelength]);
            subplot(6,4,[13:16]);
            xi = [1:nRow]/RawData.srate;
            plot(xi,threshold_changes);
            
            if histogram.nBin>0
                %figure(fig2);
                subplot(6,4,[17,21]);
                bar(histogram.xi, histogram.bin);
            end
            pause(0.1);
        end
    end
    nArrayLengthTmp = size(range_Total,1);
    range_Total(nRangeTotal+1:nArrayLengthTmp,:) = [];
    [nFP, nFN, nGT]  = TestAccuracy(range_Total, range_groundTruth, samplingFrequency_inGT, nTotalSec_2watch, nSec_4Division);
end

function drawRange(dataqueue, detectedRange_inQueue)
    nRange = detectedRange_inQueue.datasize;
    y = get(gca,'YLim');
    y = (y(1) +y(2))/2;
    x = get(gca,'XLim');
    for i=1:nRange
        pos = mod(dataqueue.index_start + detectedRange_inQueue.get(i) - 2,dataqueue.length)+1;
  %      pos = pos * resamplingRate;
        if pos(1)>pos(2)
            line([pos(1) x(2)] , [y, y],'color','red');
            line([x(1) pos(2)] , [y, y],'color','red');
        else
            line(pos, [y, y],'color','red');
        end
    end
end

function [nFP, nFN, nGT] = TestAccuracy(detectedRange_Total, range_groundTruth, samplingFrequency_inGT, nTotalSec_2watch, nSec_4Division)
    %nSec_4Division = 5;
    nBin = nTotalSec_2watch/nSec_4Division;
    nFP = zeros(1,nBin);
    nFN = zeros(1,nBin);
    nGT = zeros(1,nBin);
    
    %seperate ambiguous ranges from GT ranges
    amb_col_id = 4;
    [amb_range,concrete_GTrange_ref] = seperateAmbiguousRange(range_groundTruth, amb_col_id);
    concrete_GTrange_ref = sortrows(concrete_GTrange_ref);
    
    %Ground Truth 카운팅
    nGT_Total = size(range_groundTruth,1);
    for i=1:nGT_Total
        pos = range_groundTruth(i,3);
        pos_inBin = floor((pos/samplingFrequency_inGT)/nSec_4Division) +1;
        if pos_inBin<nBin
            nGT(pos_inBin) = nGT(pos_inBin)+1;
        end
    end
    
    detectedRange_inIdx = detectedRange_Total * samplingFrequency_inGT;
    
    [dummy, nFN_Total, nPoints, dummy, list_FNid] = isFullMatch_Points2Ranges(detectedRange_inIdx, concrete_GTrange_ref(:,3));
    %False Negative 카운팅
    for i=1:nFN_Total
        pos = concrete_GTrange_ref(list_FNid(i),3);
        pos_inBin = floor((pos/samplingFrequency_inGT)/nSec_4Division) +1;
        if pos_inBin<nBin
            nFN(pos_inBin) = nFN(pos_inBin)+1;
        end
    end
    
    [nFP_Total, dummy, nPoints, list_FPid, dummy] = isFullMatch_Points2Ranges(detectedRange_inIdx, range_groundTruth(:,3)); %Ambiguous artifact 때문에 FP 계산은 원 GT 로 해야 함
    %False Positive 카운팅
    for i=1:nFP_Total
        pos = (detectedRange_Total(list_FPid(i),1) + detectedRange_Total(list_FPid(i),2))/2;
        pos_inBin = floor(pos/nSec_4Division) +1;
        if pos_inBin<nBin
            nFP(pos_inBin) = nFP(pos_inBin)+1;
        end
    end
end

%a의 width에 대한 비율로 Normalize
function c = SubtractRanges(a,b)
    nA = size(a,1);
    nB = size(b,1);
    
    width_a = a(:,2) - a(:,1);

    %range를 우선 다 뺀다.
    c = cell(nA,1);
    for i=1:nA
        c{i} = a(i,:);
        for j=1:nB
            if  b(j,2)>a(i,1) && b(j,1)<a(i,2)
                c{i} = Subtract_aRange_fromRanges(c{i},b(j,:));
            end
        end
    end
end

function [amb_range, concrete_range] = seperateAmbiguousRange(range_groundTruth,amb_col_id)
    amb_range_counter = 0;
    concrete_range_counter = 0;
    nGTRange = size(range_groundTruth,1);
    dim = 3;
    amb_range = zeros(nGTRange,dim);
    concrete_range= zeros(nGTRange,dim);
    
    for i=1:nGTRange
        if range_groundTruth(i,amb_col_id) ==1
            amb_range_counter = amb_range_counter+1;
            amb_range(amb_range_counter,:) = range_groundTruth(i,1:dim);
        else
            concrete_range_counter = concrete_range_counter+1;
            concrete_range(concrete_range_counter,:) = range_groundTruth(i,1:dim);
        end
    end
    amb_range(amb_range_counter+1:1:nGTRange,:) = [];
    concrete_range(concrete_range_counter+1:1:nGTRange,:) = [];
end

