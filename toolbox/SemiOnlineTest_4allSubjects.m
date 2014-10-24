function [ range_Total, nFP, nFN, nGT ] = SemiOnlineTest_4allSubjects(type, part )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    global samplingFrequency2Use;
    samplingFrequency2Use = 64;
    if type ==0
        [ range_Total, nFP, nFN, nGT ] = vTest(part);
    elseif type ==1
        [ range_Total, nFP, nFN, nGT ] = TimeTest(part);
    else
        [ range_Total, nFP, nFN, nGT ] = AlphaTest();
    end
end

function [ range_Total, nFP, nFN, nGT ] = vTest(part)
    global samplingFrequency2Use;
    nSubject = 24;
    nTotalSec_2watch = 300;
    nSec_4Division = 5;
    nBin = nTotalSec_2watch/nSec_4Division;
    range_Total = cell(nSubject,nSubject);
    
    pos_firstpeak = findFirstPeak(  );
    
    
    if part ==0
        v = 0.01:0.01:0.05;
    elseif part ==1
        v = 0.06:0.01:0.1;
    elseif part ==2
        v = 0.2:0.1:1.0;
    end
    
    
    nOption = size(v,2);
    
    nFP = cell(nOption,1);
    nFN = cell(nOption,1);
    
    nGT = zeros(nSubject,nBin);
    
    alpha = 0;
    InitTime_4Histogram_inSec = 5;

   for j= 1:nOption
        nFP{j} = zeros(nSubject,nBin);
        nFN{j} = zeros(nSubject,nBin);
        range_Total{j} = zeros(nSubject,nBin);
        for i=1:24
            fprintf('%d\n',i);
            init_time = InitTime_4Histogram_inSec + pos_firstpeak(i)/samplingFrequency2Use + 0.3;
            [range_Total{j,i}, nFP{j}(i,:), nFN{j}(i,:), nGT(i,:)] = SemiOnlineTest(i,nTotalSec_2watch, nSec_4Division, alpha,init_time, v(j));
        end
        save(['Time5_alpha0_vnew' num2str(part) '.mat']);
    end
end

function [ range_Total, nFP, nFN, nGT ] = TimeTest(part)
    global samplingFrequency2Use;
    nSubject = 24;
    nTotalSec_2watch = 300;
    nSec_4Division = 5;
    nBin = nTotalSec_2watch/nSec_4Division;
    range_Total = cell(nSubject,nSubject);
    
    pos_firstpeak = findFirstPeak(  );
    
    alpha = 0;
    if part ==0
        InitTime_4Histogram_inSec = [0:5,10:5:60];
    else
        InitTime_4Histogram_inSec = [0:5,10:5:60];
    end

    nTime = size(InitTime_4Histogram_inSec,2);
    
    nFP = cell(nTime,1);
    nFN = cell(nTime,1);
    
    nGT = zeros(nSubject,nBin);
    
    v = 0.1;

   for j= 1:nTime
        nFP{j} = zeros(nSubject,nBin);
        nFN{j} = zeros(nSubject,nBin);
        range_Total{j} = zeros(nSubject,nBin);
        for i=1:24
            fprintf('%d\n',i);
            init_time = InitTime_4Histogram_inSec(j) + pos_firstpeak(i)/samplingFrequency2Use + 0.3;
            [range_Total{j,i}, nFP{j}(i,:), nFN{j}(i,:), nGT(i,:)] = SemiOnlineTest(i,nTotalSec_2watch, nSec_4Division, alpha,init_time, v);
        end
        save(['TimeChange_v1.0_alpha0' num2str(part) '.mat']);
    end
end

function [ range_Total, nFP, nFN, nGT ] = AlphaTest()
    global samplingFrequency2Use;
    samplingFrequency2Use = 64;
    
    pos_firstpeak = findFirstPeak(  );
    nSubject = 24;
    nTotalSec_2watch = 300;
    nSec_4Division = 5;
    nBin = nTotalSec_2watch/nSec_4Division;
    range_Total = cell(nSubject,1);
    
    InitTime_4Histogram_inSec = pos_firstpeak/samplingFrequency2Use + 5.3;
    alpha = -1:0.2:3;
    nAlpha = size(alpha,2);
    v = 0.1;
    
    nFP = cell(nAlpha,1);
    nFN = cell(nAlpha,1);
    
    nGT = zeros(nSubject,nBin);
    
    for j=1:nAlpha
        nFP{j} = zeros(nSubject,nBin);
        nFN{j} = zeros(nSubject,nBin);
        fprintf('%d\n',j);
        for i=1:24
            fprintf('%d ',i);
            [range_Total{j,i}, nFP{j}(i,:), nFN{j}(i,:), nGT(i,:)] = SemiOnlineTest(i,nTotalSec_2watch, nSec_4Division, alpha(j),InitTime_4Histogram_inSec(i),v);
        end
        fprintf('\n');
        save('AlphaChange_v1.0_time5.mat');
    end
end

function [ pos ] = findFirstPeak(  )
%FINDFIRSTPEAK Summary of this function goes here
%   Detailed explanation goes here

    global samplingFrequency2Use;
    
    nFile = 24;
    subject_id_start =1;
    
    folder_GT = 'D:/_Project/Data/LGData_Txt/Session1_GroundTruth';
    filepaths_GT = load_files_in_folder(folder_GT,'*.range');
    
    pos  = zeros(nFile,1);
    
    % Load data & Preprocessing
    range_groundtruth= cell(nFile,1);
    samplingFrequency2Use = 64;
    for i = subject_id_start:nFile
        range_groundtruth{i} = load(filepaths_GT{i});
        nRange = size(range_groundtruth{i},1);
        for j=1:nRange
            if range_groundtruth{i}(j,4)==0
                pos(i) = range_groundtruth{i}(j,3);
                break;
            end
        end
    end
    

end



