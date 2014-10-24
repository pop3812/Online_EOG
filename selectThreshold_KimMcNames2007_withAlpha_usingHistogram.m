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
function threshold = selectThreshold_KimMcNames2007_withAlpha_usingHistogram(histogram, alpha)
    
    v = 1;
    
    h = fliplr(histogram.bin);
   % h2 = smoothts(h,'g');
    %half_delta = histogram.delta/2;
    xi = fliplr(histogram.xi);
    
    [min_ids_KS, max_ids_KS] = findLocalMinMaxs(h');
    nKSMax = size(max_ids_KS,1);
    nKSMin = size(min_ids_KS,1);
    if nKSMax==0 % 분포도가 나오지 않은 경우. 즉 dist 배열이 비어 있는 경우
        disp('Error:In func. selectThreshold. Input data is Empty');
        threshold = -1;
        return;
    elseif nKSMax>1%패턴의 분포가 2개 이상인 경우
        %조건 1              : min값은 양쪽 max 값중 작은 값의 일정 비율(논문에서는 v=0.5) 이하가 되어야 한다. v 값은 바뀔 수 있다.
        %조건 2(by Dr. Chang): min값의 index는 global max 값의 index보다 작아야 한다.
        %조건 2는 max값을 가능하면 사용하지 않기 위해 사용되었다.
        %이 조건을 만족하지 않는 min값과 max 값중 작은 것을 지운다
        [global_max, global_max_index] = max(h);
        if max_ids_KS(nKSMax)< min_ids_KS(nKSMin)
            min_ids_KS(nKSMin)=[];
            nKSMin = nKSMin-1;
        end
        if max_ids_KS(1)> min_ids_KS(1)
            min_ids_KS(1) = [];
            nKSMin = nKSMin-1;
        end
        
        for i= nKSMin:-1:1
            if i+1>nKSMax   %해당 min이 맨 끝이고, 그 뒤에 max가 없는 경우
                min_ids_KS(i) = [];
                continue;
            end
            tmp_min =min(h(max_ids_KS(i)),h(max_ids_KS(i+1)));
            if h(max_ids_KS(i))<h(max_ids_KS(i+1))
                tmp_min_id = i;
            else
                tmp_min_id = i+1;
            end
            
            %if f(min_ids_KS(i))>=v* tmp_min || min_ids_KS(i)>=global_max_index
            if h(min_ids_KS(i))>=v* tmp_min || min_ids_KS(i)>=global_max_index
                min_ids_KS(i) = [];
                max_ids_KS(tmp_min_id)= [];
            end
        end
        
        nKSMax = size(max_ids_KS,1);
        nKSMin = size(min_ids_KS,1);
    end
    
    if nKSMax==1 % 1개패턴의 분포밖에 나오지 않는 경우
        threshold = -1;
%         nDataInh = sum(h);
%         if nExpectedMaxEvent+1<= size(nDataInh,1)
%             threshold = (localMins(nExpectedMaxEvent,2) + localMins(nExpectedMaxEvent+1,2))/2;
%         else
%             threshold = localMins(nExpectedMaxEvent,2) +1;
%         end
    else 
        threshold = xi(min_ids_KS(nKSMin));
        
        %나누어진 오른쪽의 std를 따로 구해 std의 일정비율만큼 위치를 조정한다.
        km_idx_min = min_ids_KS(nKSMin);
        
        nDataE1 = sum(h(km_idx_min:histogram.nBin));
        meanE1 = sum(h(km_idx_min:histogram.nBin).*xi(km_idx_min:histogram.nBin))/nDataE1;
        varE1 = sum(h(km_idx_min:histogram.nBin).*(xi(km_idx_min:histogram.nBin) - meanE1).^2)/(nDataE1-1);
        threshold = threshold - sqrt(varE1) * alpha;
    end
        
end