function rawData = MatScanEnd()
%%  데이터 획득 중단

% 데이터 획득 중단을 기기에 명령 내림. 
retv = calllib('LXSMD1WD8','Stop_Stream');

%명령어의 정상 작동 유무 검사
if retv == 0
%     msgbox('데이터 획득 중단');
elseif retv == -1
    msgbox('장치가 초기화되지 않았습니다.', ' ', 'error');
elseif retv == -3
    msgbox('장치로 스트림 데이터 전송 중지 명령이 보내지지 않았습니다.','','error');
end   

%% 장치 사용 중단. 

% pc와 EEG 장비간의 연결을 끊는 명령을 기기에 내림.
retv = calllib('LXSMD1WD8','Close_Device');

% 명령어의 정상 작동 유무 검사
if retv == 1
    msgbox('PC와 EEG장비와의 연결을 끊었습니다.');
elseif retv == -1
    msgbox('장치가 초기화되지 않았습니다.', ' ', 'error');
elseif retv == -3
   msgbox('장치로 스트림 데이터 전송 중지 명령이 보내지지 않았습니다.','','error');
end
%%
unloadlibrary LXSMD1WD8;