function [points2d,timeList,isPawVisible] = trackMirrorView( video, triggerTime, initPawMask, BGimg_ud, sr_ratInfo, boxRegions, boxCalibration, greenBGmask, varargin )

video.CurrentTime = triggerTime;

targetMean = [0.5,0.1,0.5];
targetSigma = [0.2,0.2,0.2];

foregroundThresh = 25/255;

stretch_hist_limit_int = 0.5;
stretch_hist_limit_ext = 0.75;

pawHSVrange = [1/3, 0.002, 0.999, 1.0, 0.99, 1.0   % for restrictive external masking
               1/3, 0.005, 0.99, 1.0, 0.97, 1.0     % for more liberal external masking
               1/3, 0.002, 0.999, 1.0, 0.80, 1.0    % for restrictive internal masking
               1/3, 0.03, 0.95, 1.0, 0.60, 1.0    % for liberal internal masking
               1/3, 0.03, 0.99, 1.0, 0.90, 1.0    % for restrictive masking just behind the front panel
               1/3, 0.10, 0.95, 1.0, 0.70, 1.0    % for liberal masking just behind the front panel
               0.00, 0.02, 0.00, 0.001, 0.999, 1.0];  % for white masking

maxDistPerFrame = 20;

whiteThresh_ext = 0.95;
whiteThresh_int = 0.85;

% blob parameters for mirror view
pawBlob = vision.BlobAnalysis;
pawBlob.AreaOutputPort = true;
pawBlob.CentroidOutputPort = true;
pawBlob.BoundingBoxOutputPort = true;
pawBlob.LabelMatrixOutputPort = true;
pawBlob.MinimumBlobArea = 100;
pawBlob.MaximumBlobArea = 4000;

for iarg = 1 : 2 : nargin - 9
    switch lower(varargin{iarg})
%         case 'pawgraylevels',
%             pawGrayLevels = varargin{iarg + 1};
%         case 'pixelcountthreshold',
%             pixCountThresh = varargin{iarg + 1};
        case 'foregroundthresh',
            foregroundThresh = varargin{iarg + 1};
        case 'maxdistperframe',
            maxDistPerFrame = varargin{iarg + 1};
        case 'hsvlimits',
            pawHSVrange = varargin{iarg + 1};
        case 'targetmean',
            targetMean = varargin{iarg + 1};
        case 'targetsigma',
            targetSigma = varargin{iarg + 1};
        case 'pawblob',
            pawBlob = varargin{iarg + 1};
        case 'whitethresh_ext',
            whiteThresh_ext = varargin{iarg + 1};
        case 'whitethresh_int',
            whiteThresh_int = varargin{iarg + 1};
        case 'stretch_hist_limit_int',
            stretch_hist_limit_int = varargin{iarg + 1};
        case 'stretch_hist_limit_ext',
            stretch_hist_limit_ext = varargin{iarg + 1};
    end
end

if strcmpi(class(BGimg_ud),'uint8')
    BGimg_ud = double(BGimg_ud) / 255;
end

pawPref = lower(sr_ratInfo.pawPref);
if iscell(pawPref)
    pawPref = pawPref{1};
end

vidName = fullfile(video.Path, video.Name);
video = VideoReader(vidName);
video.CurrentTime = triggerTime;


% frontPanelWidth = panelWidthFromMask(boxRegions.frontPanelMask);
[fpoints2d, timeList_f,isPawVisible_f] = trackPaw_mirror_local( video, BGimg_ud, initPawMask{2},pawBlob, boxRegions, pawPref,'forward',boxCalibration,greenBGmask,...
                                     'foregroundthresh',foregroundThresh,...
                                     'pawhsvrange',pawHSVrange,...
                                     'maxdistperframe',maxDistPerFrame,...
                                     'targetmean',targetMean,...
                                     'targetsigma',targetSigma,...
                                     'whitethresh_ext',whiteThresh_ext,...
                                     'whitethresh_int',whiteThresh_int,...
                                     'stretch_hist_limit_int',stretch_hist_limit_int,...
                                     'stretch_hist_limit_ext',stretch_hist_limit_ext);
    
video.CurrentTime = triggerTime;

