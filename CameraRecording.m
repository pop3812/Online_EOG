function CameraRecording()
%tic
    global vid;
    global writerObj;
   % global g_handles;
    
    I=getsnapshot(vid);
  %  imshow(I);
    F = im2frame(I);                    % Convert I to a movie frame
  %  writeVideo(writerObj,F)
    writerObj = addframe(writerObj,F);
 %   toc
end