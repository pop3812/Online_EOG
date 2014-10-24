function varargout = OnlineEyeblinkDetector(varargin)
% ONLINEEYEBLINKDETECTOR MATLAB code for OnlineEyeblinkDetector.fig
%      ONLINEEYEBLINKDETECTOR, by itself, creates a new ONLINEEYEBLINKDETECTOR or raises the existing
%      singleton*.
%
%      H = ONLINEEYEBLINKDETECTOR returns the handle to a new ONLINEEYEBLINKDETECTOR or the handle to
%      the existing singleton*.
%
%      ONLINEEYEBLINKDETECTOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ONLINEEYEBLINKDETECTOR.M with the given input arguments.
%
%      ONLINEEYEBLINKDETECTOR('Property','Value',...) creates a new ONLINEEYEBLINKDETECTOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before OnlineEyeblinkDetector_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to OnlineEyeblinkDetector_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help OnlineEyeblinkDetector

% Last Modified by GUIDE v2.5 23-Oct-2014 18:27:28

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @OnlineEyeblinkDetector_OpeningFcn, ...
                   'gui_OutputFcn',  @OnlineEyeblinkDetector_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before OnlineEyeblinkDetector is made visible.
function OnlineEyeblinkDetector_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to OnlineEyeblinkDetector (see VARARGIN)

% Choose default command line output for OnlineEyeblinkDetector
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes OnlineEyeblinkDetector wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = OnlineEyeblinkDetector_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbtn_start.
function pushbtn_start_Callback(hObject, eventdata, handles)
% hObject    handle to pushbtn_start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
    
    global timer_id_4obtaining_data;
    global timer_id_4camera;
    global g_handles;
    global p;
    g_handles = handles;
    
   % timer_id_4camera= timer('TimerFcn','CameraRecording','StartDelay',0,'Period',0.05,'ExecutionMode','FixedRate');
    timer_id_4obtaining_data= timer('TimerFcn','DataProcessing','StartDelay',0,'Period',1,'ExecutionMode','FixedRate');
    
    start(timer_id_4obtaining_data);
    %start(timer_id_4camera);

    


% --- Executes on button press in pushbtn_stop.
function pushbtn_stop_Callback(hObject, eventdata, handles)
% hObject    handle to pushbtn_stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global timer_id_4obtaining_data;
    global vid;
    global writerObj;
    global timer_id_4camera;
    
    %Closing Laxtha Connection
     MatScanEnd();
     stop(timer_id_4obtaining_data);
    
    %Closing Video
 %   writerObj=close(writerObj);         % Close the movie file
 %   stop(timer_id_4camera);
 %   stop(vid);
    
    
function init4Camera()
    global vid;
    global writerObj;
    
    vid = videoinput('winvideo',1, 'YUY2_320x240');
    set(vid, 'FramesPerTrigger', Inf);
    set(vid, 'ReturnedColorspace', 'rgb');

    vid.FrameGrabInterval = 1;  % distance between captured frames 
    start(vid)

    %writerObj = VideoWriter('myVideo','Motion JPEG AVI');   % Create a new AVI file
    writerObj = avifile('myVideo','compression','Cinepak');   % Create a new AVI file
    writerObj.fps = 8;
    %open(writerObj);

    
function p = init4Laxtha(p)
    ChNum = 1;
    SR = 9;
    gain = 128;
    p.BufferLength_Laxtha = 512;
    MatScanStart(ChNum, SR, gain);

function p = init4MSDW_Processing
    clear p;
    
    p.min_window_width = 6; %6 = 6/64  = about 93.8 ms
    p.max_window_width = 14; %14 = 14/64  = 448/2048 = about 220 ms
    p.samplingFrequency2Use = 64 ; %64;
   
    p.threshold  =-1;
    p.prev_threshold = -1;
    p.min_th_abs_ratio = 0.4;
    
    p.nBin4Histogram = 50; %Histogram을 작성하는 데에 사용할 bin의 수
    
    p.queuelength = 10* p.samplingFrequency2Use;
    
    
    p.dataqueue   = circlequeue(p.queuelength,1);
    p.v_dataqueue  = circlequeue(p.queuelength,1);
    p.acc_dataqueue = circlequeue(p.queuelength,1);
    p.msdw = circlequeue(p.queuelength,1);
    p.windowSize4msdw = circlequeue(p.queuelength,1);
    p.indexes_localMax = circlequeue(p.queuelength/2,1);
    p.indexes_localMin = circlequeue(p.queuelength/2,1);
    p.detectedRange_inQueue =  circlequeue(p.queuelength/2,2);
    p.msdw_minmaxdiff =  circlequeue(p.queuelength/2,1); %msdw 를 local min과 max와의 차이 형태로 변환시키는 데이터
    p.msdw_minmaxdiff.data(:,:) = Inf;
    
    p.histogram = accHistogram;
    
    p.dataqueue.data(:,:) = NaN;
    p.medianfilter_size = 5;
    p.buffer_4medianfilter = circlequeue(p.medianfilter_size,1);
    
    %히스토그램과 관련된 변수설정
    %bHistogramAvailable = 0;
    p.nMinimalData4HistogramCalculation = 5*p.samplingFrequency2Use; %5초. queuelength 보다 짧아야 한다. histogram을 만드는데 필요한 데이터 point의 개수가 아닌, source 데이터의 길이를 의미한다.
    p.alpha = 0;
    p.v = 0.05;

    


% --- Executes on button press in pushbtn_init.
function pushbtn_init_Callback(hObject, eventdata, handles)
% hObject    handle to pushbtn_init (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global p;
    p = init4MSDW_Processing();
    p = init4Laxtha(p); %Laxth 기기와의 연결 초기화
%    init4Camera();


% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    eventdata.Key


% --- Executes on key press with focus on figure1 or any of its controls.
function figure1_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
eventdata.Key


% --- Executes during object creation, after setting all properties.
function axes2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axes2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate axes2
