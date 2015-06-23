function centroids = track3Dpaw(video, ...
                                BGimg, ...
                                peakFrameNum, ...
                                F, ...
                                startPawMask, ...
                                digitMirrorMask_dorsum, ...
                                digitCenterMask, ...
                                rat_metadata, ...
                                register_ROI, ...
                                boxMarkers, ...
                                varargin)
%
%
%
% INPUTS:
%    video - video reader object containing the current video under
%       analysis
%    BGimg - 
%    peakFrameNum - frame in which the paw and digits were initially
%       identified
%    F - 
%    digitMirrorMask_dorsum - m x n x 5 matrix, where each m x n matrix contains a mask
%       for a part of the paw. 1st row - dorsum of paw, 2nd through 5th
%       rows are each digit from index finger to pinky. Obviously, this is
%       the mask for the dorsum of the paw in the "peakFrame"
%    digitCenterMask - m x n x 5 matrix, where each m x n matrix contains a mask
%       for a part of the paw. 1st row - dorsum of paw, 2nd through 5th
%       rows are each digit from index finger to pinky. Obviously, this is
%       the mask for the direct view in the "peakFrame"
%   rat_metadata - needed to know whether to look to the left or right of
%       the dorsal aspect of the paw to exclude points that can't be digits
%   register_ROI - 
%   boxMarkers - 
%
% VARARGS:
%    bgimg - background image 
%
% OUTPUTS:
%

startTimeFromPeak = 0.2;    % in seconds
for iarg = 1 : 2 : nargin - 10
    switch lower(varargin{iarg})
        case 'numbgframes',
            numBGframes = varargin{iarg + 1};
        case 'trigger_roi',
            ROI_to_find_trigger_frame = varargin{iarg + 1};
        case 'graypawlimits',
            gray_paw_limits = varargin{iarg + 1};
        case 'bgimg',
            BGimg = varargin{iarg + 1};
        case 'starttimebeforepeak',
            startTimeFromPeak = varargin{iarg + 1};
    end
end



vidName = fullfile(video.Path, video.Name);
video = VideoReader(vidName);
peakTime = (peakFrameNum / video.FrameRate);
video.CurrentTime = peakTime;
image = readFrame(video);
hsv_image = rgb2hsv(image);

paw_img = cell(1,3);
for ii = 1 : 3
    paw_img{ii} = image(register_ROI(ii,2):register_ROI(ii,2) + register_ROI(ii,4),...
                        register_ROI(ii,1):register_ROI(ii,1) + register_ROI(ii,3),:);
	if ii ~= 2
        paw_img{ii} = fliplr(paw_img{ii});
    end
end

if strcmpi(rat_metadata.pawPref, 'right')
    pawDorsumMirrorImg = paw_img{1};
else
    pawDorsumMirrorImg = paw_img{3};
end
% initialize one track each for the dorsum of the paw and each digit in the
% mirror and center views

% WORKING HERE - NEED TO DETERMINE A SET OF PROPERTIES FOR EACH REGION THAT
% MAY INDICATE WHETHER THE NEXT DETECTION CORRESPONDS TO IT OR NOT - FOR
% EXAMPLE, MEAN COLOR/HUE/INTENSITY, ETC. MAY NEED TO DO THIS ADAPTIVELY
% OVER TIME. HERE'S AN IDEA - ASSUME THE CENTROID LOCATION DOESN'T MOVE BETWEEN
% FRAMES, USE THAT AS A SEED FOR GEODESIC DISTANCE MAPPING AFTER DOING A
% DECORRSTRETCH...
tracks = initializeTracks();
numTracks = 0;
for ii = 1 : size(digitMirrorMask_dorsum, 3)
    numTracks = numTracks + 1;
    s = regionprops(squeeze(digitMirrorMask_dorsum(:,:,ii)),'Centroid','BoundingBox');
    temp = fliplr(squeeze(digitCenterMask(:,:,ii)));
    imgDigitMirrorMask = false(size(BGimg,1),size(BGimg,2));
    if strcmpi(rat_metadata.pawPref,'right')
        imgDigitMirrorMask(register_ROI(1,2):register_ROI(1,2)+register_ROI(1,4), ...
                           register_ROI(1,1):register_ROI(1,3)+register_ROI(1,3)) = temp;
    else
        imgDigitMirrorMask(register_ROI(3,2):register_ROI(3,2)+register_ROI(3,4), ...
                           register_ROI(3,1):register_ROI(3,3)+register_ROI(3,3)) = temp;
    end
    % need code here to calculate mean r, g, b values within each masked
    % region
%     rgb_mean = zeros(1,3);
%     for jj = 1 : 3
%         curChannelImage = squeeze(pawDorsumMirrorImg(:,:,jj));
%         maskIdx = find(squeeze(digitMirrorMask_dorsum(:,:,ii)));
%         rgb_mean(jj) = mean(curChannelImage(maskIdx));
%     end
    
	kalmanFilter = configureKalmanFilter('ConstantVelocity', ...
        s.Centroid, [200, 50], [100, 25], 100);
    CAMshiftTracker = vision.HistogramBasedTracker;
    initializeObject(CAMshiftTracker, hsv_image(:,:,1), round(s.BoundingBox));
    
    newTrack = struct(...
        'id', ii, ...
        'bbox', s.BoundingBox, ...
        'kalmanFilter', kalmanFilter, ...
        'CAMshiftTracker', CAMshiftTracker, ...
        'age', 1, ...
        'totalVisibleCount', 1, ...
        'consecutiveInvisibleCount', 1);
    
    tracks(numTracks) = newTrack;
