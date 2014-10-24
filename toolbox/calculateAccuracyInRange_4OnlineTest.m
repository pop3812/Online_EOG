% ---------------------------------------------------------------------
%   - calculateAccuracy-
%  accuracy Calculation (FPR, TPR)
% calculateAccuracyInRange_usingRank 함수와 유사하지만, MSDW 용으로 최적화되었다.
% 왜냐하면 MSDW 가 range의 ranking을 매기는 데에 적합하지 않기 때문이다.
% 여기서 range_according2rank 는 eogdetection_RangeRanking_MSDW 함수를 통해서 계산된 값으로
% threshold 에 따라 검출된 range의 리스트를 각 셀에 포함하고 있다.
%----------------------------------------------------------------------
% by Won-Du Chang, ph.D, 
% Post-Doc @  Department of Biomedical Engineering, Hanyang University
% contact: 12cross@gmail.com
%---------------------------------------------------------------------
function [nFP, nFN, nGT,totalTime_Negative] = calculateAccuracyInRange_4OnlineTest(range_groundTruth, range_detected)

    range_groundTruth = sortrows(range_groundTruth);
    amb_col_id = 4;

%%FN계산--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    %seperate ambiguous ranges from GT ranges
    [amb_range,concrete_range_ref] = seperateAmbiguousRange(range_groundTruth, amb_col_id);
    concrete_range_ref = sortrows(concrete_range_ref);

    %FN range calculation
    [nMissedRanges, nMissedPoints, nPoints, list_MissedRangeid, list_MissedPointid] = isFullMatch_Points2Ranges(range_detected, concrete_range_ref(:,3));
    
    nFN = nMissedPoints;
    list_FN = range_groundTruth(list_MissedRangeid,3); % FN range 의 peak point
    
    FN_range = SubtractRanges4NormalizedError(concrete_range_ref,range_detected);

    nGT  = size(concrete_range_ref,1);
    nFN = zeros(nThreshold, nDivision);
    nFN(:,nDivision) = NaN;
    nDelta_Positive = 0.5/(nDivision-1);  %ratio
    for i=1:nDivision-1  % 각각의 error tolerance에 대해
        target_threshold_positive = nDelta_Positive*(i-1); 
        for j=1:nThreshold %각각의 검출된 range들에 대해 FN을 count 한다.
            if j==101 &&i==3
                eee=3;
            end
            for k=1:nGT         %각각의 Ground Truth에 대해 FN 여부를 체크하고 맞으면 count를 증가시킨다.
                nItem = size(FN_range{j}{k},1);
                cnt = 0;
                for m = 1:nItem  %좌우 FN중 하나만 tolerance를 넘겨도 카운트한다.
                    if FN_range{j}{k}(m,1)>target_threshold_positive
                        cnt = 1;
                    end
                end
                nFN(j,i) = nFN(j,i) +cnt;
            end
        end
    end

   
    
    
    
