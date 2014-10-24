% ---------------------------------------------------------------------
%   - calculateAccuracy-
%  accuracy Calculation (FPR, TPR)
% calculateAccuracyInRange_usingRank �Լ��� ����������, MSDW ������ ����ȭ�Ǿ���.
% �ֳ��ϸ� MSDW �� range�� ranking�� �ű�� ���� �������� �ʱ� �����̴�.
% ���⼭ range_according2rank �� eogdetection_RangeRanking_MSDW �Լ��� ���ؼ� ���� ������
% threshold �� ���� ����� range�� ����Ʈ�� �� ���� �����ϰ� �ִ�.
%----------------------------------------------------------------------
% by Won-Du Chang, ph.D, 
% Post-Doc @  Department of Biomedical Engineering, Hanyang University
% contact: 12cross@gmail.com
%---------------------------------------------------------------------
function [nFP, nFN, nGT,totalTime_Negative] = calculateAccuracyInRange_4OnlineTest(range_groundTruth, range_detected)

    range_groundTruth = sortrows(range_groundTruth);
    amb_col_id = 4;

%%FN���--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    %seperate ambiguous ranges from GT ranges
    [amb_range,concrete_range_ref] = seperateAmbiguousRange(range_groundTruth, amb_col_id);
    concrete_range_ref = sortrows(concrete_range_ref);

    %FN range calculation
    [nMissedRanges, nMissedPoints, nPoints, list_MissedRangeid, list_MissedPointid] = isFullMatch_Points2Ranges(range_detected, concrete_range_ref(:,3));
    
    nFN = nMissedPoints;
    list_FN = range_groundTruth(list_MissedRangeid,3); % FN range �� peak point
    
    FN_range = SubtractRanges4NormalizedError(concrete_range_ref,range_detected);

    nGT  = size(concrete_range_ref,1);
    nFN = zeros(nThreshold, nDivision);
    nFN(:,nDivision) = NaN;
    nDelta_Positive = 0.5/(nDivision-1);  %ratio
    for i=1:nDivision-1  % ������ error tolerance�� ����
        target_threshold_positive = nDelta_Positive*(i-1); 
        for j=1:nThreshold %������ ����� range�鿡 ���� FN�� count �Ѵ�.
            if j==101 &&i==3
                eee=3;
            end
            for k=1:nGT         %������ Ground Truth�� ���� FN ���θ� üũ�ϰ� ������ count�� ������Ų��.
                nItem = size(FN_range{j}{k},1);
                cnt = 0;
                for m = 1:nItem  %�¿� FN�� �ϳ��� tolerance�� �Ѱܵ� ī��Ʈ�Ѵ�.
                    if FN_range{j}{k}(m,1)>target_threshold_positive
                        cnt = 1;
                    end
                end
                nFN(j,i) = nFN(j,i) +cnt;
            end
        end
    end

   
    
    
    
