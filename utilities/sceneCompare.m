function sceneCompare(sceneFile1,sceneFile2)
%SCENECOMPARE Compare radiance of two scenes
%   Specifically designed for seeing if additive exposures work

%{
sceneHomeDir = fullfile(ivRootPath(),'local', 'pavilion-night');
sceneCompare(fullfile(sceneHomeDir,'frames-16ms','generated-33ms','pav-001-002.mat'), ...
    fullfile(sceneHomeDir, 'frames-33ms','generated-scenes','pav-001-001.mat'));
%}

% Load our scenes
scene1 = load(sceneFile1,'outputScene');
scene1Data = scene1.outputScene;
scene2 = load(sceneFile2,'outputScene');
scene2Data = scene2.outputScene;

% Compute some usable image from them, that we can use to compare
image1 = sceneShowImage(scene1Data,-3);
image2 = sceneShowImage(scene2Data,-3);

% Do a comparison & measure results
montage({image1, image2});


end

