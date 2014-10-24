// This header file must be included in main program to use "LXSM_D1WD8.DLL"
// DLL version 1.2 Released 2003-11-03
#define WM_AcqUnitData	WM_USER+1

extern "C" __declspec(dllimport) unsigned long Get_StreamMemory();			// ��Ʈ���޸�(�Ǽ����迭)�� �ּҸ� ��ȯ��.unsigned long Ÿ������ ��ȯ��.
extern "C" __declspec(dllimport) float * Get_StreamMemoryFP();			// ��Ʈ���޸�(�Ǽ����迭)�� �ּҸ� ��ȯ��. float* ������ ��ȯ��. 2010�� 9�� 20�� �߰���.
extern "C" __declspec(dllimport) short Init_Device(HWND msgtarget_window,int pid); // H/W��ġ �ʱ�ȭ, stream message���� ������ handle �� ��ġ�� ����ID����.
extern "C" __declspec(dllimport) short Close_Device();	
extern "C" __declspec(dllimport) short Start_Stream();					   // Stream ����. ���� Init_Device, �� �ѹ�.
extern "C" __declspec(dllimport) short Stop_Stream();					   // Stream ����. ���� Init_Device, Start_Stream.
extern "C" __declspec(dllimport) short Set_SampleFreq(unsigned char samplefreq_idx);   // ��ġ�� Sampling Frequency ����.
extern "C" __declspec(dllimport) short Set_PGA(unsigned char gain_idx);   // ��ġ�� PGA �ε��� �� ����.
extern "C" __declspec(dllimport) short Set_ADCMaxNumChannel(unsigned char maxnum_channel);	// ��ġ�� ADC�մ��� ��ä�� ���� MUX�� �ִ� ä���� �����Ѵ�. 2^n �� ä�μ��� �����Ѵ�. 
extern "C" __declspec(dllimport) short Set_ConfigChannel(unsigned char *Is_Select_Channel); // ä�μ���.
extern "C" __declspec(dllimport) short Set_KeyBoardMarking(unsigned char on_off);			// Ű���� ��ŷ��� ����Ұ����� �������� �����ϴ°�. 1�� ����Ѵ�. 0�� ������� �ʴ´�. ���Լ� ȣ������ ������ ����Ʈ���� 0�̴�. 
extern "C" __declspec(dllimport) short Set_MessageMode(unsigned char keybd);		
