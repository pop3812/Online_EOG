% --------------------------------------
% selectThreshold_KimMcNames2007_withAlpha �Լ��� h ����.
% h �� �̸� ���Ǿ� �ִ� ��� h �� �Ķ���ͷ� �޾Ƽ� ó���Ѵ�.
% threshold = selectThreshold(data);
% threshold �� �ڵ����� ������ �ش�.
% algorithm by S.Kim & J. McNames (2007, J. Neuroscience Method: Automatic spike detection based on adaptive template matching for extracellular neural recordings)
% program by Won-Du Chang, ph.D, 
% Post-Doc @  Department of Biomedical Engineering, Hanyang University
% 12cross@gmail.com
%---------------------------------------------------------------------
% start_index: start_index ������ ���� �����Ѵ�.
% nExpectedMaxEvent: ������ ������ ����Ǵ� event�� �ִ��
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
    if nKSMax==0 % �������� ������ ���� ���. �� dist �迭�� ��� �ִ� ���
        disp('Error:In func. selectThreshold. Input data is Empty');
        threshold = -1;
        return;
    elseif nKSMax>1%������ ������ 2�� �̻��� ���
        %���� 1              : min���� ���� max ���� ���� ���� ���� ����(�������� v=0.5) ���ϰ� �Ǿ�� �Ѵ�. v ���� �ٲ� �� �ִ�.
        %���� 2(by Dr. Chang): min���� index�� global max ���� index���� �۾ƾ� �Ѵ�.
        %���� 2�� max���� �����ϸ� ������� �ʱ� ���� ���Ǿ���.
        %�� ������ �������� �ʴ� min���� max ���� ���� ���� �����
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
            if i+1>nKSMax   %�ش� min�� �� ���̰�, �� �ڿ� max�� ���� ���
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
    
    if nKSMax==1 % 1�������� �����ۿ� ������ �ʴ� ���
        threshold = -1;
%         nDataInh = sum(h);
%         if nExpectedMaxEvent+1<= size(nDataInh,1)
%             threshold = (localMins(nExpectedMaxEvent,2) + localMins(nExpectedMaxEvent+1,2))/2;
%         else
%             threshold = localMins(nExpectedMaxEvent,2) +1;
%         end
    else 
        threshold = xi(min_ids_KS(nKSMin));
        
        %�������� �������� std�� ���� ���� std�� ����������ŭ ��ġ�� �����Ѵ�.
        km_idx_min = min_ids_KS(nKSMin);
        
        nDataE1 = sum(h(km_idx_min:histogram.nBin));
        meanE1 = sum(h(km_idx_min:histogram.nBin).*xi(km_idx_min:histogram.nBin))/nDataE1;
        varE1 = sum(h(km_idx_min:histogram.nBin).*(xi(km_idx_min:histogram.nBin) - meanE1).^2)/(nDataE1-1);
        threshold = threshold - sqrt(varE1) * alpha;
    end
        
end