%%FP���--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    %find matching reference_id for each test range
    %correspondingRefID_ofTestRange = FindCorrespondingRefID(range_test, concrete_range_ref);
    %������ test range�� ���� �����ϴ� peak ������ 
    
    %peakids = peakids_ref(correspondingRefID_ofTestRange,1);
    fprintf('start removing ambiguous positivie from test data..\n');
    
    
    

    range_test = cell(nThreshold,1);
    for p=1:nThreshold
        %range�� �ð������� ����
    %     rank = [1:nTotalRange]';
         %range_test = [range_according2rank, rank];
         range_test{p} = sortrows(range_detected{p},1);
         nTest  = size(range_test{p},1);

        % Ambiguous Range Removal from Test Range
        test_cnt = 1;
        ref_cnt = 1;
        nRef = size(range_groundTruth,1);
        while test_cnt<=nTest && ref_cnt <=nRef
            if range_groundTruth(ref_cnt,2)<=range_test{p}(test_cnt,1)
                ref_cnt= ref_cnt+1;
            elseif range_test{p}(test_cnt,2)<=range_groundTruth(ref_cnt,1)
                test_cnt = test_cnt+1;
            else % ��ġ�� ���
                bAmbiguousFound = range_groundTruth(ref_cnt,amb_col_id);
                bAllAmbigous = bAmbiguousFound;
                ref_end_id = ref_cnt;
                while ref_end_id+1<=nRef && range_groundTruth(ref_end_id+1,1)<range_test{p}(test_cnt,2) %�ϳ��� test�� �������� ref �� ��ġ�� ��츦 üũ
                    ref_end_id = ref_end_id+1;
                end
                for i=ref_cnt:ref_end_id
                    bAmb = range_groundTruth(i,amb_col_id);
                    if bAmbiguousFound ==0 && bAmb==0
                        bAmbiguousFound = 0;
                    else
                        bAmbiguousFound = 1;
                    end

                    if bAllAmbigous==1 && bAmb==1
                        bAllAmbigous = 1;
                    else
                        bAllAmbigous = 0;
                    end
                end

                if bAmbiguousFound==0   %ambiguous ���� ���� ��쿡�� skip �ϰ� ��������
                    test_cnt = test_cnt+1;
                    ref_cnt= ref_end_id+1;
                elseif ref_end_id==ref_cnt || bAllAmbigous==1 %ambigous������ 1:1 ��Ī�Ǵ� ��� �Ǵ� ��� ambigous�ϴ� ��쿡�� test���� �����
    %                 range_test(test_cnt,:) = [];
    %                 nTest = nTest -1;%�ϳ��� �������Ƿ� test_cnt �� ������Ű�� �ʴ´�
                    range_test{p}(test_cnt,1:2) =  [0 0]; % ������ �ʰ� [0 0] array�� �����.
                    test_cnt = test_cnt+1; 
                else   %ambigous�ϸ鼭 �ϳ��� test�� �������� ref�� ��Ī�Ǹ�, ��Ī�Ǵ� ref���� amb �� concrete�� ���� �ִ� ���
                    range2delete = zeros(1,2);
                    delete_cnt = 0;
                    for i=ref_cnt:1:ref_end_id-1
                        if range_groundTruth(ref_cnt,amb_col_id)==0 &&range_groundTruth(ref_cnt+1,amb_col_id)==0 %���ӵǴ� �� ref_range �� ��� ambi�� �ƴ� ���.
                            %do nothing
                        elseif range_groundTruth(ref_cnt,amb_col_id)==1 &&range_groundTruth(ref_cnt+1,amb_col_id)==1 %���ӵǴ� �� ref_range �� ��� ambi�� ���.
                            if i==ref_end_id-1    %���� range�� ������ range�� ��� ���� �͵� �����
                                range2delete(delete_cnt+1,2) = range_test{p}(test_cnt,2);
                                delete_cnt = delete_cnt+1;
                            else %�������� �ƴ� ��� skip�ϰ���� ���� ������ �Ѵ�
                            end
                        elseif range_groundTruth(ref_cnt,amb_col_id)==0 &&range_groundTruth(ref_cnt+1,amb_col_id)==1
                            range2delete(delete_cnt+1,1) = round((range_groundTruth(ref_cnt,2) + range_groundTruth(ref_cnt+1,1))/2);
                            if i==ref_end_id-1    %���� range�� ������ range�� ���
                                range2delete(delete_cnt+1,2) = range_test{p}(test_cnt,2);
                                delete_cnt = delete_cnt+1;
                            end
                        else
                            if i==ref_cnt %�� ó���� ���
                                range2delete(delete_cnt+1,1) = range_test{p}(test_cnt,1);
                            end
                            range2delete(delete_cnt+1,2) = round((range_groundTruth(ref_cnt,2) + range_groundTruth(ref_cnt+1,1))/2);
                            delete_cnt = delete_cnt+1;
                        end
                    end

                    %�����

                    tmp = SubtractRanges_fromaRange(range_test{p}(test_cnt,1:2),range2delete);
                    if size(tmp,1)==0
                        range_test{p}(test_cnt,1:2) = [0 0];
                    else
                        range_test{p}(test_cnt,1:2) =tmp;
                    end

                end
            end
        end
    end
    
    totalTime = size(data,1)/samplingRates;
    totalTime_Positive = sum(range_groundTruth(:,2) - range_groundTruth(:,1))/samplingRates;
    totalTime_Negative = totalTime - totalTime_Positive;
    
    FP_range = cell(nThreshold,1);
    for i=1:nThreshold
        %FN range calculation
        FP_range{i} = SubtractRanges4NormalizedError_4useBasRef(range_test{i},concrete_range_ref,samplingRates);
    end
    
    fprintf('start FP counting..\n');

    nFP = zeros(nThreshold, nDivision);
    nDelta_Negative = 0.3/(nDivision-1);  %ratio
    %FP_Range_Integrated = cell(nTotalRange, nDivision);
    
    for i=1:nDivision  % ������ error tolerance�� ����
        target_threshold_negative = nDelta_Negative*(i-1); 
        for j=1:nThreshold %������ threshold�� ���� FP�� count �Ѵ�.
             nFPRange = size(FP_range{j},1);
             FP_Range_Integrated = ones(nFPRange,2)*Inf;
             nRangeIntegrated = 0;
                
            for k = 1: nFPRange %������ FP Range�� ���� FP ���θ� üũ�ϰ� ������ count�� ������Ų��.
                nItem = size(FP_range{j}{k},1);
                for m = 1:nItem
                    if FP_range{j}{k}(m,2)>target_threshold_negative
                        [FP_Range_Integrated, nRangeIntegrated] = IntegrateARange2Ranges(FP_Range_Integrated, FP_range{j}{k}(m,3:4), nRangeIntegrated);
                        %nFP(j,i) = nFP(j,i) + FP_range{j}{k}(m,2);
                    end
                end
            end
            
            if nRangeIntegrated>0
                nFP(j,i) = sum(FP_Range_Integrated(1:nRangeIntegrated,2) - FP_Range_Integrated(1:nRangeIntegrated,1));
            end
        end
    end
    nFP = nFP ./samplingRates;
    
    %------------------------------------------------------------------------
