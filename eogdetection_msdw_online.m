%MSDW를 사용하여 spike의 구간을 검출한다.
% threshold가 -1인 경우에는 automatic thresholding 기법을 적용한다.
% nDeletedPrevRange 는 이전에 record 된 artifact range 중 새롭게 detected 된 range와
% 겹쳐져서 삭제된 구간의 수
function [range, threshold, nDeletedPrevRange] = eogdetection_msdw_online(dataqueue, v_dataqueue, acc_dataqueue, idx_cur, min_windowwidth, max_windowwidth, threshold, prev_threshold, msdw, windowSize4msdw,indexes_localMin, indexes_localMax, detectedRange_inQueue, min_th_abs_ratio, nMinimalData4HistogramCalculation, msdw_minmaxdiff, histogram, nBin4Histogram,alpha, v)
%EOGDETECTION_MSDW_ONLINE Summary of this function goes here
%   Detailed explanation goes here
    global bTmpUp;
    global bTmpDown;
    global tmp_max_id;
    global tmp_min_id;
%    global bMinFound;
   % global detectedRange_inQueue;
    
    if nargin<13
        min_th_abs_ratio = 0.4;
    end
    
    %초기화
    if idx_cur==1
        bTmpUp =0; bTmpDown = 0;    tmp_max_id= 0; tmp_min_id = 0;
    end
    range = [];
    nDeletedPrevRange = 0;
    
    %데이터를 입력하기 전에 이미 queue 가 꽉 차 있는 상태인지 체크 data의 shift 확인 등에 필요
    % 이게 1이면 calMultiSDW_onebyone 함수가 호출되면서 queue의 시작점/끝점이 shift하게 됨
    if v_dataqueue.datasize == v_dataqueue.length
        bDataFull_beforeAddingData = 1;
    else
        bDataFull_beforeAddingData = 0;
    end

    %현재까지의 데이터를 사용해 MSDW 계산
    [ msdw_cur, windowSize4msdw_cur ] = calMultiSDW_onebyone( dataqueue, v_dataqueue, acc_dataqueue, min_windowwidth, max_windowwidth );
    if isempty(msdw_cur)
        msdw.add(0);
        windowSize4msdw.add(0);
    else
        msdw.add(msdw_cur);
        windowSize4msdw.add(windowSize4msdw_cur);
    end
    
    %데이터가 충분히 쌓이지 않은 경우 처리
    if idx_cur<3
        return;
    end
    
    %queue가 shift 되며, queue에 있는 range, indexes_localMax, indexes_localMin 가 invalid 되는 것을 방지하는 코드
    ProcessQueueIntegrity(bDataFull_beforeAddingData, detectedRange_inQueue);
    ProcessQueueIntegrity(bDataFull_beforeAddingData, indexes_localMax);
    ProcessQueueIntegrity(bDataFull_beforeAddingData, indexes_localMin);
    
    % i-2, i-1, i 의 세 항목을 참조하여 local min/max 를 계산한다.
    %peak가 날카롭지 않은 경우를 위한 계산
    [tmp_max_id, tmp_min_id, bTmpUp, bTmpDown, bMinFound] = checkLocalMinMax(msdw, tmp_max_id, tmp_min_id, bTmpUp, bTmpDown, indexes_localMin, indexes_localMax, idx_cur);
    
    %local minimum이 새롭게 발견된 경우, msdw를 minmax diff 형태로 전환한다.
    if bMinFound==1
        MSDW2minmaxdiff_online(msdw, max_windowwidth, indexes_localMin, indexes_localMax, msdw_minmaxdiff);
        
        %automatic thresholding 인 경우 threshold를 계산한다.
        if threshold<0 
            if dataqueue.datasize>=nMinimalData4HistogramCalculation
                if histogram.nBin ==0
                    histogram.Init(msdw_minmaxdiff.data(1:msdw_minmaxdiff.datasize,:),nBin4Histogram);
                else
                    histogram.add(msdw_minmaxdiff.getLast());
                end
            else
                %데이터가 아직 충분하지 않은 경우 histogram을 계산하지 않고,
                %range도 계산하지 않는다.
                return;
            end
            %threshold = selectThreshold_KimMcNames2007_withAlpha_usingHistogram(histogram,ceil(totalTimePassed),0);
            threshold = selectThreshold_KimMcNames2007_withAlpha_usingHistogram_v2(histogram, alpha,v);
            if threshold<0 %위의 알고리즘으로 threshold 계산이 안되는 경우 그 전의 threshold를 그대로 사용한다.
                threshold = prev_threshold;
            end
        end
    end
    
    
    
    %이전 local maxima 를 하나씩 살펴보면서 스파이크로 볼 수 있는지 여부를 따진다.
    if bMinFound ==1 && indexes_localMax.datasize>0 %minimum 값이 발견되고, 이전에 maximum 값이 발견되었던 경우
        id_min = indexes_localMin.getLast();
        sum = msdw.get(indexes_localMax.getLast()) - msdw.get(id_min);
        tmp_max_sum = sum;
        curmax_pos = indexes_localMax.getLast();
        r_start = -1;

        bAccept = isCriteriaSatisfied(sum,threshold, min_th_abs_ratio, msdw.get(curmax_pos), msdw.get(id_min));
        if(bAccept==1)   %조건을 만족하는 경우
            %처음에 세팅된 범위가 이전 범위와 겹치는 경우 starting point를 수정한다.
            %이때 이 범위가 이전의 범위를 포함하는 것은 바람직하지 않다.

            r_start = curmax_pos - windowSize4msdw.get(curmax_pos);
            if(detectedRange_inQueue.datasize>0)
                prev_range = detectedRange_inQueue.getLast();
                if r_start<=prev_range(2)
                    r_start = prev_range(2);
                end
            end
        end

        for k=0:indexes_localMax.datasize-2 %이전의 max 값들을 꺼꾸로 하나씩 짚어 가면서 이전의 max 값을 기준으로 range를 정할 수 있는지 체크한다.
            if(id_min - indexes_localMax.get_fromEnd(2+k)>max_windowwidth)        %일정 범위 (max_windowwidth *2) 내의 maximum value가 아닌 경우 중단
                break;
            end
            prev_range = [];
            if(detectedRange_inQueue.datasize>0)
                prev_range = detectedRange_inQueue.getLast();
            end

            %이전의 range와 겹치지 않으면서 sum이 최대인 경우를 찾는다. (이전 range를 포함하는 경우는 괜찮다.)
            curmax_pos  = indexes_localMax.get_fromEnd(k+2);                  %새로 살펴볼 max 지점의 인덱스
            prevmax_pos = indexes_localMax.get_fromEnd(k+1);                    %이전에 살펴본 max지점의 인덱스
            sum = sum + msdw.get(curmax_pos) - msdw.get(prevmax_pos);  %두 지점 사이의 데이터 차를 더해 현재까지의 합을 구한다.

            r_start_tmp = curmax_pos - windowSize4msdw.get(curmax_pos);            %range의 시작점

            tmp_check_result = isCriteriaSatisfied(sum,threshold,min_th_abs_ratio, msdw.get(curmax_pos), msdw.get(id_min));%, id_min, curmax_pos,max_id_window_acc_v(id_min), nLocalMin-1-k, LRValues_Spike, LRWidths_Spike, bAccept);
            if(sum>tmp_max_sum  && tmp_check_result==1) %조건을 만족하는 경우

                tmp_max_sum = sum;
                if(detectedRange_inQueue.datasize==0 || r_start_tmp>=prev_range(2))  %이전의 range와 겹치지 않는다면 starting point를 확장한다
                    r_start = r_start_tmp; 
                end

                while(detectedRange_inQueue.datasize>0 && r_start_tmp<=prev_range(1))  %이전 range를 포함한다면, (2개 이상의 range를 동시에 점프하여 포함할 가능성도 있으므로 if 대신 while을 쓴다.)
                    detectedRange_inQueue.pop();%이전의 range를 제거한다. 
                    nDeletedPrevRange = nDeletedPrevRange +1;
                    %이번 range는 포함했지만, 다음 range와도 겹치고 포함하지는 못하는 경우 처리
                    %range를 다음 range의 끝점에서 시작하도록 한다.
                    if(detectedRange_inQueue.datasize>0) 
                        prev_range = detectedRange_inQueue.getLast();
                        if r_start_tmp<prev_range(2) %다음 range와 겹치는 경우 일단 그 range의 끝점을 시작점으로 해 두고, 포함하는 경우에는 while 문의 다음번 iteration 에서 처리한다.
                            r_start = prev_range(2);     
                        else
                            r_start = r_start_tmp;
                        end
                    else
                        r_start = r_start_tmp;
                    end
                end
            end
        end

        if(r_start>0)
            range = [r_start id_min];
            detectedRange_inQueue.add(range);
        end
    end
end

function [bYes] = isCriteriaSatisfied(sum, threshold, min_th_abs_ratio, window_acc_v_max, window_acc_v_min)%, min_id,max_id,windowwidth_at_min, prev_minID,  LRValues_Spike, LRWidths_Spike, bAccept)
    bYes = (sum>threshold && window_acc_v_max>threshold*min_th_abs_ratio && window_acc_v_min<-threshold*min_th_abs_ratio);% && min_id - windowwidth_at_min>=max_id);
end



%queue가 shift 되며, queue에 있는 range 등의 data 가 invalid 되는 것을 방지하는 코드
function ProcessQueueIntegrity(bDataFull_beforeAddingData, queue)
    if queue.datasize>0 && bDataFull_beforeAddingData ==1
        queue.data = queue.data -1;
        theFirstRange = queue.get(1);
        if theFirstRange(1)==0
            queue.pop_fromBeginning();
        end
    end
end