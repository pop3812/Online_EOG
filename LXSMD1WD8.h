// This header file must be included in main program to use "LXSM_D1WD8.DLL"
// DLL version 1.2 Released 2003-11-03
#define WM_AcqUnitData	WM_USER+1

extern "C" __declspec(dllimport) unsigned long Get_StreamMemory();			// 스트림메모리(실수형배열)의 주소를 반환함.unsigned long 타입으로 반환함.
extern "C" __declspec(dllimport) float * Get_StreamMemoryFP();			// 스트림메모리(실수형배열)의 주소를 반환함. float* 형으로 반환함. 2010년 9월 20일 추가됨.
extern "C" __declspec(dllimport) short Init_Device(HWND msgtarget_window,int pid); // H/W장치 초기화, stream message받을 윈도우 handle 및 장치의 고유ID전달.
extern "C" __declspec(dllimport) short Close_Device();	
extern "C" __declspec(dllimport) short Start_Stream();					   // Stream 시작. 선행 Init_Device, 단 한번.
extern "C" __declspec(dllimport) short Stop_Stream();					   // Stream 종료. 선행 Init_Device, Start_Stream.
extern "C" __declspec(dllimport) short Set_SampleFreq(unsigned char samplefreq_idx);   // 장치의 Sampling Frequency 설정.
extern "C" __declspec(dllimport) short Set_PGA(unsigned char gain_idx);   // 장치의 PGA 인덱스 값 설정.
extern "C" __declspec(dllimport) short Set_ADCMaxNumChannel(unsigned char maxnum_channel);	// 장치의 ADC앞단의 다채널 지원 MUX의 최대 채널을 설정한다. 2^n 로 채널수를 설정한다. 
extern "C" __declspec(dllimport) short Set_ConfigChannel(unsigned char *Is_Select_Channel); // 채널선택.
extern "C" __declspec(dllimport) short Set_KeyBoardMarking(unsigned char on_off);			// 키보드 마킹기능 사용할것인지 말것인지 셋팅하는것. 1은 사용한다. 0은 사용하지 않는다. 본함수 호출하지 않으면 디폴트값은 0이다. 
extern "C" __declspec(dllimport) short Set_MessageMode(unsigned char keybd);		
