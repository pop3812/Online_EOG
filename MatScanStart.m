function rawData = MatScanStart(chNum, SR, gain)
%%  라이브러리 등록 

[notfound,warnings] = loadlibrary('LXSMD1WD8', 'LXSMD1WD8.h');

% 명령어의 정상 작동 유무 검사
if libisloaded('LXSMD1WD8') 
%     msgbox('라이브러리 정상 등록!');
else
    msgbox('라이브러리 등록 실패!', '', 'error');
end

%% 장치 초기화 

hwnd = 5;
% 장치 초기화
[retv init]=calllib('LXSMD1WD8','Init_Device', hwnd, 5);

% 명령어의 정상 작동 유무 검사
if retv==-1 
    msgbox('PC에 장착된 장치를 발견하지 못함', '', 'error');
elseif retv ==-2 
    msgbox('초기화 중복 호촐.', '', 'warn');
elseif retv ==-3
    msgbox('장치의 명령전달에 오류', '', 'error');
else 
%     msgbox('장치 초기화 성공');
end

%% 데이터를 받을 변수 초기화

% 데이터를 받는 변수 지정

global rawData;
rawData = calllib('LXSMD1WD8', 'Get_StreamMemoryFP');
setdatatype(rawData, 'singlePtr', 512,1);

%% 5. 윈도우 메시지 대신 키보드이 '+' event를 받도록 설정하는 파트 

retv = calllib('LXSMD1WD8','Set_MessageMode',1);

%명령어의 정상 작동 유무 검사
if retv == 1
%     msgbox('Set_MessageMode 정상 실행');
end

%%  사용할 채널 수 설정 

% 설정한 채널에 맞게 기기에 명령을 내림.
retv = calllib('LXSMD1WD8','Set_ADCMaxNumChannel',chNum);

%명령어의 정상 작동 유무 검사
if retv == -1 
    msgbox('init_device가 호출되기전에 ADC가 호출되었습니다.', '' , 'error');
elseif retv ==-2 
    msgbox('이미 이 함수는 호출되었습니다.','','warning');
elseif retv ==-3
    msgbox('장치로 명령 전달을 실패하였습니다.', '', 'error');    
elseif retv ==-10
    msgbox('채널수는 2^n형태로 설정가능합니다. ', '', 'error');
else 
%     sucMess = sprintf('Chennel : %d 개', chNum);
%     msgbox(sucMess);
end

%% Sampling Rate 설정 

% 설정한 주파수에 맞게 기기에 명령을 내림.
retv = calllib('LXSMD1WD8','Set_SampleFreq',SR);

% 명령어의 정상 작동 유무 검사
if retv == 1
%     sucMess = sprintf('Sampling Rate : %d Hz', 2^SR);
%     msgbox(sucMess);
elseif retv == -1 
    msgbox('init_device함수 (장치초기화) 부터 호출하십시오.', '', 'error');
elseif retv == -3 
    msgbox('장치로 명령전달이 실패하였습니다.', '' , 'error');
elseif retv == -4
    msgbox('지원되지 않는 샘플링 주파수를 설정하였습니다.','','error');    
elseif retv == -10
    msgbox('인자로 전달된 값의 범위가 맞지 않습니다.', ' ','error');
end

%% 8. 게인값 조정    

% 설정한 게인값에 맞게 기기에 명령을 내림.
retv = calllib('LXSMD1WD8','Set_PGA',gain);

% 명령어의 정상 작동 유무 검사
if retv == 1
%     sucMess = sprintf('gain : %d', gain);
%     msgbox(sucMess);    
elseif retv == -1 
    msgbox('init_device함수 (장치초기화) 부터 호출하십시오.', ' ' , 'error');
elseif retv == -3 
    msgbox('장치로 명령전달이 실패하였습니다.', ' ', 'error');   
elseif retv == -10
    msgbox('인자로 전달된 값의 범위가 맞지 않습니다.', ' ', 'error');
end

%% 9. 데이터 획득 시작

% 데이터 획득 시작을 기기에 명령 내림. 
retv = calllib('LXSMD1WD8','Start_Stream');

% 명령어의 정상 작동 유무 검사
if retv == 1
%     msgbox('데이터 획득 시작');
elseif retv == -1
    msgbox('init_device함수 (장치초기화) 부터 호출하십시오.', '', 'error');
elseif retv == -2
    msgbox('이미 데이터 획득 중입니다.', '', 'error');
elseif retv == -3
    msgbox('장치로 스트림 데이터 전송명령이 전달되지 못하였습니다.','', 'error');
elseif retv == -4
    msgbox('지원되지 않는샘플링 주파수로 데이터 수집 시도하였습니다.', ' ', 'error');
end