%     %FNR, FPR ���
%     FPR_tmp = nFP./totalTime_Negative;
%     FNR_tmp = nFN./nGT;
%     
%     %nCheckPoint = 101;
%     delta = 1/(nCheckPoint-1);
%     FPR = 0:delta:1;
%     FNR_wrtFNTolerance = zeros(nCheckPoint,nDivision);
%     FNR_wrtFNTolerance (1,:) = 1;
%     
%     for k=1:nDivision
%         tmp_id = 1;
%         for i=2:nCheckPoint
%             FPR2find = FPR(i);
%             div2find = 1;
%             dist = abs(FPR_tmp(tmp_id,div2find) - FPR2find);
%             while tmp_id<nThreshold && dist>=abs(FPR_tmp(tmp_id+1,div2find) - FPR2find)
%                 tmp_id = tmp_id+1;
%                 dist = abs(FPR_tmp(tmp_id,div2find) - FPR2find);
%             end
%             
%             if dist< delta
%                 FNR_wrtFNTolerance(i,k) = FNR_tmp(tmp_id,k);
%             else
%                 FNR_wrtFNTolerance(i,k) = NaN;
%             end
%         end
%     end
%     
%     FNR_wrtFPTolerance = zeros(nCheckPoint,nDivision);
%     FNR_wrtFPTolerance (1,:) = 1;
%     for k=1:nDivision
%         tmp_id = 1;
%         for i=2:nCheckPoint
%             FPR2find = FPR(i);
%             div2find = k;
%             dist = abs(FPR_tmp(tmp_id,div2find) - FPR2find);
%             while tmp_id<nThreshold && dist>=abs(FPR_tmp(tmp_id+1,div2find) - FPR2find)
%                 tmp_id = tmp_id+1;
%                 dist = abs(FPR_tmp(tmp_id,div2find) - FPR2find);
%             end
%             if dist< delta
%                 FNR_wrtFPTolerance(i,k) = FNR_tmp(tmp_id,1);
%             else
%                 FNR_wrtFPTolerance(i,k) = NaN;
%             end
%         end
%     end
    
end
    
