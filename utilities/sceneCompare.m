function [sensor1, sensor2] = sceneCompare(sceneFile1,sceneFile2, exposureTime)
%SCENECOMPARE Compare radiance of two scenes
%   Specifically designed for seeing if additive exposures work

% Updated to accept pre-loaded scenes

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

% Load our scenes
if isequal(class(sceneFile1),'struct')
    scene1Data = sceneFile1;
else
    scene1 = load(sceneFile1,'outputScene');
    scene1Data = scene1.outputScene;
end
if isequal(class(sceneFile2),'struct')
    scene2Data = sceneFile2;
else
    scene2 = load(sceneFile2,'outputScene');
    scene2Data = scene2.outputScene;
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
oi1 = oiCrop(oiCompute(oi1, scene1Data),'border');
oi2 = oiCrop(oiCompute(oi2, scene2Data),'border')';

%{
mean(oi1.data.photons, 'all')
mean(oi2.data.photons, 'all')

mean(oi1.data.illuminance, 'all')
mean(oi2.data.illuminance, 'all')
%}

% create an arbitray sensor so we get an RGB image
sensor1 = sensorCreate(useSensor); % oldie but a goodie
sensor2 = sensorCreate(useSensor); % oldie but a goodie

sensor1 = sensorSet(sensor1,'rows',480);
sensor1 = sensorSet(sensor1,'cols',640);
sensor2 = sensorSet(sensor2,'rows',480);
sensor2 = sensorSet(sensor2,'cols',640);

% We don't want AutoExposure
sensor1 = sensorSet(sensor1,'integration time', exposureTime);
sensor2 = sensorSet(sensor2,'integration time', exposureTime);

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