%%FP계산--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    %find matching reference_id for each test range
    %correspondingRefID_ofTestRange = FindCorrespondingRefID(range_test, concrete_range_ref);
    %각각의 test range에 대해 대응하는 peak 지점을 
    
    %peakids = peakids_ref(correspondingRefID_ofTestRange,1);
    fprintf('start removing ambiguous positivie from test data..\n');
    
    
    

    range_test = cell(nThreshold,1);
    for p=1:nThreshold
        %range를 시간순으로 정렬
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
            else % 겹치는 경우
                bAmbiguousFound = range_groundTruth(ref_cnt,amb_col_id);
                bAllAmbigous = bAmbiguousFound;
                ref_end_id = ref_cnt;
                while ref_end_id+1<=nRef && range_groundTruth(ref_end_id+1,1)<range_test{p}(test_cnt,2) %하나의 test가 여러개의 ref 와 겹치는 경우를 체크
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

                if bAmbiguousFound==0   %ambiguous 하지 않은 경우에는 skip 하고 지나간다
                    test_cnt = test_cnt+1;
                    ref_cnt= ref_end_id+1;
                elseif ref_end_id==ref_cnt || bAllAmbigous==1 %ambigous하지만 1:1 매칭되는 경우 또는 모두 ambigous하는 경우에는 test만을 지운다
    %                 range_test(test_cnt,:) = [];
    %                 nTest = nTest -1;%하나를 지웠으므로 test_cnt 는 증가시키지 않는다
                    range_test{p}(test_cnt,1:2) =  [0 0]; % 지우지 않고 [0 0] array로 만든다.
                    test_cnt = test_cnt+1; 
                else   %ambigous하면서 하나의 test가 여러개의 ref와 매칭되며, 매칭되는 ref들이 amb 와 concrete가 섞여 있는 경우
                    range2delete = zeros(1,2);
                    delete_cnt = 0;
                    for i=ref_cnt:1:ref_end_id-1
                        if range_groundTruth(ref_cnt,amb_col_id)==0 &&range_groundTruth(ref_cnt+1,amb_col_id)==0 %연속되는 두 ref_range 가 모두 ambi가 아닌 경우.
                            %do nothing
                        elseif range_groundTruth(ref_cnt,amb_col_id)==1 &&range_groundTruth(ref_cnt+1,amb_col_id)==1 %연속되는 두 ref_range 가 모두 ambi인 경우.
                            if i==ref_end_id-1    %뒤의 range가 마지막 range인 경우 뒤의 것도 지운다
                                range2delete(delete_cnt+1,2) = range_test{p}(test_cnt,2);
                                delete_cnt = delete_cnt+1;
                            else %마지막이 아닌 경우 skip하고다음 것을 보도록 한다
                            end
                        elseif range_groundTruth(ref_cnt,amb_col_id)==0 &&range_groundTruth(ref_cnt+1,amb_col_id)==1
                            range2delete(delete_cnt+1,1) = round((range_groundTruth(ref_cnt,2) + range_groundTruth(ref_cnt+1,1))/2);
                            if i==ref_end_id-1    %뒤의 range가 마지막 range인 경우
                                range2delete(delete_cnt+1,2) = range_test{p}(test_cnt,2);
                                delete_cnt = delete_cnt+1;
                            end
                        else
                            if i==ref_cnt %맨 처음인 경우
                                range2delete(delete_cnt+1,1) = range_test{p}(test_cnt,1);
                            end
                            range2delete(delete_cnt+1,2) = round((range_groundTruth(ref_cnt,2) + range_groundTruth(ref_cnt+1,1))/2);
                            delete_cnt = delete_cnt+1;
                        end
                    end

                    %지우기

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
    
    for i=1:nDivision  % 각각의 error tolerance에 대해
        target_threshold_negative = nDelta_Negative*(i-1); 
        for j=1:nThreshold %각각의 threshold에 대해 FP를 count 한다.
             nFPRange = size(FP_range{j},1);
             FP_Range_Integrated = ones(nFPRange,2)*Inf;
             nRangeIntegrated = 0;
                
            for k = 1: nFPRange %각각의 FP Range에 대해 FP 여부를 체크하고 맞으면 count를 증가시킨다.
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
%     %FNR, FPR 계산
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
%     %test range의 peak 가 ref에 포함되지 않은 경우에 삭제한다 (포함되어 있지 않은 경우에는 일반적인 에러계산으로 에러율 나옴)
%     [peakvalues_test, peakids_test] = getExtremePointInRanges( data, range_test, 1 );                                                               %nonAmbiguous Test set 의 peak id 계산
%     [a, b, c, list_refid_notMatched2TestPoint, list_testid_notInConcreteRefRange] = isFullMatch_Points2Ranges(concrete_range_ref, peakids_test);    %concrete ref range 와 nonAmbiguous Test peak 간의 full match test
%     range_test = range_test(setdiff(1:1:nTest,list_testid_notInConcreteRefRange),:);                                                                %test range 중 concrete range에 포함되지 않은 것은 제외
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

    %range를 우선 다 뺀다.
    c = cell(nA,1);
    bFullFP = zeros(nA,1); %전혀 겹쳐지지 않는 경우는 따로 카운트한다.
    for i=1:nA
        c{i} = [a(i,:)];
        for j=1:nB
            if  b(j,2)>a(i,1) && b(j,1)<a(i,2)
                c{i} = Subtract_aRange_fromRanges(c{i},b(j,:));
            end
        end
        % A-B를 하면서, B를 ref로 쓰는 경우에, 전혀 겹쳐지지 않는 부분은 지운다.
        if size(c{i},1) ==size(a(i,:),1) && isequal(c{i}, a(i,:))
            bFullFP(i) = 1;
        end
    end
    
    %각각의 C에 대해서 corresponding reference id를 찾는다
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
            
            %if ref_count<nB && c{i}(new_j+nAdded,1) == b(ref_count,2) && c{i}(new_j,2) == b(ref_count+1,1) %가운데 끼인 경우
            if ref_count<nB && c{i}(new_j,1) == b(ref_count,2) && c{i}(new_j,2) == b(ref_count+1,1) %가운데 끼인 경우
                mid = round((c{i}(new_j,1) + c{i}(new_j,2))/2);
                if c{i}(new_j,2) - c{i}(new_j,1)==1  %가운데 끼인 구간의 너비가 1인 경우 나누지 않는다
                    corresponding_ref_id{i}(new_j) = ref_count+1;
                    ref_count = ref_count+1;
                else                               %그렇지 않은 경우 나누어 저장한다
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
    
    % percent형식으로 전환한다. time 기준으로
    nC = size(c,1);
    for i=1:nC
        nDivision = size(c{i},1);
        c{i}(:,3:4) = c{i}(:,1:2);
        for j=1: nDivision
            len = (c{i}(j,2) - c{i}(j,1)) ./ SamplingRates;
            if bFullFP(i) ==0
                c{i}(j,:) = [0, len, c{i}(j,1), c{i}(j,2)];
            else  %전혀 겹쳐지지 않는 경우는 Inf로 계산해 둔다
                c{i}(j,:) = [Inf, Inf, c{i}(j,1), c{i}(j,2)];
            end
        end
    end
    
