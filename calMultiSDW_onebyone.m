%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calMultiSDW_onebyone
%
% 온라인 버전의 calMultiSDW
% calMultiSDW 과 동일하나, 가장 최근에 들어온 데이터를 사용하여 msdw를 추가로 계산한다.
% 파라메터 data, v_data, acc_v 는 모두 circlequeue type이며 idx_cur는 circule queue의 외부 index 번호,
%return 값은 마지막 지점의 msdw와 window size이다.
%
function [ msdw, windowSize4msdw, v_data, acc_v ] = calMultiSDW_onebyone( data, v_data, acc_v, min_windowwidth, max_windowwidth )
    %데이터가 충분하지 않은 경우 empty matrix를 리턴한다
    msdw = [];
    windowSize4msdw = [];

    if v_data.datasize==0
        v_data.add(0);
        acc_v.add(0);
        return;
    end

    v_data.add(data.getLast() - data.get_fromEnd(2));
    acc_v.add (acc_v.getLast()+v_data.getLast());
    
    if v_data.datasize==1   %아직 누적벡터합을 계산할 수 없는 경우
        return;
    end
    
    windowSize4msdw = 0;

    % window width를 변화시키며 그 중 누적벡터합의 절대값이 최대가 되게 하는 window size와 그 때의 누적벡터합을 계산한다.
    %이때 두 가지 조건이 맞아야 한다. 1.방향성이 맞아야 한다. 즉 벡터의 방향이 바뀌는 것은 짝수번인 경우만 허용한다
    %                               2.현재점의 데이터와 window width 이전의 데이터 사이에 두 데이터의 값의 범위를 벗어나는 데이터가 있어서는 안된다.
    max_abs_window_acc_v = 0; 
    sign_change_counter = 0;
    prev_sign = v_data.getLast();
    bBiggerDataFound    = 0;
    bSmallerDataFound   = 0;
    for j = 1:max_windowwidth-1
        sign = v_data.get_fromEnd(j+1);
        if isempty(sign)
            break;
        end

        %if(idx_cur-j-1>0) %위의 isEmpty 에서 구현됨
            if(sign*prev_sign <0)
                sign_change_counter = sign_change_counter+1;
            end

            %2.현재점의 데이터와 window width 이전의 데이터 사이에 두 데이터의 값의 범위를 벗어나는
            % 데이터가 있어서는 안된다. 이를 체크하고 발견시에는 곧바로 멈추며, max id 가 찾아지기 전에 멈춘
            % 경우에는 최소 window size를  max id로 지정해 준다.
            %if(v_data.get(idx_cur)<v_data.get(idx_cur-j))       
            if(v_data.getLast()<v_data.get_fromEnd(j+1))       
                bBiggerDataFound = 1;   
            %elseif(v_data.get(idx_cur)>v_data.get(idx_cur-j))   
            elseif(v_data.getLast()>v_data.get_fromEnd(j+1))   
                bSmallerDataFound = 1;   
            end
            if bBiggerDataFound *bSmallerDataFound==1
                break;
            end

            %abs_win_acc_v = abs(acc_v.get(idx_cur) - acc_v.get(idx_cur-j-1));
            abs_win_acc_v = abs(acc_v.getLast() - acc_v.get_fromEnd(j+1));
            %if (j>=min_windowwidth && abs_win_acc_v> max_abs_window_acc_v && mod(sign_change_counter,2)==0 && v_data.get(idx_cur)*v_data.get(idx_cur-j)>=0 )   %방향성이 맞고 min max 범위 내에 있는 것들 중 최대값 % bug_fixed. however, it should be checked again
            if (j>=min_windowwidth && abs_win_acc_v> max_abs_window_acc_v && mod(sign_change_counter,2)==0 && v_data.getLast()*v_data.get_fromEnd(j+1)>=0 )   %방향성이 맞고 min max 범위 내에 있는 것들 중 최대값 % bug_fixed. however, it should be checked again
                max_abs_window_acc_v = abs_win_acc_v;
                windowSize4msdw= j+1;
            end
            if(sign~=0)
                prev_sign = sign;
            end
       % end
    end
    if windowSize4msdw==0
        windowSize4msdw = min_windowwidth;
    end

    tmp = acc_v.get_fromEnd(windowSize4msdw);
    if isempty(tmp)
        msdw = 0;
    else
        msdw = acc_v.getLast() - acc_v.get_fromEnd(windowSize4msdw);
    end


end

