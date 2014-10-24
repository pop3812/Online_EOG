function rawData = MatScanStart(chNum, SR, gain)
%%  ���̺귯�� ��� 

[notfound,warnings] = loadlibrary('LXSMD1WD8', 'LXSMD1WD8.h');

% ��ɾ��� ���� �۵� ���� �˻�
if libisloaded('LXSMD1WD8') 
%     msgbox('���̺귯�� ���� ���!');
else
    msgbox('���̺귯�� ��� ����!', '', 'error');
end

%% ��ġ �ʱ�ȭ 

hwnd = 5;
% ��ġ �ʱ�ȭ
[retv init]=calllib('LXSMD1WD8','Init_Device', hwnd, 5);

% ��ɾ��� ���� �۵� ���� �˻�
if retv==-1 
    msgbox('PC�� ������ ��ġ�� �߰����� ����', '', 'error');
elseif retv ==-2 
    msgbox('�ʱ�ȭ �ߺ� ȣ��.', '', 'warn');
elseif retv ==-3
    msgbox('��ġ�� ������޿� ����', '', 'error');
else 
%     msgbox('��ġ �ʱ�ȭ ����');
end

%% �����͸� ���� ���� �ʱ�ȭ

% �����͸� �޴� ���� ����

global rawData;
rawData = calllib('LXSMD1WD8', 'Get_StreamMemoryFP');
setdatatype(rawData, 'singlePtr', 512,1);

%% 5. ������ �޽��� ��� Ű������ '+' event�� �޵��� �����ϴ� ��Ʈ 

retv = calllib('LXSMD1WD8','Set_MessageMode',1);

%��ɾ��� ���� �۵� ���� �˻�
if retv == 1
%     msgbox('Set_MessageMode ���� ����');
end

%%  ����� ä�� �� ���� 

% ������ ä�ο� �°� ��⿡ ����� ����.
retv = calllib('LXSMD1WD8','Set_ADCMaxNumChannel',chNum);

%��ɾ��� ���� �۵� ���� �˻�
if retv == -1 
    msgbox('init_device�� ȣ��Ǳ����� ADC�� ȣ��Ǿ����ϴ�.', '' , 'error');
elseif retv ==-2 
    msgbox('�̹� �� �Լ��� ȣ��Ǿ����ϴ�.','','warning');
elseif retv ==-3
    msgbox('��ġ�� ��� ������ �����Ͽ����ϴ�.', '', 'error');    
elseif retv ==-10
    msgbox('ä�μ��� 2^n���·� ���������մϴ�. ', '', 'error');
else 
%     sucMess = sprintf('Chennel : %d ��', chNum);
%     msgbox(sucMess);
end

%% Sampling Rate ���� 

% ������ ���ļ��� �°� ��⿡ ����� ����.
retv = calllib('LXSMD1WD8','Set_SampleFreq',SR);

% ��ɾ��� ���� �۵� ���� �˻�
if retv == 1
%     sucMess = sprintf('Sampling Rate : %d Hz', 2^SR);
%     msgbox(sucMess);
elseif retv == -1 
    msgbox('init_device�Լ� (��ġ�ʱ�ȭ) ���� ȣ���Ͻʽÿ�.', '', 'error');
elseif retv == -3 
    msgbox('��ġ�� ��������� �����Ͽ����ϴ�.', '' , 'error');
elseif retv == -4
    msgbox('�������� �ʴ� ���ø� ���ļ��� �����Ͽ����ϴ�.','','error');    
elseif retv == -10
    msgbox('���ڷ� ���޵� ���� ������ ���� �ʽ��ϴ�.', ' ','error');
end

%% 8. ���ΰ� ����    

% ������ ���ΰ��� �°� ��⿡ ����� ����.
retv = calllib('LXSMD1WD8','Set_PGA',gain);

% ��ɾ��� ���� �۵� ���� �˻�
if retv == 1
%     sucMess = sprintf('gain : %d', gain);
%     msgbox(sucMess);    
elseif retv == -1 
    msgbox('init_device�Լ� (��ġ�ʱ�ȭ) ���� ȣ���Ͻʽÿ�.', ' ' , 'error');
elseif retv == -3 
    msgbox('��ġ�� ��������� �����Ͽ����ϴ�.', ' ', 'error');   
elseif retv == -10
    msgbox('���ڷ� ���޵� ���� ������ ���� �ʽ��ϴ�.', ' ', 'error');
end

%% 9. ������ ȹ�� ����

% ������ ȹ�� ������ ��⿡ ��� ����. 
retv = calllib('LXSMD1WD8','Start_Stream');

% ��ɾ��� ���� �۵� ���� �˻�
if retv == 1
%     msgbox('������ ȹ�� ����');
elseif retv == -1
    msgbox('init_device�Լ� (��ġ�ʱ�ȭ) ���� ȣ���Ͻʽÿ�.', '', 'error');
elseif retv == -2
    msgbox('�̹� ������ ȹ�� ���Դϴ�.', '', 'error');
elseif retv == -3
    msgbox('��ġ�� ��Ʈ�� ������ ���۸���� ���޵��� ���Ͽ����ϴ�.','', 'error');
elseif retv == -4
    msgbox('�������� �ʴ»��ø� ���ļ��� ������ ���� �õ��Ͽ����ϴ�.', ' ', 'error');
end


