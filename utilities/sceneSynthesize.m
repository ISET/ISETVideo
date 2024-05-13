function sceneSynthesize(filespec,frames)

%SCENESYNTHESIZE Add scenes (exr files or eventually scenes also)
%   To synthesize longer exposures
%
% Note: Adding multiple shorter "exposures" generates higher photon counts
%       than the equivalent longer exposure, since pbrt doesn't adjust
%       for exposure time (as far as I can tell)
%
% So, we need to find some way to normalize our luminance, based on the
% number of scenes we've been asked to combine.
%
% D.Cardinal, Stanford University, 2024
%{
sceneSynthesize(fullfile(ivDirGet('local'), 'pavilion-night', 'synthetic-scene-test', 'pav*033*.exr'),1);

sceneSynthesize(fullfile(ivDirGet('local'), 'synthetic_scene_tests', 'pavilion-day*016*.exr'),2);
sceneSynthesize(fullfile(ivDirGet('local'), 'synthetic_scene_tests', 'pavilion-day*033*.exr'),1);
%}



inputEXRs = dir(filespec);

[dirPath, basename, ~] = fileparts(filespec);
basename = replace(basename,'*','');

outputDir = fullfile(dirPath,'generated');
if ~isfolder(outputDir)
    mkdir(outputDir);
end

outputScene = [];
for ii = 1:frames:numel(inputEXRs)
    inputScenes = {};
    for jj = 0:frames-1
        nextEXR = fullfile(inputEXRs(ii+jj).folder, ...
            inputEXRs(ii+jj).name);
        if isfile(nextEXR)
            ourScene = piEXR2ISET(nextEXR);
            inputScenes{jj+1} = ourScene;
        else
            continue; % no file to read
        end
    end
    weight = 1/numel(inputScenes);
    outputScene = sceneAdd(inputScenes, repelem(weight, numel(inputScenes)), 'add');

    % need to write out
    outputFileName = fullfile( outputDir, sprintf('%s-%03d-%03d.mat', ...
        basename, ii, jj+1));
    save(outputFileName,'outputScene');

end



