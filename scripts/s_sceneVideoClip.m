%% s_sceneVideoClip
%
% Create a short "video clip" of scenes
%
% Initially this will be simply a series of scene .exr
% files that can be viewed in tev or iset
%
% Uses our computational photography (cp) framework
% with a cpBurstCamera in 'video' mode to capture a series
% of 3D images generated using ISET3d-v4/pbrt-v4.
% 
% Camera motion is supported on CPU and GPU.
% Currently Object Motion is only supported on CPU (PBRT-v4 limitation)
% 
% Developed by David Cardinal, Stanford University, 2024.
%

ieInit();
% some timing code, just to see how fast we run...
benchmarkstart = cputime; 
tStart = tic;

% cpBurstCamera is a sub-class of cpCamera that implements simple HDR and Burst
% capture and processing
ourCamera = cpBurstCamera(); 

% We'll use a pre-defined sensor for our Camera Module, and let it use
% default optics for now. We can then assign the module to our camera:
% NOTE: When generating just scenes, this is ignored
sensor = sensorCreate('imx363');

% The sensor comes in with a small default resolution, and in any case
% well want to decide on one for ourselves:
nativeSensorResolution = 2048; % about real life
aspectRatio = 4/3;  % Set to desired ratio

% Specify the number of frames for our video
numFrames = 3; % Total number of frames to render
videoFPS = 10; % How many frames per second to encode

% Rays per pixel (more is slower, but less noisy)
nativeRaysPerPixel = 512;

% Fast Preview Factor
fastPreview = 32 ; % multiplierfor optional faster rendering
raysPerPixel = floor(nativeRaysPerPixel/fastPreview);

ourRows = floor(nativeSensorResolution / fastPreview);
ourCols = floor(aspectRatio * ourRows); 

sensor = sensorSet(sensor,'size',[ourRows ourCols]);
sensor = sensorSet(sensor,'noiseFlag', 0); % 0 is less noise

% Make the pixels bigger, but keep the sensor the same size
% This is useful for previewing more quickly:
nativePSize = pixelGet(sensor.pixel,'pixel width');
previewPSize = nativePSize * fastPreview;
sensor.pixel = pixelSet(sensor.pixel,'sizesamefillfactor',[previewPSize previewPSize]);


% Cameras can eventually have more than one module (lens + sensor)
% but for now, we just create one using our sensor
ourCamera.cmodules(1) = cpCModule('sensor', sensor); 


scenePath = 'sanmiguel';
sceneName = 'sanmiguel-courtyard';
sceneWidth = 40; % rough width of scene in meters
sceneHeight = 25; % rough height of scene in meters
desiredXRotation = 55; % how many degrees do we want to rotate down
desiredYRotation = 150; % how many degrees do we want to rotate left
xGravity = .1; % Inverse of how many scene widths to move horizontally
yGravity = .1; % Inverse of how many scene widths to move vertically
zDistance = 2; % Meters into scene

pbrtCPScene = cpScene('pbrt', 'scenePath', scenePath, 'sceneName', sceneName, ...
    'resolution', [ourCols ourRows], ... 
    'sceneLuminance', 500, ...
    'numRays', raysPerPixel);

%{
% This section is just for when using our scenes
% add the basic materials from our library
piMaterialsInsert(pbrtCPScene.thisR);

% clear out any default lights
pbrtCPScene.thisR = piLightDelete(pbrtCPScene.thisR, 'all');

% put our scene in an interesting room
pbrtCPScene.thisR.set('skymap', 'room.exr', 'rotation val', [-90 180 0]);

lightName = 'from camera';
spectrumScale = 3; lightSpectrum = 'equalEnergy';
ourLight = piLightCreate(lightName,...
                           'type', 'distant',...
                           'specscale float', spectrumScale,...
                           'spd spectrum', lightSpectrum,...
                           'cameracoordinate', true);

pbrtCPScene.thisR.set('light', ourLight, 'add');
%}



% set the camera in motion, using meters per second per axis
% 'unused', then translate, then rotate
% Z is into scene, Y is up, X is right
translateZPerFrame = zDistance / numFrames; 
translateYPerFrame = (sceneHeight / numFrames) / yGravity;
translateXPerFrame = (sceneWidth / numFrames) / xGravity;

% X-axis is 'vertical' rotation, Y-axis is 'horizontal'
rotateXPerFrame =  -1 * (desiredXRotation / numFrames);
rotateYPerFrame = -1 * (desiredYRotation / numFrames);

pbrtCPScene.cameraMotion = {{'unused', ...
    [translateXPerFrame, translateYPerFrame, translateZPerFrame], ...
    [rotateXPerFrame, rotateYPerFrame, 0]}};

[sceneList, sceneFiles] = pbrtCPScene.render([.1 .1 .1]);

%{
% For when we want to have a real camera
videoFrames = ourCamera.TakePicture(pbrtCPScene, ...
    'Video', 'numVideoFrames', numFrames, 'imageName','Video with Camera Motion');

% optionally, take a peek
imtool(videoFrames{4});
if isunix
    demoVideo = VideoWriter('cpDemo', 'Motion JPEG AVI');
else
    % H.264 only works on Windows and Mac
    demoVideo = VideoWriter('cpDemo', 'MPEG-4');
end
demoVideo.FrameRate = videoFPS;
demoVideo.Quality = 99;
open(demoVideo);
for ii = 2:numel(videoFrames)
    writeVideo(demoVideo,videoFrames{ii});
end
close (demoVideo);
%}
% timing code
tTotal = toc(tStart);
afterTime = cputime;
beforeTime = benchmarkstart;
glData = rendererinfo;
%disp(strcat("Local cpCam ran  on: ", glData.Vendor, " ", glData.Renderer, "with driver version: ", glData.Version)); 
disp(strcat("Local cpCam ran  in: ", string(afterTime - beforeTime), " seconds of CPU time."));
disp(strcat("Total cpCam ran  in: ", string(tTotal), " total seconds."));



