%checkLocalMinMax 함수
% 최근 3개의 데이터를 가지고 local min max를 찾아주는 함수
% data 는 circlequeue 형식으로 된 데이터, idx_cur은 circlequeue 에서 current 데이터의 index
% tmp_max_id, tmp_min_id, bTmpUp, bTmpDown, bMinFound 는 최초에 0으로 세팅되어 입력되어야
% 하며, 함수가 반복되어 호출되면서 값이 변화된다.
% indexes_localMin과  indexes_localMax 는 circle queue 형식으로 local min& max 의
% index 지점이 저장된다.
function [tmp_max_id, tmp_min_id, bTmpUp, bTmpDown, bMinFound] = checkLocalMinMax(data, tmp_max_id, tmp_min_id, bTmpUp, bTmpDown, indexes_localMin, indexes_localMax, idx_cur)
    bMinFound = 0;
    data_recent = [ data.get(idx_cur-2), data.get(idx_cur-1), data.get(idx_cur)];
    if(data_recent(1)<data_recent(2) && data_recent(2) == data_recent(3))  %이전에 비해 증가했으나 다음 진행이 flat 한 경우 /-
        tmp_max_id = idx_cur-1;
        bTmpUp = 1;     bTmpDown = 0;
    elseif(data_recent(1)>data_recent(2) && data_recent(2) == data_recent(3))  %이전에 비해 감소했으나 다음 진행이 flat 한 경우 /-
        tmp_min_id = idx_cur-1;
        bTmpDown = 1;   bTmpUp = 0;
    elseif(data_recent(1)==data_recent(2))
        if(data_recent(2) > data_recent(3)) %이전이 flat하였고 다음 진행이 내려가는 경우
            if bTmpUp==1    %이전에 올라왔었던 경우
                indexes_localMax.add(round((idx_cur-1 + tmp_max_id)/2));
            end
            %계속 내려가고 있는 경우, 이전의 edge 세팅을 무효로 한다
            %local max 이 세팅된 경우에도, 이전의 edge 세팅을 무효로 한다
            bTmpUp =0; bTmpDown = 0;
        elseif(data_recent(2) < data_recent(3)) %이전이 flat하였고 다음 진행이 올라가는 경우
            if bTmpDown==1  %이전에 내려왔었던 경우
                indexes_localMin.add(round((idx_cur-1 + tmp_min_id)/2));

                bMinFound = 1;
            end
            %계속 올라가고 있는 경우, 이전의 edge 세팅을 무효로 한다
            %local min 이 세팅된 경우에도, 이전의 edge 세팅을 무효로 한다
            bTmpUp =0; bTmpDown = 0;
        end %계속 flat 한 경우에는 아무것도 하지 않는다.


    %일반적인 local min/max detection
    elseif(data_recent(1)<data_recent(2) && data_recent(2) > data_recent(3) )
        indexes_localMax.add(idx_cur-1);

    elseif(data_recent(1)>data_recent(2) && data_recent(2) < data_recent(3))
        indexes_localMin.add(idx_cur-1);
        bMinFound = 1;
    end
end