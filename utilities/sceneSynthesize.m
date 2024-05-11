function sceneSynthesize(filespec,frames)
%SCENESYNTHESIZE Add scenes (exr files or eventually scenes also)
%   To synthesize longer exposures
% WE need to change this to generate scenes
% and then we can also make sure '1' works to turn exrs into scenes

%{
sceneSynthesize(fullfile(ivDirGet('local'), 'pavilion-night', 'synthetic-scene-test', 'pav*033*.exr'),1);

sceneSynthesize(fullfile(ivDirGet('local'), 'synthetic_scene_tests', 'pavilion-day*016*.exr'),2);
sceneSynthesize(fullfile(ivDirGet('local'), 'synthetic_scene_tests', 'pavilion-day*033*.exr'),1);

sceneSynthesize(fullfile(ivDirGet('local'), 'pavilion-night', 'frames-16ms', 'pav*.exr'),2);
sceneSynthesize(fullfile(ivDirGet('local'), 'pavilion-night','frames-33ms','pav*.exr'),1)
%}
inputEXRs = dir(filespec);

[dirPath, basename, ~] = fileparts(filespec);
basename = replace(basename,'*','');

outputDir = fullfile(dirPath,'generated');
if ~isfolder(outputDir)
    mkdir(outputDir);
end

for ii = 1:frames:numel(inputEXRs)
    outputScene = [];
    for jj = 0:frames - 1
        if ii+jj <= numel(inputEXRs)
            nextEXR = fullfile(inputEXRs(ii+jj).folder, ...
                inputEXRs(ii+jj).name);
            if isfile(nextEXR)
                ourScene = piEXR2ISET(nextEXR);
                if isempty(outputScene)
                    outputScene = ourScene;
                else
                    outputScene = sceneAdd(outputScene, ourScene);;
                end
                frameCount = jj;
            end
        else
            continue;
        end
    end
    % need to write out
    outputFileName = fullfile( outputDir, sprintf('%s-%03d-%03d.mat', ...
        basename, ii, ii+frameCount));
    save(outputFileName,'outputScene');
    
end
end