[rpoints2d, timeList_b,isPawVisible_b] = trackPaw_mirror_local( video, BGimg_ud, initPawMask{2},pawBlob, boxRegions, pawPref, 'reverse',boxCalibration,greenBGmask,...
                                     'foregroundthresh',foregroundThresh,...
                                     'pawhsvrange',pawHSVrange,...
                                     'maxdistperframe',maxDistPerFrame,...
                                     'targetmean',targetMean,...
                                     'targetsigma',targetSigma,...
                                     'whitethresh_ext',whiteThresh_ext,...
                                     'whitethresh_int',whiteThresh_int,...
                                     'stretch_hist_limit_int',stretch_hist_limit_int,...
                                     'stretch_hist_limit_ext',stretch_hist_limit_ext);

                                 
   
points2d = rpoints2d;
trigFrame = round(triggerTime * video.FrameRate);
for iFrame = trigFrame : length(fpoints2d)
    points2d{iFrame} = fpoints2d{iFrame};
end
timeList = [timeList_b,timeList_f(2:end)];
isPawVisible = isPawVisible_b | isPawVisible_f;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [points2d,timeList,isPawVisible] = trackPaw_mirror_local( video, ...
                                    BGimg_ud, ...
                                    initPawMask, ...
                                    pawBlob, ...
                                    boxRegions, ...
                                    pawPref, ...
                                    timeDir, ...
                                    boxCalibration,...
                                    greenBGmask,...
                                    varargin)

zeroTol = 1e-10;
fps = video.FrameRate;

h = video.Height;
w = video.Width;

stretch_hist_limit_int = 0.5;
stretch_hist_limit_ext = 0.75;

switch lower(pawPref),
    case 'right',
        fundMat = boxCalibration.srCal.F(:,:,1);
    case 'left',
        fundMat = boxCalibration.srCal.F(:,:,2);
end
cameraParams = boxCalibration.cameraParams;

if strcmpi(timeDir,'reverse')
    numFrames = round((video.CurrentTime) * fps);
    frameCount = numFrames;
else
    numFrames = round((video.Duration - video.CurrentTime) * fps);
    frameCount = 1;
end
totalFrames = round(video.Duration * fps);

prevMask = initPawMask;

targetMean = [0.5,0.2,0.5];
    
targetSigma = [0.2,0.2,0.2];
           
for iarg = 1 : 2 : nargin - 9
    switch lower(varargin{iarg})
%         case 'pawgraylevels',
%             pawGrayLevels = varargin{iarg + 1};
%         case 'pixelcountthreshold',
%             pixCountThresh = varargin{iarg + 1};
        case 'foregroundthresh',
            foregroundThresh = varargin{iarg + 1};
        case 'pawhsvrange',
            pawHSVrange = varargin{iarg + 1};
%         case 'maxredgreendist',
%             maxRedGreenDist = varargin{iarg + 1};
%         case 'minrgdiff',
%             minRGDiff = varargin{iarg + 1};
        case 'maxdistperframe',
            maxDistPerFrame = varargin{iarg + 1};
        case 'targetmean',
            targetMean = varargin{iarg + 1};
        case 'targetsigma',
            targetSigma = varargin{iarg + 1};
        case 'whitethresh_ext',
            whiteThresh_ext = varargin{iarg + 1};
        case 'whitethresh_int',
            whiteThresh_int = varargin{iarg + 1};
        case 'stretch_hist_limit_int',
            stretch_hist_limit_int = varargin{iarg + 1};
        case 'stretch_hist_limit_ext',
            stretch_hist_limit_ext = varargin{iarg + 1};
    end
end

points2d = cell(1,totalFrames);

timeList(frameCount) = video.CurrentTime;
currentFrame = round((video.CurrentTime) * fps);
image = readFrame(video);   % just to advance one frame for forward direction
image_ud = undistortImage(image, cameraParams);
image_ud = double(image_ud) / 255;
orig_BGimg_ud = BGimg_ud;
image_ud = color_adapthisteq(image_ud);


isPawVisible = false(totalFrames,1);
isPawVisible(currentFrame) = true;

temp = bwmorph(bwconvhull(initPawMask),'remove');
[y,x] = find(temp);
points2d{currentFrame} = [x,y];
% framesChecked = 0;
% isPawVisible(frameCount,:) = true(1,2);   % by definition (almost), paw is visible in both views in the initial frame

