function sceneSynthesize(filespec,frames)
%SCENESYNTHESIZE Add scenes (exr files or eventually scenes also)
%   To synthesize longer exposures
% WE need to change this to generate scenes
% and then we can also make sure '1' works to turn exrs into scenes

%{
sceneSynthesize(fullfile(ivRootPath,'local', 'pavilion-night', 'frames-001ms', 'pav*.exr'),4);
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
    for jj = 1:frames
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
        basename, ii, ii+frameCount-1));
    save(outputFileName,'outputScene');
    
end
end

