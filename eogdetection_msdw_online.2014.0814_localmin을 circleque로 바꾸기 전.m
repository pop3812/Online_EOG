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
    
    %�ʱ�ȭ
    if idx_cur==1
        bTmpUp =0; bTmpDown = 0;    tmp_max_id= 0; tmp_min_id = 0;
    end
    bMinFound = 0;
    range = [];
    
    %�����͸� �Է��ϱ� ���� �̹� queue �� �� �� �ִ� �������� üũ data�� shift Ȯ�� � �ʿ�
    % �̰� 1�̸� calMultiSDW_onebyone �Լ��� ȣ��Ǹ鼭 queue�� ������/������ shift�ϰ� ��
    if v_dataqueue.datasize == v_dataqueue.length
        bDataFull_beforeAddingData = 1;
    else
        bDataFull_beforeAddingData = 0;
    end

    %��������� �����͸� ����� MSDW ���
    [ msdw_cur, windowSize4msdw_cur ] = calMultiSDW_onebyone( dataqueue, v_dataqueue, acc_dataqueue, min_windowwidth, max_windowwidth );
    if isempty(msdw_cur)
        msdw.add(0);
        windowSize4msdw.add(0);
    else
        msdw.add(msdw_cur);
        windowSize4msdw.add(windowSize4msdw_cur);
    end
    
    %�����Ͱ� ����� ������ ���� ��� ó��
    if idx_cur<3
        return;
    end
    
    %queue�� shift �Ǹ�, queue�� �ִ� range �� invalid �Ǵ� ���� �����ϴ� �ڵ�
    if detectedRange_inQueue.datasize>0 && bDataFull_beforeAddingData ==1
        detectedRange_inQueue.data = detectedRange_inQueue.data -1;
        theFirstRange = detectedRange_inQueue.get(1);
        if theFirstRange(1)==0
            detectedRange_inQueue.pop_fromBeginning();
        end
    end
    %queue�� shift �Ǹ�, queue�� �ִ� indexes_localMax �� invalid �Ǵ� ���� �����ϴ� �ڵ�
    if indexes_localMax.datasize>0  && bDataFull_beforeAddingData ==1
        indexes_localMax.data = indexes_localMax.data -1;
        theFirst = indexes_localMax.get(1);
        if theFirst(1)==0
            indexes_localMax.pop_fromBeginning();
        end
    end
    
    

    % i-2, i-1, i �� �� �׸��� �����Ͽ� local min/max �� ����Ѵ�.
    %peak�� ��ī���� ���� ��츦 ���� ���
    msdw_tmp = [ msdw.get(idx_cur-2), msdw.get(idx_cur-1), msdw.get(idx_cur)];
    if(msdw_tmp(1)<msdw_tmp(2) && msdw_tmp(2) == msdw_tmp(3))  %������ ���� ���������� ���� ������ flat �� ��� /-
        tmp_max_id = idx_cur-1;
        bTmpUp = 1;     bTmpDown = 0;
    elseif(msdw_tmp(1)>msdw_tmp(2) && msdw_tmp(2) == msdw_tmp(3))  %������ ���� ���������� ���� ������ flat �� ��� /-
        tmp_min_id = idx_cur-1;
        bTmpDown = 1;   bTmpUp = 0;
    elseif(msdw_tmp(1)==msdw_tmp(2))
        if(msdw_tmp(2) > msdw_tmp(3)) %������ flat�Ͽ��� ���� ������ �������� ���
            if bTmpUp==1    %������ �ö�Ծ��� ���
                indexes_localMax.add(round((idx_cur-1 + tmp_max_id)/2));
            end
            %��� �������� �ִ� ���, ������ edge ������ ��ȿ�� �Ѵ�
            %local max �� ���õ� ��쿡��, ������ edge ������ ��ȿ�� �Ѵ�
            bTmpUp =0; bTmpDown = 0;
        elseif(msdw_tmp(2) < msdw_tmp(3)) %������ flat�Ͽ��� ���� ������ �ö󰡴� ���
            if bTmpDown==1  %������ �����Ծ��� ���
                indexes_localMin = round((idx_cur-1 + tmp_min_id)/2);

                bMinFound = 1;
            end
            %��� �ö󰡰� �ִ� ���, ������ edge ������ ��ȿ�� �Ѵ�
            %local min �� ���õ� ��쿡��, ������ edge ������ ��ȿ�� �Ѵ�
            bTmpUp =0; bTmpDown = 0;
        end %��� flat �� ��쿡�� �ƹ��͵� ���� �ʴ´�.


    %�Ϲ����� local min/max detection
    elseif(msdw_tmp(1)<msdw_tmp(2) && msdw_tmp(2) > msdw_tmp(3) )
        indexes_localMax.add(idx_cur-1);

    elseif(msdw_tmp(1)>msdw_tmp(2) && msdw_tmp(2) < msdw_tmp(3))
        indexes_localMin = idx_cur-1;
        bMinFound = 1;
    end

    if bMinFound ==1 && indexes_localMax.datasize>0 %minimum ���� �߰ߵǰ�, ������ maximum ���� �߰ߵǾ��� ���

        id_min = indexes_localMin;
        sum = msdw.get(indexes_localMax.getLast()) - msdw.get(id_min);
        tmp_max_sum = sum;
        curmax_pos = indexes_localMax.getLast();
        r_start = -1;


        %Spike�� �־ Left�� Right Side�� ���
        bAccept = isCriteriaSatisfied(sum,threshold, min_th_abs_ratio, msdw.get(curmax_pos), msdw.get(id_min));%, id_min, curmax_pos, max_id_window_acc_v(id_min), nLocalMin-1, LRValues_Spike, LRWidths_Spike, bAccept);
        if(bAccept==1)   %������ �����ϴ� ���
            %ó���� ���õ� ������ ���� ������ ��ġ�� ��� starting point�� �����Ѵ�.
            %�̶� �� ������ ������ ������ �����ϴ� ���� �ٶ������� �ʴ�.

            r_start = curmax_pos - windowSize4msdw.get(curmax_pos);
            
            if(detectedRange_inQueue.datasize>0)
                prev_range = detectedRange_inQueue.getLast();
                if r_start<=prev_range(2)
                    r_start = prev_range(2);
                end
            end
        end


        for k=0:indexes_localMax.datasize-2 %������ max ������ ���ٷ� �ϳ��� ¤�� ���鼭 ������ max ���� �������� range�� ���� �� �ִ��� üũ�Ѵ�.
            if(id_min - indexes_localMax.get_fromEnd(2+k)>max_windowwidth)        %���� ���� (max_windowwidth *2) ���� maximum value�� �ƴ� ��� �ߴ�
                break;
            end
            prev_range = [];
            if(detectedRange_inQueue.datasize>0)
                prev_range = detectedRange_inQueue.getLast();
            end

            %������ range�� ��ġ�� �����鼭 sum�� �ִ��� ��츦 ã�´�. (���� range�� �����ϴ� ���� ������.)
            curmax_pos  = indexes_localMax.get_fromEnd(k+2);                  %���� ���캼 max ������ �ε���
            prevmax_pos = indexes_localMax.get_fromEnd(k+1);                    %������ ���캻 max������ �ε���
            sum = sum + msdw.get(curmax_pos) - msdw.get(prevmax_pos);  %�� ���� ������ ������ ���� ���� ��������� ���� ���Ѵ�.

            r_start_tmp = curmax_pos - windowSize4msdw.get(curmax_pos);            %range�� ������

            tmp_check_result = isCriteriaSatisfied(sum,threshold,min_th_abs_ratio, msdw.get(curmax_pos), msdw.get(id_min));%, id_min, curmax_pos,max_id_window_acc_v(id_min), nLocalMin-1-k, LRValues_Spike, LRWidths_Spike, bAccept);
            if(sum>tmp_max_sum  && tmp_check_result==1) %������ �����ϴ� ���

                tmp_max_sum = sum;
                if(detectedRange_inQueue.datasize==0 || r_start_tmp>=prev_range(2))  %������ range�� ��ġ�� �ʴ´ٸ� starting point�� Ȯ���Ѵ�
                    r_start = r_start_tmp; 
                end

                while(detectedRange_inQueue.datasize>0 && r_start_tmp<=prev_range(1))  %���� range�� �����Ѵٸ�, (2�� �̻��� range�� ���ÿ� �����Ͽ� ������ ���ɼ��� �����Ƿ� if ��� while�� ����.)
                    detectedRange_inQueue.pop();%������ range�� �����Ѵ�. 
                    
                    %�̹� range�� ����������, ���� range�͵� ��ġ�� ���������� ���ϴ� ��� ó��
                    %range�� ���� range�� �������� �����ϵ��� �Ѵ�.
                    if(detectedRange_inQueue.datasize>0) 
                        prev_range = detectedRange_inQueue.getLast();
                        if r_start_tmp<prev_range(2) %���� range�� ��ġ�� ��� �ϴ� �� range�� ������ ���������� �� �ΰ�, �����ϴ� ��쿡�� while ���� ������ iteration ���� ó���Ѵ�.
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
