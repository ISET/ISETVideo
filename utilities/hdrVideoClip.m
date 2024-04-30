function outputVideo = hdrVideoClip(filespec)
%HDRVIDEOCLIP Create a video from a list of .exr files

videoFPS = 2; % show slowly

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
    piEXRDenoise(hdrFile);
    hdr = exrread(hdrFile);
    hdr = max(hdr,0);
    % DOESN"T WORK rgb = tonemap(real(hdr));
    rgb = single(hdrRender(hdr));
    %imshow(rgb);
    %writeVideo(demoVideo,rgb);
    demoVideo(rgb);
end
%close (demoVideo);
release(demoVideo);
end

