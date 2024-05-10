function outputVideo = hdrVideoClip(filespec)
%HDRVIDEOCLIP Create a video from a list of .exr files

%{
% example code
hdrVideoClip(fullfile(ivRootPath,'local', 'pavilion-night','frames-001ms','pav*.exr'))
hdrVideoClip(fullfile(ivRootPath,'local', 'pavilion-night', 'frames-001ms','generated--004ms','pav*.exr'));
hdrVideoClip('~/iset/isetvideo/local/pavilion-night/33 ms frames and preview video/pav*.exr');
%}
videoFPS = 30; % 2 is show slowly

hdrList = dir(filespec);
[hdrPath, basename, ~] = fileparts(filespec);
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
    scene = piEXR2ISET(hdrFile);
    sceneDeNoise = scene; %piAIdenoise(scene);
    % 
    rgb = sceneShowImage(sceneDeNoise, -3); % HDR
    demoVideo(rgb);
    clear scene;
    clear sceneDeNoise;

end
release(demoVideo);
end

