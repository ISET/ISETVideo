%% Test results with and without active object motion
%
%   BORROWED PIECES FROM
%   v_iset3d_motion (currently v2, using a custom test scene)
%                   with backport additions for ISET3d
%
% D. Cardinal, Stanford University, July, 2024
%

%%
ieInit
if ~piDockerExists, piDockerConfig; end
dockerInUse = []; % used to switch between cpu and gpu


% Set up scene for comparison
asset = 'A_O'; % could use any of the letters

% Threshold for deciding burst image matches long exposure
ssimThreshold = .96; % is as high as .99 best case

% motion params (may need to be adjusted for units)
assetTranslation = [.1 .1 0];
assetRotation = [0 0 90];

%% First use standard translation and rotation as a baseline

%% Now test dynamic object motion
thisR = resetScene();

% If we set .hasActiveTransform,
% customWRS makes sure we have a CPU version of PBRT
thisR.hasActiveTransform = true;

% We're not using shutter times yet, so values are total desired
piAssetMotionAdd(thisR,asset, ...
    'translation', assetTranslation);

piAssetMotionAdd(thisR,asset , ...
    'rotation', assetRotation);

% We need to test both camera and asset movement
thisR.set('camera motion translate start',[0 0 0]);
thisR.set('camera motion translate end',translationEnd);

customWRS(thisR,'asset_and_camera', dockerInUse);

%% Try using shutter times to control position
%% Add scene with camera motion
thisRAnimation = resetScene();
thisRNoAnimation = resetScene();

thisRAnimation.hasActiveTransform = true;
translationEnd = [.7 -.7 0];

% maybe we could set these for both and then copy?
thisRAnimation.set('camera motion translate start',[0 0 0]);
thisRAnimation.set('camera motion translate end',translationEnd);
thisRNoAnimation.set('camera motion translate start',[0 0 0]);
thisRNoAnimation.set('camera motion translate end',translationEnd);

%% Set parameters for our burst
exposureTime = .001; % currently this needs to be short enough to avoid long exposure from blowing out.
exposureMultiplier = 1000; %only used for creating integer file names

% Set how many burst frames we want to sum to a longer exposure
numFrames = 5; % Arbitrary, > 1

% Length of the long exposure (and of any video made from the burst)
totalDuration = exposureTime * numFrames;

shutterStart = 0;

% Will contain scenes for the Asset motion case
sceneAnimation = []; % so we can check for isempty()
sceneNoAnimation = []; % so we can sum frames into it

% We're not using shutter times yet, so values are m/s
assetTranslation = [.01*exposureMultiplier .01*exposureMultiplier 0];
piAssetMotionAdd(thisR,asset, ...
    'translation', assetTranslation);

assetRotation = [0 0 45]; % Check if this is d/s so we need to multiply?
piAssetMotionAdd(thisR,asset , ...
    'rotation', assetRotation);

