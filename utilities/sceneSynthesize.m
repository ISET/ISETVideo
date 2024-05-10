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
    outputEXR = [];
    for jj = 1:frames
        if ii+jj <= numel(inputEXRs)
            nextEXR = fullfile(inputEXRs(ii+jj).folder, ...
                inputEXRs(ii+jj).name);
            if isfile(nextEXR)
                ourEXR = exrread(nextEXR);
                if isempty(outputEXR)
                    outputEXR = ourEXR;
                else
                    outputEXR = ourEXR + outputEXR;
                end
                frameCount = jj;
            end
        else
            continue;
        end
    end
    % need to write out
    outputFileName = fullfile( outputDir, sprintf('%s-%03d-%03d.exr', ...
        basename, ii, ii+frameCount-1));
    exrwrite(outputEXR,outputFileName);
end
end