end

%     1: second로 Normalize
function c = SubtractRanges4NormalizedError_inSeconds(a,b,samplingRates)
    nA = size(a,1);
    nB = size(b,1);

    %range를 우선 다 뺀다.
    c = cell(nA,1);
    for i=1:nA
        c{i} = a(i,:);
        for j=1:nB
            if  b(j,2)>a(i,1) && b(j,1)<a(i,2)
                c{i} = Subtract_aRange_fromRanges(c{i},b(j,:));
            end
        end
        
        % A-B를 하면서, B를 ref로 쓰는 경우에, 전혀 겹쳐지지 않는 부분은 지운다.
        % percent 형식으로 전환할 수 없기 때문이다.
        if bUseB_asRef ==1 && size(c{i},1) ==size(a(i,:),1) && isequal(c{i}, a(i,:))
            c(i) = [];
        end
    end
    
    % percent형식으로 전환한다
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

%a의 width에 대한 비율로 Normalize
function c = SubtractRanges4NormalizedError(a,b)
    nA = size(a,1);
    nB = size(b,1);
    
    width_a = a(:,2) - a(:,1);

    %range를 우선 다 뺀다.
    c = cell(nA,1);
    for i=1:nA
        c{i} = a(i,:);
        for j=1:nB
            if  b(j,2)>a(i,1) && b(j,1)<a(i,2)
                c{i} = Subtract_aRange_fromRanges(c{i},b(j,:));
            end
        end
    end
    
    % percent형식으로 전환한다
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
%     %range를 우선 다 뺀다.
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
%     % percent형식으로 전환한다
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
%         if bRefRangeLeft==1 %남겨진 ref가 있다면
%             refRange_toCheck = refRangeLeft;
%         else    
%             refRange_toCheck = range_groundTruth(count_ref,:);
%         end
%         if bTestRangeLeft==1 %남겨진 test가 있다면
%             testRange_toCheck = testRangeLeft;
%         else    
%             testRange_toCheck = range_test(count_test,:);
%         end
%         
%         %Test Range의 시작점이 Ref 보다 앞에 있는 경우
%         if testRange_toCheck(1)< refRange_toCheck(1)
%             
%             %Test Range의 끝점이 Ref의 시작점보다 앞에 있는 경우
%             %Test Range가 완전히 앞에 있는 경우, test range 는 그대로 Fals Positive가 된다.
%             if testRange_toCheck(2)<=refRange_toCheck(1)
%                 FP_range_counter = FP_range_counter+1;
%                 FP_range(FP_range_counter,:) = testRange_toCheck(:);
%                 count_test = count_test+1;
%                 
%             %Test Range의 끝점이 Ref에 포함되어 있는 경우
%             elseif testRange_toCheck(2)<=refRange_toCheck(2)
%                 
%                 %FP 추가
%                 FP_range_counter = FP_range_counter+1;
%                 FP_range(FP_range_counter,:) = [testRange_toCheck(1) refRange_toCheck(1)] ;
%                 count_test = count_test+1;
%                 
%                 %FN은 다음 Test Range를 체크하기 전까지는 정확히 알 수 없다. 남겨진 부분을 마킹해 놓고 넘어간다
%                 bRefRangeLeft = 1;
%                 refRangeLeft = [testRange_toCheck(2) refRange_toCheck(2)] ;
%                
%             %Test Range의 끝점이 Ref의 끝점보다 뒤에 있는 경우, 즉 Test가 Ref를 포함하는 경우
%             else
%             end
%                 
%             
%         %Test Range의 시작점이 Ref 에 포함되는 경우
%         elseif test_ranges(count_test,1)>= range_groundTruth(count_ref,1) && test_ranges(count_test,1)<range_groundTruth(count_ref,2)
%             
%         %Test Range의 시작점이 Ref 보다 뒤에 있는 경우
%         %Test Range가 완전히 뒤에 있는 경우, ref range 는 그대로 Fals Negative 된다.
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

