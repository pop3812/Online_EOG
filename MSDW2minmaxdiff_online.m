% MSDW2minmaxdiff_online
% MSDW2minmaxdiff 의 온라인 버전 함수
%
% msdw 가 계산된 상태에서 적절한 threshold 값을 추정할 수 있도록 minmax 의 차이 형태로 바꾼다.
% local minimum이 새롭게 insert 된 시점에 호출되어야 한다.
%
% msdw: msdw (circlequeue type)
% max_windowwidth: msdw 계산에서 사용된 window의 크기
% indexes_localMin: msdw 의 local min이 들어있는 circlequeue
% indexes_localMax: msdw 의 local max가 들어있는 circlequeue
%
% minmaxdiff: circlequeue type의 output (handle 형식이기 때문에 return할 필요 없다)
%
function MSDW2minmaxdiff_online(msdw, max_windowwidth, indexes_localMin, indexes_localMax, minmaxdiff)
    
    if indexes_localMin.datasize<1 || indexes_localMax.datasize<1
        return;
    end
    

    %가장 최근의 local min에 대해서 msdw를 min-max difference 형태로 conversion 한다. (여기서
    %max는 min의 앞에 존재하는 max이며, min-max 의 index 차이가 max_windowwidth 보다 커서는
    %안된다.
    min_id = indexes_localMin.getLast();
    nPrevLocalMax = indexes_localMax.datasize;
    
    for j=1:nPrevLocalMax % 여기서 j는 prev_max 의 reversed id가 된다.
        max_id = indexes_localMax.get_fromEnd(j);
        if min_id - max_id > max_windowwidth  %min-max 의 index 차이가 max_windowwidth 보다 크면 멈춘다
            break;
        end
        tmp_minmaxdiff = msdw.get(max_id) - msdw.get(min_id);
        if j==1
            minmaxdiff.add(tmp_minmaxdiff);
        elseif tmp_minmaxdiff> minmaxdiff.getLast()
            minmaxdiff.data(minmaxdiff.index_end,:) = tmp_minmaxdiff;
        end
    end

end