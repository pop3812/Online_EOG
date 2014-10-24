function [range] = eogdetection_msdw_online(dataqueue, v_dataqueue, acc_dataqueue, idx_cur, min_windowwidth, max_windowwidth, threshold, msdw, windowSize4msdw,indexes_localMax, detectedRange_inQueue, min_th_abs_ratio)
%EOGDETECTION_MSDW_ONLINE Summary of this function goes here
%   Detailed explanation goes here
    global bTmpUp;
    global bTmpDown;
    global tmp_max_id;
    global tmp_min_id;
%    global bMinFound;
   % global detectedRange_inQueue;
    
    if nargin<12
        min_th_abs_ratio = 0.4;
    end
    
    %초기화
    if idx_cur==1
        bTmpUp =0; bTmpDown = 0;    tmp_max_id= 0; tmp_min_id = 0;
    end
    bMinFound = 0;
    range = [];
    
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
    
    %queue가 shift 되며, queue에 있는 range 가 invalid 되는 것을 방지하는 코드
    if detectedRange_inQueue.datasize>0 && bDataFull_beforeAddingData ==1
        detectedRange_inQueue.data = detectedRange_inQueue.data -1;
        theFirstRange = detectedRange_inQueue.get(1);
        if theFirstRange(1)==0
            detectedRange_inQueue.pop_fromBeginning();
        end
    end
    %queue가 shift 되며, queue에 있는 indexes_localMax 가 invalid 되는 것을 방지하는 코드
    if indexes_localMax.datasize>0  && bDataFull_beforeAddingData ==1
        indexes_localMax.data = indexes_localMax.data -1;
        theFirst = indexes_localMax.get(1);
        if theFirst(1)==0
            indexes_localMax.pop_fromBeginning();
        end
    end
    
    

    % i-2, i-1, i 의 세 항목을 참조하여 local min/max 를 계산한다.
    %peak가 날카롭지 않은 경우를 위한 계산
    msdw_tmp = [ msdw.get(idx_cur-2), msdw.get(idx_cur-1), msdw.get(idx_cur)];
    if(msdw_tmp(1)<msdw_tmp(2) && msdw_tmp(2) == msdw_tmp(3))  %이전에 비해 증가했으나 다음 진행이 flat 한 경우 /-
        tmp_max_id = idx_cur-1;
        bTmpUp = 1;     bTmpDown = 0;
    elseif(msdw_tmp(1)>msdw_tmp(2) && msdw_tmp(2) == msdw_tmp(3))  %이전에 비해 감소했으나 다음 진행이 flat 한 경우 /-
        tmp_min_id = idx_cur-1;
        bTmpDown = 1;   bTmpUp = 0;
    elseif(msdw_tmp(1)==msdw_tmp(2))
        if(msdw_tmp(2) > msdw_tmp(3)) %이전이 flat하였고 다음 진행이 내려가는 경우
            if bTmpUp==1    %이전에 올라왔었던 경우
                indexes_localMax.add(round((idx_cur-1 + tmp_max_id)/2));
            end
            %계속 내려가고 있는 경우, 이전의 edge 세팅을 무효로 한다
            %local max 이 세팅된 경우에도, 이전의 edge 세팅을 무효로 한다
            bTmpUp =0; bTmpDown = 0;
        elseif(msdw_tmp(2) < msdw_tmp(3)) %이전이 flat하였고 다음 진행이 올라가는 경우
            if bTmpDown==1  %이전에 내려왔었던 경우
                indexes_localMin = round((idx_cur-1 + tmp_min_id)/2);

                bMinFound = 1;
            end
            %계속 올라가고 있는 경우, 이전의 edge 세팅을 무효로 한다
            %local min 이 세팅된 경우에도, 이전의 edge 세팅을 무효로 한다
            bTmpUp =0; bTmpDown = 0;
        end %계속 flat 한 경우에는 아무것도 하지 않는다.


    %일반적인 local min/max detection
    elseif(msdw_tmp(1)<msdw_tmp(2) && msdw_tmp(2) > msdw_tmp(3) )
        indexes_localMax.add(idx_cur-1);

    elseif(msdw_tmp(1)>msdw_tmp(2) && msdw_tmp(2) < msdw_tmp(3))
        indexes_localMin = idx_cur-1;
        bMinFound = 1;
    end

    if bMinFound ==1 && indexes_localMax.datasize>0 %minimum 값이 발견되고, 이전에 maximum 값이 발견되었던 경우

        id_min = indexes_localMin;
        sum = msdw.get(indexes_localMax.getLast()) - msdw.get(id_min);
        tmp_max_sum = sum;
        curmax_pos = indexes_localMax.getLast();
        r_start = -1;


        %Spike에 있어서 Left와 Right Side를 계산
        bAccept = isCriteriaSatisfied(sum,threshold, min_th_abs_ratio, msdw.get(curmax_pos), msdw.get(id_min));%, id_min, curmax_pos, max_id_window_acc_v(id_min), nLocalMin-1, LRValues_Spike, LRWidths_Spike, bAccept);
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
