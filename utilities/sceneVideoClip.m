function sceneVideoClip(sceneName)
%% sceneVideoClip
% NOTE: Need to parameterize hard-coded options
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
% As of May, 2024 we support camera motion on a GPU using either
% ActiveTransforms or Rotate/Translate 
%
% Developed by David Cardinal, Stanford University, 2020-2024.
%

ieInit();
% some timing code, just to see how fast we run...
benchmarkstart = cputime;
tStart = tic;

% cpBurstCamera is a sub-class of cpCamera that implements simple HDR and Burst
% capture and processing
%# ourCamera = cpBurstCamera();

%% Our Parameters (could be passed if we make this a function)

% scenes

%% Primary scenes for video clip work
%scenePath = 'barcelona-pavilion';
%sceneName = 'pavilion-night';
%sceneName = 'pavilion-day';

%% Also Working (at least without Active motion)
%scenePath = 'sanmiguel';
%sceneName = 'sanmiguel-courtyard';
%sceneName = 'sanmiguel-realistic-courtyard';
%scenePath = 'bistro';
%sceneName = 'bistro_boulangerie';
%%sceneName = 'bistro_cafe';
%sceneName = 'bistro_vespa';
%scenePath = 'contemporary-bathroom';
%sceneName = 'contemporary-bathroom';
%scenePath = 'landscape';
%sceneName = 'view-0';

%% Not working at all
% Can't render Kroken due to mixed texture bug
%scenePath = 'kroken';
%sceneName = 'camera-1';
% Can't render villa due to some type of wavefront error
%scenePath = 'villa';
%sceneName = 'villa-daylight';

%% Set camera motion here using a per-scene preset
cameraMotion = createCameraMotion(sceneName);

% Set overall length, frame rate, and preview video replay rate
clipLength = 1/30; %.02; % seconds
exposureTime = 1/60; %1/8; %.001; % seconds
videoFPS = 20; % How many frames per second to encode

% Rays per pixel (more is slower, but less noisy)
nativeRaysPerPixel = 2048;
% Fast Preview Factor (we only denoise when fastPreview > 1)
fastPreview = 1 ; % >1 is multiplierfor for faster rendering

% Calculate the number of frames for our video
numFrames = floor(clipLength / exposureTime);

%% NOTE: Currently we stop at Scene, so camera code is mostly moot
% We'll use a pre-defined sensor for our Camera Module, and let it use
% default optics for now. We can then assign the module to our camera:
% NOTE: When generating just scenes, this is ignored
%# sensor = sensorCreate('imx363');

% The sensor comes in with a small default resolution, and in any case
% well want to decide on one for ourselves:
nativeSensorResolution = 1024; %
aspectRatio = 4/3;  % Set to desired ratio
raysPerPixel = floor(nativeRaysPerPixel/fastPreview);

ourRows = floor(nativeSensorResolution / fastPreview);
ourCols = floor(aspectRatio * ourRows);

%# sensor = sensorSet(sensor,'size',[ourRows ourCols]);
%# sensor = sensorSet(sensor,'noiseFlag', 0); % 0 is less noise

% Make the pixels bigger, but keep the sensor the same size
% This is useful for previewing more quickly:
%# nativePSize = pixelGet(sensor.pixel,'pixel width');
%# previewPSize = nativePSize * fastPreview;
%# sensor.pixel = pixelSet(sensor.pixel,'sizesamefillfactor',[previewPSize previewPSize]);


% Cameras can eventually have more than one module (lens + sensor)
% but for now, we just create one using our sensor
%# ourCamera.cmodules(1) = cpCModule('sensor', sensor);

%}

pbrtCPScene = cpScene('pbrt', 'scenePath', scenePath, 'sceneName', sceneName, ...
    'sceneLuminance', 500, ...
    'numRays', raysPerPixel, ...
    'resolution', [ourCols ourRows],...
    'useActiveCameraMotion', cameraMotion.useActiveCameraMotion);

% set the camera in motion, using meters per second per axis
% 'unused', then translate, then rotate
% Z is into scene, Y is up, X is right
framesPerSecond = floor(1/exposureTime);
rotateXPerFrame = cameraMotion.xRot / framesPerSecond;
rotateYPerFrame = cameraMotion.yRot / framesPerSecond;
rotateZPerFrame = cameraMotion.zRot / framesPerSecond;
if pbrtCPScene.useActiveCameraMotion
    % then specify the entire 1 second motion
    pbrtCPScene.cameraMotion = {{'our camera', ...
        [cameraMotion.x, cameraMotion.y, cameraMotion.z], ...
        [rotateXPerFrame, rotateYPerFrame, rotateZPerFrame]}};
else

    % X-axis is 'vertical' rotation, Y-axis is 'horizontal'
    translateXPerFrame = cameraMotion.x / framesPerSecond;
    translateYPerFrame = cameraMotion.y / framesPerSecond;
    translateZPerFrame = cameraMotion.z / framesPerSecond;

    pbrtCPScene.cameraMotion = {{'our camera', ...
        [translateXPerFrame, translateYPerFrame, translateZPerFrame], ...
        [rotateXPerFrame, rotateYPerFrame, rotateZPerFrame]}};
end
[sceneList, ~, ~] = pbrtCPScene.render(repelem(exposureTime, numFrames));

% renderedFiles has the .exr files, sceneList has the .mat files for scenes
videoFolder = fullfile(ivRootPath(),'local','unfiled');
videoFile = fullfile(videoFolder, 'fpsDemo');
videoFrames = [];
for ii=1:numel(sceneList)
    sceneList{ii} = sceneSet(sceneList{ii},'render flag','hdr');

    % dnoise if we are running with less rays per pixel
    if fastPreview > 1
        deNoiseScene = piAIdenoise(sceneList{ii});
    else
        deNoiseScene = sceneList{ii};
    end

    % Experiment with different
    ourFrame = sceneShowImage(deNoiseScene, -3);    % Compute, but don't show
    %ourIP = piRadiance2RGB(deNoiseScene);
    %videoFrames{ii} = im2frame(double(ourIP.data.result));
    videoFrames{ii} = im2frame(double(ourFrame));

end

videoFileName = fullfile(ivRootPath, 'local', [sceneName '-video']);
if isunix
    demoVideo = VideoWriter(videoFileName, 'Motion JPEG AVI');
else
    % H.264 only works on Windows and Mac
    demoVideo = VideoWriter(videoFileName, 'MPEG-4');
end
demoVideo.FrameRate = videoFPS;
demoVideo.Quality = 99;
open(demoVideo);
for ii = 1:numel(videoFrames)
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

end
%% Create scene specific camera paths using x,y,z constant motions & rotations
%  Set useActiveCameraMotion to use ActiveTransforms
%  otherwise Translate and Rotate are used
function cameraMotion = createCameraMotion(preset)
switch preset
    case {'pavilion-night', 'pavilion-day'}
        % In m/s and d/s
        cameraMotion.useActiveCameraMotion = true; % use moving camera instead of translate/rotate
        adjustScale = 1; % In pavilion x-axis is reversed
        cameraMotion.x = adjustScale * -10; % m/s x, y, z
        cameraMotion.y = -1; % m/s x, y, z
        cameraMotion.z = 0; % m/s x, y, z
        cameraMotion.xRot = 0; %-6; % d/s rx, ry, rz
        cameraMotion.yRot = 0; % adjustScale * 30; % d/s rx, ry, rz
        cameraMotion.zRot = 0; % d/s rx, ry, rz    end

end
end
