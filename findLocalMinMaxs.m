% [mins maxs] = findLocalMinMaxs(data)
% data 에서 local minmax (의 index) 를 찾아 주는 함수
% data는 zero padding 등이 되어 있으면 안된다.
function [mins, maxs] = findLocalMinMaxs(data)
    
    nRow = max(size(data,1), size(data,2));
    
    mins = zeros(nRow,1);
    maxs = zeros(nRow,1);
    min_count = 0;
    max_count = 0;
    bTmpUp = 0;     bTmpDown = 0;
    for i=2:nRow-1
        %일반적인 local min/max detection
        if(data(i)<data(i-1) && data(i) < data(i+1)) %min
            min_count = min_count+1;
            mins(min_count) = i;
            bTmpUp = 0;     bTmpDown = 0;
        elseif(data(i)>data(i-1) && data(i) > data(i+1)) %max
            max_count = max_count+1;
            maxs(max_count) = i;
            bTmpUp = 0;     bTmpDown = 0;
        %peak가 날카롭지 않은 경우를 위한 계산
        elseif(data(i)>data(i-1) && data(i) == data(i+1))  %이전에 비해 증가했으나 다음 진행이 flat 한 경우 /-
            tmp_max_id = i;
            bTmpUp = 1;     bTmpDown = 0;
        elseif(data(i)<data(i-1) && data(i) == data(i+1))  %이전에 비해 감소했으나 다음 진행이 flat 한 경우 /-
            tmp_min_id = i;
            bTmpDown = 1;   bTmpUp = 0;
        elseif(data(i)==data(i-1))
            if(data(i) > data(i+1)  ) %이전이 flat하였고 다음 진행이 내려가는 경우
                if bTmpUp==1  %이전에 올라왔었던 경우
                    max_count = max_count +1;
                    maxs(max_count) = round((i + tmp_max_id)/2);
                end
                %계속 내려가고 있는 경우, 이전의 edge 세팅을 무효로 한다
                %local max 이 세팅된 경우에도, 이전의 edge 세팅을 무효로 한다
                bTmpUp =0; bTmpDown = 0;
            elseif(data(i) < data(i+1)) %이전이 flat하였고 다음 진행이 올라가는 경우
                if bTmpDown==1  %이전에 내려왔었던 경우
                    min_count = min_count+1;
                    mins(min_count) = round((i + tmp_min_id)/2);
                end
                %계속 올라가고 있는 경우, 이전의 edge 세팅을 무효로 한다
                %local min 이 세팅된 경우에도, 이전의 edge 세팅을 무효로 한다
                bTmpUp =0; bTmpDown = 0;
            end %계속 flat 한 경우에는 아무것도 하지 않는다.
        end
    end
    mins(min_count+1:nRow,:) = [];
    maxs(max_count+1:nRow,:) = [];
    
end