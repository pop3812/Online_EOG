function [ range_Total, nFP, nFN, nGT ] = SemiOnlineTest_4allSubjects_time( )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    nSubject = 24;
    nTotalSec_2watch = 300;
    nSec_4Division = 5;
    nBin = nTotalSec_2watch/nSec_4Division;
    range_Total = cell(nSubject,1);
    
    alpha = 0;
    InitTime_4Histogram_inSec = 1:4;
    nTime = size(InitTime_4Histogram_inSec,2);
    
    nFP = cell(nTime,1);
    nFN = cell(nTime,1);
    
    nGT = zeros(nSubject,nBin);
    
    for j=1:nTime
        nFP{j} = zeros(nSubject,nBin);
        nFN{j} = zeros(nSubject,nBin);
        for i=1:24
            fprintf('%d\n',i);
            [range_Total{i}, nFP{j}(i,:), nFN{j}(i,:), nGT(i,:)] = SemiOnlineTest(i,nTotalSec_2watch, nSec_4Division, alpha,InitTime_4Histogram_inSec(j));
        end
        save('Time_1to4by1.mat');
    end
end

function [ range_Total, nFP, nFN, nGT ] = AlphaTest()
    nSubject = 24;
    nTotalSec_2watch = 300;
    nSec_4Division = 5;
    nBin = nTotalSec_2watch/nSec_4Division;
    range_Total = cell(nSubject,1);
    
    alpha = -1:0.2:3;
    nAlpha = size(alpha,2);
    
    nFP = cell(nAlpha,1);
    nFN = cell(nAlpha,1);
    
    nGT = zeros(nSubject,nBin);
    
    for j=1:nAlpha
        nFP{j} = zeros(nSubject,nBin);
        nFN{j} = zeros(nSubject,nBin);
        for i=1:24
            fprintf('%d\n',i);
            [range_Total{i}, nFP{j}(i,:), nFN{j}(i,:), nGT(i,:)] = SemiOnlineTest(i,nTotalSec_2watch, nSec_4Division, alpha(j),InitTime_4Histogram_inSec);
        end
        break;
        save('Alpha.mat');
    end
end