%     %Range Removal from Test Range, if range is not matched to ref range
%     %test range�� peak �� ref�� ���Ե��� ���� ��쿡 �����Ѵ� (���ԵǾ� ���� ���� ��쿡�� �Ϲ����� ����������� ������ ����)
%     [peakvalues_test, peakids_test] = getExtremePointInRanges( data, range_test, 1 );                                                               %nonAmbiguous Test set �� peak id ���
%     [a, b, c, list_refid_notMatched2TestPoint, list_testid_notInConcreteRefRange] = isFullMatch_Points2Ranges(concrete_range_ref, peakids_test);    %concrete ref range �� nonAmbiguous Test peak ���� full match test
%     range_test = range_test(setdiff(1:1:nTest,list_testid_notInConcreteRefRange),:);                                                                %test range �� concrete range�� ���Ե��� ���� ���� ����
%     
%     nTest = size(range_test,1);
%     nRef = size(concrete_range_ref,1);
%     
%     %Range Removal from Ref Range, if 
%     range_ref = range_ref(setdiff(1:1:nRef,list_refid_notMatched2TestPoint),:);
%     [peakvalues_ref, peakids_ref] = getExtremePointInRanges( data, concrete_range_ref, 1 );
    
    
    
function c = SubtractRanges4NormalizedError_4useBasRef(a,b,SamplingRates)
    nA = size(a,1);
    nB = size(b,1);

    %range�� �켱 �� ����.
    c = cell(nA,1);
    bFullFP = zeros(nA,1); %���� �������� �ʴ� ���� ���� ī��Ʈ�Ѵ�.
    for i=1:nA
        c{i} = [a(i,:)];
        for j=1:nB
            if  b(j,2)>a(i,1) && b(j,1)<a(i,2)
                c{i} = Subtract_aRange_fromRanges(c{i},b(j,:));
            end
        end
        % A-B�� �ϸ鼭, B�� ref�� ���� ��쿡, ���� �������� �ʴ� �κ��� �����.
        if size(c{i},1) ==size(a(i,:),1) && isequal(c{i}, a(i,:))
            bFullFP(i) = 1;
        end
    end
    
    %������ C�� ���ؼ� corresponding reference id�� ã�´�
    nC = size(c,1);
    corresponding_ref_id = cell(nC,1);
    ref_count =1;
    for i=1:nC
        nDivision = size(c{i},1);
        corresponding_ref_id{i} = zeros(nDivision,1);
        nAdded = 0;
        for j=1: nDivision
            new_j = j +nAdded;
            while ref_count<=nB && b(ref_count,2)<c{i}(new_j,1) 
                ref_count = ref_count+1;
            end
            if ref_count>nB
                break;
            end
            
            %if ref_count<nB && c{i}(new_j+nAdded,1) == b(ref_count,2) && c{i}(new_j,2) == b(ref_count+1,1) %��� ���� ���
            if ref_count<nB && c{i}(new_j,1) == b(ref_count,2) && c{i}(new_j,2) == b(ref_count+1,1) %��� ���� ���
                mid = round((c{i}(new_j,1) + c{i}(new_j,2))/2);
                if c{i}(new_j,2) - c{i}(new_j,1)==1  %��� ���� ������ �ʺ� 1�� ��� ������ �ʴ´�
                    corresponding_ref_id{i}(new_j) = ref_count+1;
                    ref_count = ref_count+1;
                else                               %�׷��� ���� ��� ������ �����Ѵ�
                    c{i} = [c{i}(1:1:new_j-1,:);c{i}(new_j,1) mid;mid c{i}(j,2) ;c{i}(new_j+1:1:nDivision,:)];
                    corresponding_ref_id{i}(new_j+0) = ref_count;
                    corresponding_ref_id{i}(new_j+1) = ref_count+1;
                    nAdded = nAdded+1;
                    ref_count = ref_count+1;
                end

            elseif c{i}(new_j,2) == b(ref_count,1)
                corresponding_ref_id{i}(new_j) = ref_count;
            elseif c{i}(new_j,1) == b(ref_count,2)
                corresponding_ref_id{i}(new_j) = ref_count;
                ref_count = ref_count+1;
            end
        end
    end
    
    % percent�������� ��ȯ�Ѵ�. time ��������
    nC = size(c,1);
    for i=1:nC
        nDivision = size(c{i},1);
        c{i}(:,3:4) = c{i}(:,1:2);
        for j=1: nDivision
            len = (c{i}(j,2) - c{i}(j,1)) ./ SamplingRates;
            if bFullFP(i) ==0
                c{i}(j,:) = [0, len, c{i}(j,1), c{i}(j,2)];
            else  %���� �������� �ʴ� ���� Inf�� ����� �д�
                c{i}(j,:) = [Inf, Inf, c{i}(j,1), c{i}(j,2)];
            end
        end
    end
    
end

