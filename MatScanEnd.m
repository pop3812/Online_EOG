function rawData = MatScanEnd()
%%  ������ ȹ�� �ߴ�

% ������ ȹ�� �ߴ��� ��⿡ ��� ����. 
retv = calllib('LXSMD1WD8','Stop_Stream');

%��ɾ��� ���� �۵� ���� �˻�
if retv == 0
%     msgbox('������ ȹ�� �ߴ�');
elseif retv == -1
    msgbox('��ġ�� �ʱ�ȭ���� �ʾҽ��ϴ�.', ' ', 'error');
elseif retv == -3
    msgbox('��ġ�� ��Ʈ�� ������ ���� ���� ����� �������� �ʾҽ��ϴ�.','','error');
end   

%% ��ġ ��� �ߴ�. 

% pc�� EEG ����� ������ ���� ����� ��⿡ ����.
retv = calllib('LXSMD1WD8','Close_Device');

% ��ɾ��� ���� �۵� ���� �˻�
if retv == 1
    msgbox('PC�� EEG������ ������ �������ϴ�.');
elseif retv == -1
    msgbox('��ġ�� �ʱ�ȭ���� �ʾҽ��ϴ�.', ' ', 'error');
elseif retv == -3
   msgbox('��ġ�� ��Ʈ�� ������ ���� ���� ����� �������� �ʾҽ��ϴ�.','','error');
end
%%
unloadlibrary LXSMD1WD8;