for ii = 1:numFrames

    % Add shutter times so we can step asset and camera motion
    % forward as we capture frames
    shutterOpen = shutterStart + (exposureTime * (ii-1));
    shutterClose =  shutterStart + (exposureTime * ii);
    thisR.set('shutteropen', shutterOpen);
    thisR.set('shutterclose', shutterClose);
    thisRCamera.set('shutteropen', shutterOpen);
    thisRCamera.set('shutterclose', shutterClose);

    % Set custom output file names for later analysis and
    % potentially turning into a video clip
    outputFile = sprintf('shutter_%03d_%03d',shutterOpen*exposureMultiplier, ...
        shutterClose*exposureMultiplier);

    % Now render, show, and write output file
    % customWRS calls piWRS, but sets the output file name
    %           and scene name to make tracing simpler
    currentScene = customWRS(thisR,outputFile, dockerInUse);

    % Now do the same for the version of the scene with camera motion
    outputFile = sprintf('camera_%03d_%03d',shutterOpen*exposureMultiplier, ...
        shutterClose*exposureMultiplier);
    currentSceneCamera = customWRS(thisRCamera, outputFile, dockerInUse);

    % Now we want to walk through this with both animation
    % and no animation
    if isempty(sceneAnimation) % or sceneNoAnimation
        sceneAnimationCamera = currentScene;
        sceneBurstCamera = currentSceneCamera;

        % First time through take our "long" exposure
        shutterClose = shutterStart + (exposureTime*numFrames);
        thisR.set('shutterClose', shutterClose);
        thisRCamera.set('shutterClose', shutterClose);

        % To even out noise characteristics, we want * numFrames
        % raysPerPixel for the long exposure
        baseRPP = recipeGet(thisR, 'rays per pixel');
        recipeSet(thisR, 'rays per pixel',baseRPP * numFrames);
        recipeSet(thisRCamera, 'rays per pixel',baseRPP * numFrames);

        outputFile = sprintf('shutter_%03d_%03d',shutterOpen*exposureMultiplier, ...
            shutterClose*exposureMultiplier);
        sceneLongBaseline = customWRS(thisR, outputFile, dockerInUse);
        sceneLong = sceneLongBaseline;

        outputFile = sprintf('camera_%03d_%03d',shutterOpen*exposureMultiplier, ...
            shutterClose*exposureMultiplier);
        sceneLongBaselineCamera = customWRS(thisRCamera, outputFile, dockerInUse);
        sceneLongCamera = sceneLongBaselineCamera;

        % Now reset rays per pixel
        recipeSet(thisR, 'rays per pixel',baseRPP);
        recipeSet(thisRCamera, 'rays per pixel',baseRPP);
    else

        % Accrue photon values from each exposure
        % For long exposure just do an incremental sum
        sceneBurst = sceneAdd(sceneBurst, currentScene);
        sceneLong = sceneAdd(sceneLong, sceneLongBaseline);

        sceneBurstCamera = sceneAdd(sceneBurstCamera, currentSceneCamera);
        sceneLongCamera = sceneAdd(sceneLongCamera, sceneLongBaselineCamera);

    end

end

% Compute the scene using a reasonable sensor
% For validation this is a simple monochrome version
% For video assembly, we'd presumably want to add a "real" sensor
% [sensorLong, sensorBurst] = sceneCompare(sceneLong,sceneBurst, totalDuration);

% sceneWindow(sceneLong);
% sceneWindow(sceneBurst);

% Sanity check for luminance levels
% [x,y] for location
scenePlot(sceneLong,'luminance hline',[1 127]);
scenePlot(sceneBurst,'luminance hline',[1 127]);


%%  Calculate sensor responses and compare
oiLong = oiCompute(oiCreate('wvf'),sceneLong,'crop',true);
oiBurst = oiCompute(oiCreate('wvf'),sceneBurst,'crop',true);
oiLongDenoise = piAIdenoise(oiLong);
oiBurstDenoise = piAIdenoise(oiBurst);

sensor = sensorCreate('monochrome');
sensor = sensorSet(sensor,'fov',oiGet(oiBurst,'fov'),oiBurst);

% Can shorten exposure time if needed to prevent clipping
sensor = sensorSet(sensor,'exp time',.0002);
% Need to set the noise flag off, or sensoraddnoise also
% crops the voltage
sensor = sensorSet(sensor, 'noise flag', -1);

sensorLong = sensorCompute(sensor,oiLong);
sensorLongDenoise = sensorCompute(sensor,oiLongDenoise);
sensorBurst = sensorCompute(sensor,oiBurst);
sensorBurstDenoise = sensorCompute(sensor,oiBurstDenoise);

sensorWindow(sensorLong);
sensorWindow(sensorLongDenoise);
sensorWindow(sensorBurst);

voltsLong = sensorGet(sensorLongDenoise,'volts');
voltsBurst = sensorGet(sensorBurstDenoise,'volts');

% Use ssim as a quick check
[ssimVal, ssimMap] = ssim(voltsLong, voltsBurst);
ieNewGraphWin; imagesc(ssimMap);