[y,~] = find(boxRegions.floorMask);
ROI_bot = min(y);
shelfLims = regionprops(boxRegions.shelfMask,'boundingbox');
switch lower(pawPref),
    case 'right',
        ROI = [1,1,floor(shelfLims.BoundingBox(1)),ROI_bot;...
            ceil(shelfLims.BoundingBox(1)+shelfLims.BoundingBox(3)),1,w-ceil(shelfLims.BoundingBox(1)+shelfLims.BoundingBox(3)),ROI_bot];
    case 'left',
        ROI = [ceil(shelfLims.BoundingBox(1)+shelfLims.BoundingBox(3)),1,w-ceil(shelfLims.BoundingBox(1)+shelfLims.BoundingBox(3)),ROI_bot;...
            1,1,floor(shelfLims.BoundingBox(1)),ROI_bot];
%         ext_white_check_SE = [ones(1,10),zeros(1,10)];
end
mirror_BG_image_ud = BGimg_ud(ROI(1,2):ROI(1,2)+ROI(1,4),ROI(1,1):ROI(1,1)+ROI(1,3),:);
other_mirror_BG_image_ud = BGimg_ud(ROI(2,2):ROI(2,2)+ROI(2,4),ROI(2,1):ROI(2,1)+ROI(2,3),:);
lh  = stretchlim(other_mirror_BG_image_ud,0.05);
BGimg_ud_str = imadjust(mirror_BG_image_ud,lh,[]);

while video.CurrentTime < video.Duration && video.CurrentTime >= 0

    prevFrame = frameCount;
%     framesChecked = framesChecked + 1;
    
    if strcmpi(timeDir,'reverse')
        frameCount = frameCount - 1;
        if frameCount == 0
            break;
        end
        video.CurrentTime = frameCount / fps;
    else
        frameCount = frameCount + 1;
    end
    currentFrame = round((video.CurrentTime) * fps);
    fprintf('frame number %d, current frame %d\n',frameCount, currentFrame);
    
    image = readFrame(video);
    if strcmpi(timeDir,'reverse')
        if abs(video.CurrentTime - timeList(prevFrame)) > zeroTol    % a frame was skipped
            % if going backwards, went one too many frames back, so just
            % read the next frame
            image = readFrame(video);
        end
    end
    
    if strcmpi(timeDir,'forward') && ...
       abs(video.CurrentTime - timeList(prevFrame) - 2/fps) > zeroTol && ...
       video.CurrentTime - timeList(prevFrame) - 2/fps < 0
            % if going forwards, this means the CurrentTime didn't advance
            % by 1/fps on the last read (not sure why this occasionally
            % happens - some sort of rounding error)
            timeList(frameCount) = video.CurrentTime;
    else           
        timeList(frameCount) = video.CurrentTime - 1/fps;
    end

    prev_image_ud = image_ud;
    image_ud = undistortImage(image, cameraParams);
    image_ud = double(image_ud) / 255;
                         
    [fullMask,~] = trackNextStep_mirror_20160503_b(image_ud,BGimg_ud_str,fundMat,prevMask,boxRegions,pawPref,greenBGmask,...
                             'foregroundthresh',foregroundThresh,...
                             'pawhsvrange',pawHSVrange,...
                             'maxdistperframe',maxDistPerFrame,...
                             'targetmean',targetMean,...
                             'targetsigma',targetSigma,...
                             'whitethresh_ext',whiteThresh_ext,...
                             'whitethresh_int',whiteThresh_int,...
                             'stretch_hist_limit_int',stretch_hist_limit_int,...
                             'stretch_hist_limit_ext',stretch_hist_limit_ext);
                         
%     [fullMask,~] = trackNextStep_mirror_20160330(image_ud,fundMat,prevMask,boxRegions,pawPref,...
%                              'foregroundthresh',foregroundThresh,...
%                              'pawhsvrange',pawHSVrange,...
%                              'maxdistperframe',maxDistPerFrame,...
%                              'targetmean',targetMean,...
%                              'targetsigma',targetSigma,...
%                              'whitethresh_ext',whiteThresh_ext,...
%                              'whitethresh_int',whiteThresh_int,...
%                              'stretch_hist_limit_int',stretch_hist_limit_int,...
%                              'stretch_hist_limit_ext',stretch_hist_limit_ext);

	if any(fullMask(:))
        temp = bwmorph(fullMask,'remove');
        [y,x] = find(temp);
        points2d{currentFrame} = [x,y];
        isPawVisible(currentFrame) = true;
        prevMask = fullMask;
    else
        points2d{currentFrame} = [];
        isPawVisible(currentFrame) = false;
        if isPawVisible(lastFrame)
            prevMask = imdilate(prevMask, strel('disk',maxDistPerFrame));
        end
    end
    
	lastFrame = currentFrame;
        
%     showSingleViewTracking(image_ud,fullMask)
end

end