%     1: second�� Normalize
function c = SubtractRanges4NormalizedError_inSeconds(a,b,samplingRates)
    nA = size(a,1);
    nB = size(b,1);

    %range�� �켱 �� ����.
    c = cell(nA,1);
    for i=1:nA
        c{i} = a(i,:);
        for j=1:nB
            if  b(j,2)>a(i,1) && b(j,1)<a(i,2)
                c{i} = Subtract_aRange_fromRanges(c{i},b(j,:));
            end
        end
        
        % A-B�� �ϸ鼭, B�� ref�� ���� ��쿡, ���� �������� �ʴ� �κ��� �����.
        % percent �������� ��ȯ�� �� ���� �����̴�.
        if bUseB_asRef ==1 && size(c{i},1) ==size(a(i,:),1) && isequal(c{i}, a(i,:))
            c(i) = [];
        end
    end
    
    % percent�������� ��ȯ�Ѵ�
    for i=1:nA
        nDivision = size(c{i},1);
        if bUseB_asRef ==0
            c{i} = c{i} - center_id_a(i);
            width_Left = center_id_a(i) - a(i,1);
            width_Right = a(i,2)- center_id_a(i);
        else
            c{i} = c{i} - center_id_b(i);
            width_Left = center_id_b(i) - b(i,1);
            width_Right = b(i,2)- center_id_b(i);
        end
        for j=1: nDivision
            for k = 1:2
                if c{i}(j,k)<0
                    c{i}(j,k) = c{i}(j,k) ./ width_Left;
                else
                    c{i}(j,k) = c{i}(j,k) ./ width_Right;
                end
            end
        end
    end
    
end

%a�� width�� ���� ������ Normalize
function c = SubtractRanges4NormalizedError(a,b)
    nA = size(a,1);
    nB = size(b,1);
    
    width_a = a(:,2) - a(:,1);

    %range�� �켱 �� ����.
    c = cell(nA,1);
    for i=1:nA
        c{i} = a(i,:);
        for j=1:nB
            if  b(j,2)>a(i,1) && b(j,1)<a(i,2)
                c{i} = Subtract_aRange_fromRanges(c{i},b(j,:));
            end
        end
    end
    
    % percent�������� ��ȯ�Ѵ�
    for i=1:nA
        nDivision = size(c{i},1);
        width_c = c{i}(:,2) - c{i}(:,1);
        c{i} = width_c ./width_a(i);
    end
end

% c = a - b
% c = [range_start rane_end  ]
% function c = SubtractRanges4NormalizedError(a,b,center_id_a)
%     nA = size(a,1);
%     nB = size(b,1);
% 
%     %range�� �켱 �� ����.
%     c = cell(nA,1);
%     for i=1:nA
%         c{i} = a(i,:);
%         for j=1:nB
%             if  b(j,2)>a(i,1) && b(j,1)<a(i,2)
%                 c{i} = Subtract_aRange_fromRanges(c{i},b(j,:));
%             end
%         end
%     end
%     
%     % percent�������� ��ȯ�Ѵ�
%     for i=1:nA
%         nDivision = size(c{i},1);
%         c{i} = c{i} - center_id_a(i);
%         width_Left = center_id_a(i) - a(i,1);
%         width_Right = a(i,2)- center_id_a(i);
%         for j=1: nDivision
%             for k = 1:2
%                 if c{i}(j,k)<0
%                     c{i}(j,k) = c{i}(j,k) ./ width_Left;
%                 else
%                     c{i}(j,k) = c{i}(j,k) ./ width_Right;
%                 end
%             end
%         end
%     end
%     
% end








function [amb_range, concrete_range] = seperateAmbiguousRange(range_groundTruth,amb_col_id)
    amb_range_counter = 0;
    concrete_range_counter = 0;
    nGTRange = size(range_groundTruth,1);
    dim = 2;
    amb_range = zeros(nGTRange,dim);
    concrete_range= zeros(nGTRange,dim);
    
    for i=1:nGTRange
        if range_groundTruth(i,amb_col_id) ==1
            amb_range_counter = amb_range_counter+1;
            amb_range(amb_range_counter,:) = range_groundTruth(i,1:dim);
        else
            concrete_range_counter = concrete_range_counter+1;
            concrete_range(concrete_range_counter,:) = range_groundTruth(i,1:dim);
        end
    end
    amb_range(amb_range_counter+1:1:nGTRange,:) = [];
    concrete_range(concrete_range_counter+1:1:nGTRange,:) = [];