end

for ii = 1 : size(digitCenterMask, 3)
    numTracks = numTracks + 1;
    temp = squeeze(digitCenterMask(:,:,ii));
    imgDigitCenterMask = false(size(BGimg,1),size(BGimg,2));
    imgDigitCenterMask(register_ROI(2,2):register_ROI(2,2)+register_ROI(2,4), ...
                       register_ROI(2,1):register_ROI(2,3)+register_ROI(2,3)) = temp;
    
    s = regionprops(squeeze(digitCenterMask(:,:,ii)),'Centroid','BoundingBox');
    
%     rgb_mean = zeros(1,3);
%     for jj = 1 : 3
%         curChannelImage = squeeze(pawDorsumMirrorImg(:,:,jj));
%         maskIdx = find(squeeze(digitMirrorMask_dorsum(:,:,ii)));
%         rgb_mean(jj) = mean(curChannelImage(maskIdx));
%     end
    
	kalmanFilter = configureKalmanFilter('ConstantVelocity', ...
        s.Centroid, [200, 50], [100, 25], 100);
    CAMshiftTracker = vision.HistogramBasedTracker;
    initializeObject(CAMshiftTracker, hsv_image(:,:,1), round(s.BoundingBox));
    
    newTrack = struct(...
        'id', ii, ...
        'bbox', s.BoundingBox, ...
        'kalmanFilter', kalmanFilter, ...
        'CAMshiftTracker', CAMshiftTracker, ...
        'age', 1, ...
        'totalVisibleCount', 1, ...
        'consecutiveInvisibleCount', 1);
    
    tracks(numTracks) = newTrack;
end
% paw_mask = startPawMask;
while video.CurrentTime < video.Duration
    image = readFrame(video);
    hsv_image = rgb2hsv(image);
    figure(1)
    imshow(image)
    hold on

    for ii = 1 : numTracks
        bbox = step(tracks(ii).CAMshiftTracker, hsv_image(:,:,1));
        rectangle('position',bbox);
    end
%     paw_mask = maskPaw_moving(image, BGimg, digitMirrorMask_dorsum, digitCenterMask, register_ROI, F, rat_metadata, boxMarkers);
    
    
%     figure(2)
%     imshow(image);
end
% detector = vision.ForegroundDetector(...
%    'NumTrainingFrames', 50, ... % 5 because of short video
%    'InitialVariance', 30*30); % initial standard deviation of 30
blob = vision.BlobAnalysis(...
   'CentroidOutputPort', false, 'AreaOutputPort', false, ...
   'BoundingBoxOutputPort', true, ...
   'MinimumBlobAreaSource', 'Property', 'MinimumBlobArea', 200);

sTime = (peakFrameNum / video.FrameRate);
figure(1)
frameNum = 0;
while video.CurrentTime < video.Duration
    image = readFrame(video);
    fgMask = step(detector, image);
    imshow(fgMask);
    frameNum = frameNum + 1;
end
mirrorTracks_dorsum = initializeTracks();
centerTracks        = initializeTracks();

% rewind 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tracks = initializeTracks()
    % create an empty array of tracks
    tracks = struct(...
        'id', {}, ...
        'bbox', {}, ...
        'kalmanFilter', {}, ...
        'CAMshiftTracker', {}, ...
        'age', {}, ...
        'totalVisibleCount', {}, ...
        'consecutiveInvisibleCount', {});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function obj = setupSystemObjects()
        % Initialize Video I/O
        % Create objects for reading a video from a file, drawing the tracked
        % objects in each frame, and playing the video.

        % Create a video file reader.
        obj.reader = vision.VideoFileReader('atrium.avi');

        % Create two video players, one to display the video,
        % and one to display the foreground mask.
        obj.videoPlayer = vision.VideoPlayer('Position', [20, 400, 700, 400]);
        obj.maskPlayer = vision.VideoPlayer('Position', [740, 400, 700, 400]);

        % Create System objects for foreground detection and blob analysis

        % The foreground detector is used to segment moving objects from
        % the background. It outputs a binary mask, where the pixel value
        % of 1 corresponds to the foreground and the value of 0 corresponds
        % to the background.

        obj.detector = vision.ForegroundDetector('NumGaussians', 3, ...
            'NumTrainingFrames', 40, 'MinimumBackgroundRatio', 0.7);

        % Connected groups of foreground pixels are likely to correspond to moving
        % objects.  The blob analysis System object is used to find such groups
        % (called 'blobs' or 'connected components'), and compute their
        % characteristics, such as area, centroid, and the bounding box.

        obj.blobAnalyser = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
            'AreaOutputPort', true, 'CentroidOutputPort', true, ...
            'MinimumBlobArea', 400);
    end