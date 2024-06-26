function outputVideo = hdrVideoClip(filespec)
%HDRVIDEOCLIP Create a video from a list of .exr files (or scenes?)

%{
% example code
%% 
hdrVideoClip(fullfile(ivDirGet('computed'), 'bunny*005.exr'))
hdrVideoClip(fullfile(ivDirGet('computed'), 'pavilion-night*010.exr'));
hdrVideoClip(fullfile(ivDirGet('local'), 'pavilion-night', 'frames-001ms','generated--004ms','pav*.mat'));
hdrVideoClip(fullfile(ivDirGet('local'),'pavilion-night/33 ms frames and preview video/pav*.exr');
%}
videoFPS = 1; % 2 is show slowly

hdrList = dir(filespec);
[hdrPath, basename, ext] = fileparts(filespec);
basename = replace(basename,'*','');
outputVideoPrefix = fullfile(hdrPath, [basename '-video']);


if isunix
    %demoVideo = VideoWriter(outputVideoPrefix,  'Uncompressed AVI'); % 'Motion JPEG AVI');
    demoVideo = vision.VideoFileWriter([outputVideoPrefix '.avi']); % 'Motion JPEG AVI');
else
    % H.264 only works on Windows and Mac
    %demoVideo = VideoWriter(outputVideoPrefix, 'MPEG-4');
    demoVideo = vision.VideoFileWriter([outputVideoPrefix '.mp4'], 'FileFormat','MPEG4');
end

demoVideo.FrameRate = videoFPS;
% Don't set quality if archival
%demoVideo.Quality = 90;
%open(demoVideo);
for ii = 1:numel(hdrList)
    hdrFile = fullfile(hdrList(ii).folder,hdrList(ii).name);
    if isequal(ext, '.exr')
        scene = piEXR2ISET(hdrFile);
    else
        % already have a scene
        load(hdrFile,'outputScene');
        scene = outputScene;
    end
    sceneDeNoise = scene; %piAIdenoise(scene);
    % 
    rgb = sceneShowImage(sceneDeNoise, -3); % hdr without GUI
    demoVideo(rgb);
    clear scene;
    clear sceneDeNoise;

end
release(demoVideo);
end