end


%     nFP = 0;
%     nFN = 0;
% FP_range = zeros(nTest,2);
%     FN_range = zeros(nRef,2);
%     FP_range_counter = 0;
%     FN_range_counter = 0;
%     
%     bRefRangeLeft = 0;
%     bTestRangeLeft = 0;
%     count_test = 1;
%     count_ref = 1;
%     while count_test<=nTest && count_ref<=nRef
%         if bRefRangeLeft==1 %������ ref�� �ִٸ�
%             refRange_toCheck = refRangeLeft;
%         else    
%             refRange_toCheck = range_groundTruth(count_ref,:);
%         end
%         if bTestRangeLeft==1 %������ test�� �ִٸ�
%             testRange_toCheck = testRangeLeft;
%         else    
%             testRange_toCheck = range_test(count_test,:);
%         end
%         
%         %Test Range�� �������� Ref ���� �տ� �ִ� ���
%         if testRange_toCheck(1)< refRange_toCheck(1)
%             
%             %Test Range�� ������ Ref�� ���������� �տ� �ִ� ���
%             %Test Range�� ������ �տ� �ִ� ���, test range �� �״�� Fals Positive�� �ȴ�.
%             if testRange_toCheck(2)<=refRange_toCheck(1)
%                 FP_range_counter = FP_range_counter+1;
%                 FP_range(FP_range_counter,:) = testRange_toCheck(:);
%                 count_test = count_test+1;
%                 
%             %Test Range�� ������ Ref�� ���ԵǾ� �ִ� ���
%             elseif testRange_toCheck(2)<=refRange_toCheck(2)
%                 
%                 %FP �߰�
%                 FP_range_counter = FP_range_counter+1;
%                 FP_range(FP_range_counter,:) = [testRange_toCheck(1) refRange_toCheck(1)] ;
%                 count_test = count_test+1;
%                 
%                 %FN�� ���� Test Range�� üũ�ϱ� �������� ��Ȯ�� �� �� ����. ������ �κ��� ��ŷ�� ���� �Ѿ��
%                 bRefRangeLeft = 1;
%                 refRangeLeft = [testRange_toCheck(2) refRange_toCheck(2)] ;
%                
%             %Test Range�� ������ Ref�� �������� �ڿ� �ִ� ���, �� Test�� Ref�� �����ϴ� ���
%             else
%             end
%                 
%             
%         %Test Range�� �������� Ref �� ���ԵǴ� ���
%         elseif test_ranges(count_test,1)>= range_groundTruth(count_ref,1) && test_ranges(count_test,1)<range_groundTruth(count_ref,2)
%             
%         %Test Range�� �������� Ref ���� �ڿ� �ִ� ���
%         %Test Range�� ������ �ڿ� �ִ� ���, ref range �� �״�� Fals Negative �ȴ�.
%         else
%             FN_range_counter = FN_range_counter+1;
%             FN_range(FN_range_counter,:) = range_groundTruth(count_ref,:);
%             count_ref = count_ref+1;
%         end
%     end
%     nFP = nFP + (nTest - count_test+1);
%     nFN = nFN + (nRef - count_ref+1);
%     
%     
%     
%     
%     peakids_GTAmbiguous = zeros(nGT,1);
%     count_GTAmbiguous=0;
%     for i=1:nGT
%         if range_groundTruth(i,3)==1
%             count_GTAmbiguous = count_GTAmbiguous+1;
%             peakids_GTAmbiguous(count_GTAmbiguous,:) = peakids_GT(i,:);
%         end
%     end
%     peakids_GTAmbiguous(count_GTAmbiguous+1:1:nGT,:) = [];
%     [nFP_amb, nFN_amb, nAmb] = isFullMatch_Points2Ranges(range_test,peakids_GTAmbiguous);
%     
%     nFN = nFN-nFN_amb;
%     nGT = nGT-nAmb;
%     nTP = nGT-nFN;
% end


    %[peakvalues_test, peakids_test] = getExtremePointInRanges( data(:,channel_id), range_test, 1 );
    %[nFP, nFN, nEyeblink] = isFullMatch_Points2Points(peakids_test,peakids_GT);

