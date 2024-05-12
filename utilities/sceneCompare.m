function sceneCompare(sceneFile1,sceneFile2)
%SCENECOMPARE Compare radiance of two scenes
%   Specifically designed for seeing if additive exposures work

%{
sceneHomeDir = fullfile(ivDirGet('local'), 'synthetic_scene_tests','generated');
sceneCompare(fullfile(sceneHomeDir,'pavilion-day016-001-002.mat'), ...
    fullfile(sceneHomeDir, 'pavilion-day033-001-001.mat'));
%}

% Load our scenes
scene1 = load(sceneFile1,'outputScene');
scene1Data = scene1.outputScene;
scene2 = load(sceneFile2,'outputScene');
scene2Data = scene2.outputScene;

%{
mean(scene1Data.data.photons, 'all')
mean(scene2Data.data.photons, 'all')
%}
% Compute some usable image from them, that we can use to compare
%image1 = sceneShowImage(scene1Data,-3);
%image2 = sceneShowImage(scene2Data,-3);

% Compute image as rendered through a sensor:
oi1 = oiCreate('pinhole');
oi2 = oiCreate('pinhole');

% get the optical image (light falling on the sensor plane)
oi1 = oiCompute(oi1, scene1Data);
oi2 = oiCompute(oi2, scene2Data);

%{
mean(oi1.data.photons, 'all')
mean(oi2.data.photons, 'all')
%}

% create an arbitray sensor so we get an RGB image
sensor1 = sensorCreate('imx363'); % oldie but a goodie
sensor2 = sensorCreate('imx363'); % oldie but a goodie

% compute the image recorded by the sensor
sensor1 = sensorCompute(sensor1, oi1);
sensor2 = sensorCompute(sensor2, oi2);

%{
mean(sensor1.data.dv, 'all')
mean(sensor2.data.dv, 'all')

mean(sensor1.data.volts, 'all')
mean(sensor2.data.volts, 'all')

%}

mesh(sensor1.data.dv - sensor2.data.dv);
% Do a comparison & measure results
%montage({image1, image2});


end

