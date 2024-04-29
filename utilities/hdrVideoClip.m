function outputVideo = hdrVideoClip(filespec)
%HDRVIDEOCLIP Create a video from a list of .exr files

videoFPS = 2; % show slowly

hdrList = dir(filespec);
[hdrPath, basename, ~] = fileparts(filespec);
outputVideoPrefix = fullfile(hdrPath, [basename '-video']);


if isunix
    demoVideo = VideoWriter(outputVideoPrefix, 'Motion JPEG AVI');
else
    % H.264 only works on Windows and Mac
    demoVideo = VideoWriter(outputVideoPrefix, 'MPEG-4');
end

demoVideo.FrameRate = videoFPS;
demoVideo.Quality = 99;
open(demoVideo);
for ii = 1:numel(hdrList)
    hdr = exrread(fullfile(hdrList(ii).folder,hdrList(ii).name));
    rgb = tonemap(hdr);
    writeVideo(demoVideo,rgb);
end
close (demoVideo);

end

