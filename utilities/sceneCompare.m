function [sensor1, sensor2] = sceneCompare(scene1,scene2, exposureTime)
%SCENECOMPARE Compare radiance of two scenes
%   Specifically designed for seeing if additive exposures work
%
% Inputs:
%  scene1, scene2: Either scene files or scene objects
%  exposureTime: Integration time for the sensors
%{
sceneHomeDir = fullfile(ivDirGet('local'), 'synthetic_scene_tests','generated');
sceneCompare(fullfile(sceneHomeDir,'pavilion-day016-001-002.mat'), ...
    fullfile(sceneHomeDir, 'pavilion-day033-001-001.mat'), .033);

% for debug
sceneHomeDir = fullfile(ivDirGet('local'), 'synthetic_scene_tests','generated');
sceneCompare(fullfile(sceneHomeDir,'pavilion-day016-001-001.mat'), ...
    fullfile(sceneHomeDir, 'pavilion-day033-001-001.mat'), .033);
%}

% Pick a sensor
useSensor = 'Monochrome';

% Load our scenes, unless we have them already
if isequal(class(scene1),'struct')
    scene1Data = scene1;
else
    ourScene1 = load(scene1,'outputScene');
    scene1Data = ourScene1.outputScene;
end
if isequal(class(scene2),'struct')
    scene2Data = scene2;
else
    ourScene2 = load(scene2,'outputScene');
    scene2Data = ourScene2.outputScene;
end

% Without denoising we get massive luminance spikes
scene1Data = piAIdenoise(scene1Data);
scene2Data = piAIdenoise(scene2Data);
%{
mean(scene1Data.data.photons, 'all')
mean(scene2Data.data.photons, 'all')
%}
% Compute some usable image from them, that we can use to compare
%image1 = sceneShowImage(scene1Data,-3);
%image2 = sceneShowImage(scene2Data,-3);

% Compute image as rendered through a sensor:
oi1 = oiCreate('default');
oi2 = oiCreate('default');

% get the optical image (light falling on the sensor plane)
% crop to scene size -- don't want spillover in this case
oi1 = oiCompute(oi1, scene1Data,'crop', true);
oi2 = oiCompute(oi2, scene2Data,'crop', true)';

%{
mean(oi1.data.photons, 'all')
mean(oi2.data.photons, 'all')

mean(oi1.data.illuminance, 'all')
mean(oi2.data.illuminance, 'all')
%}

% create an arbitray sensor so we get an RGB image
sensor1 = sensorCreate(useSensor); % oldie but a goodie
sensor2 = sensorCreate(useSensor); % oldie but a goodie

sensorScale = 1;
sensor1 = sensorSet(sensor1,'rows',480*sensorScale);
sensor1 = sensorSet(sensor1,'cols',640*sensorScale);
sensor2 = sensorSet(sensor2,'rows',480*sensorScale);
sensor2 = sensorSet(sensor2,'cols',640*sensorScale);

% We don't want AutoExposure
sensor1 = sensorSet(sensor1,'integration time', exposureTime);
sensor2 = sensorSet(sensor2,'integration time', exposureTime);

%%%% NOTE: I'm not sure why we are running into this and wheter the default
% oi should have photons of type do
oi1.data.photons = double(oi1.data.photons);
oi2.data.photons = double(oi2.data.photons);

% compute the image recorded by the sensor
sensor1 = sensorCompute(sensor1, oi1);
sensor2 = sensorCompute(sensor2, oi2);

%{
mean(sensor1.data.dv, 'all')
mean(sensor2.data.dv, 'all')

mean(sensor1.data.volts, 'all')
mean(sensor2.data.volts, 'all')

%}

% if we want to show results
% mesh(sensor1.data.volts - sensor2.data.volts);
%{
% Do a comparison & measure results
image1 = sensorShowImage(sensor1,1);
image2 = sensorShowImage(sensor2,1);
montage({image1, image2});
%}


end

