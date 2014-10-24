% --------------------------------------
% selectThreshold_KimMcNames2007_withAlpha 함수의 h 버전.
% h 이 미리 계산되어 있는 경우 h 을 파라메터로 받아서 처리한다.
% threshold = selectThreshold(data);
% threshold 를 자동으로 선택해 준다.
% algorithm by S.Kim & J. McNames (2007, J. Neuroscience Method: Automatic spike detection based on adaptive template matching for extracellular neural recordings)
% program by Won-Du Chang, ph.D, 
% Post-Doc @  Department of Biomedical Engineering, Hanyang University
% 12cross@gmail.com
%---------------------------------------------------------------------
% start_index: start_index 앞쪽의 값은 무시한다.
% nExpectedMaxEvent: 출현할 것으로 예상되는 event의 최대빈도
%---------------------------------------------------------------------
function threshold = selectThreshold_KimMcNames2007_withAlpha_usingHistogram_v2(histogram, alpha,v)
    
    if nargin<3
        v = 0.4;
    end
    h = histogram.bin;
    %h = fliplr(histogram.bin);
   % h2 = smoothts(h,'g');
    %half_delta = histogram.delta/2;
    %xi = fliplr(histogram.xi);
    
    threshold = -1;
    
    [min_ids_KS, max_ids_KS] = findLocalMinMaxs(h');
    nKSMax = size(max_ids_KS,1);
    nKSMin = size(min_ids_KS,1);
    if nKSMax==0 % 분포도가 나오지 않은 경우. 즉 dist 배열이 비어 있는 경우
        disp('Error:In func. selectThreshold. Input data is Empty');
        return;
    elseif nKSMax>1%패턴의 분포가 2개 이상인 경우
        %조건 1              : 
        %조건 2(by Dr. Chang): min값의 index는 global max 값의 index보다 작아야 한다.
        %조건 2는 max값을 가능하면 사용하지 않기 위해 사용되었다.
        %이 조건을 만족하지 않는 min값과 max 값중 작은 것을 지운다
        
        if max_ids_KS(nKSMax)< min_ids_KS(nKSMin) %최후의 local max 이후에 local min 이 존재한다면 최후의 min을 삭제한다.
            min_ids_KS(nKSMin)=[];
            nKSMin = nKSMin-1;
        end
        if max_ids_KS(1)> min_ids_KS(1)     %최초의local max 이전에 local min 이 존재한다면 최초의 min을 삭제한다.
            min_ids_KS(1) = [];
            nKSMin = nKSMin-1;
        end
        
        %global max 를 찾는다
        global_max_id = 1;
        for i= 2:nKSMax
            if h(max_ids_KS(i))> h(max_ids_KS(global_max_id))
                global_max_id = i;
            end
        end
        global_max = h(max_ids_KS(global_max_id));
        
        %아래 부분의 코드는 분포도에서 최초의 local max 가 최초의 local min에 선행한다고 전제한다.
        for i= global_max_id+1:nKSMax
            Max_i = h(max_ids_KS(i));
            if Max_i/global_max<v              %조건
                km_idx_min = min_ids_KS(i-1);
                threshold = histogram.xi(km_idx_min);
                break;
            end
        end
    end
    
    if threshold<0 %조건에 맞는 기준점을 찾지 못한 경우
        return;
    else 
        %나누어진 오른쪽의 std를 따로 구해 std의 일정비율만큼 위치를 조정한다.
        nDataE1 = sum(h(1:km_idx_min));
        meanE1 = sum(h(1:km_idx_min).*histogram.xi(1:km_idx_min))/nDataE1;
        varE1 = sum(h(1:km_idx_min).*(histogram.xi(1:km_idx_min) - meanE1).^2)/(nDataE1-1);
        threshold = threshold - sqrt(varE1) * alpha;
    end
        
end