% Now do the same thing for the version of the scene with camera motion
% Currently uses sceneCompare from isetvideo
% which denoises the sensor image
[sensorLongCamera, sensorBurstCamera] = sceneCompare(sceneLongCamera, ...
    sceneBurstCamera, totalDuration);

% class of volts has to match for ssim (maybe fix in ssim?)
voltsLongCamera = double(sensorLong.data.volts);
voltsBurstCamera = double(sensorBurst.data.volts);

[ssimValCamera, ssimMapCamera] = ssim(voltsLongCamera, voltsBurstCamera);

% show results:
assert(ssimVal > ssimThreshold, 'Asset SSIM is below threshold');
fprintf('SSIM Assets only: %f\n',ssimVal)
figure;
imshowpair(voltsLong,voltsBurst,'diff')

assert(ssimValCamera > ssimThreshold, 'Asset & Camera SSIM is below threshold');
fprintf('SSIM Assets & Camera: %f\n',ssimValCamera)
figure;
imshowpair(voltsLongCamera,voltsBurstCamera,'diff')


%% ------------------------------------------------------------
% END OF MAIN SCRIPT -- SUPPORT FUNCTIONS FOLLOW

%% Customize output file & scene name for easier tracing
function scene = customWRS(thisR, outputName, dockerInUse)

[p, ~, e] = fileparts(thisR.outputFile);
outFileName = ['Test_' outputName e];
thisR.outputFile = fullfile(p,outFileName);
thisR.name = ['Test: ' outputName];

% Now run the regular wrs
% with the docker object needed
dockerInUse = getDocker(thisR, dockerInUse);

% Make sure to turn off mean luminance!!
scene = piWRS(thisR, 'mean luminance', -1, ...
    'dockerWrapper', dockerInUse);

end

%% Select correct version of PBRT

% Set up correct docker image
% isetdocker in -tiny ignores the docker container we pass and uses presets
% so for now we have to clear out the container

function useDocker = getDocker(thisR, dockerInUse)

% Only reset when switching!
% Need to add code that works with both iset3D and iset3D-tiny!!
usingTiny = contains(piRootPath,'-tiny','IgnoreCase',true);

% If we have -tiny in our path, use isetdocker
if usingTiny

    if thisR.hasActiveTransform
        % Need to use a cpu version of pbrt for this case
        % switch if needed
        if isempty(dockerInUse) || isequal(dockerInUse.device, 'gpu')
            reset(isetdocker);
            dockerCPU = isetdocker('preset','orange-cpu');
            useDocker = dockerCPU;
        else
            useDocker = dockerInUse;
        end
    else % can use GPU
        if isempty(dockerInUse) || ~isequal(dockerInUse.device, 'gpu')
            dockerGPU = isetdocker('preset','remoteorange');
            useDocker = dockerGPU;
        else % we already have a GPU version
            useDocker = dockerInUse;
        end
    end
else % otherwise use dockerWrapper from ISET3d

    if thisR.hasActiveTransform % need CPU
        if isempty(dockerInUse) || dockerInUse.gpuRendering
            % Need CPU for object motion
            useDocker = dockerWrapper('verbosity',2,'gpuRendering',0, ...
                'remoteImage','digitalprodev/pbrt-v4-cpu');
        else
            useDocker = dockerInUse;
        end
    else % can use GPU
        if isempty(dockerInUse) || ~dockerInUse.gpuRendering
            useDocker = dockerWrapper('verbosity',2,'gpuRendering',1, ...
                'remoteImage', 'digitalprodev/pbrt-v4-gpu-ampere-ti');
        else
            useDocker = dockerInUse;
        end
    end
end
end


%% --------------

function thisR = resetScene()

useScene = 'lettersForMotionTests.pbrt';
useRPP = 128;
%useScene = 'lettersAtDepth.pbrt';
thisR = piRead(useScene);
thisR.metadata.rendertype = {'radiance', 'depth'};
recipeSet(thisR,'rays per pixel', useRPP);
end


