function [triggerFrame, peakFrame] = identifyTriggerFrame( video, pawPref, varargin )
%
% INPUTS:
%   video - a VideoReader object for the relevant video
%
% VARARGs:
%   numbgframes - number of frames to use at the beginning of the video to
%       calculate the background
%   trigger_roi - 2 x 4 matrix containing coordinates of the region of
%       interest in which to look for the paw to determine the trigger 
%       frame
%
% OUTPUTS:
%   triggerFrame - the frame at which the paw is fully through the slot

numFrames = video.numberOfFrames;
numBGFrames = 50;
frames_before_max = 50;
grayLimit = [50 150];

ROI_to_find_trigger_frame = [  0030         0570         0120         0095
                               1880         0550         0120         0095];
for iarg = 1 : 2 : nargin - 2
    switch lower(varargin{iarg})
        case 'numbgframes',
            numBGFrames = varargin{iarg + 1};
        case 'trigger_roi',   % region of interest to look for trigger frame
            ROI_to_find_trigger_frame = varargin{iarg + 1};
        case 'grylimits',
            grayLimit = varargin{iarg + 1};
    end
end

BGframes = uint8(zeros(numBGFrames, video.Height, video.Width, 3));
for ii = 1 : numBGFrames
    BGframes(ii,:,:,:) = read(video, ii);
end
BGimg = uint8(squeeze(mean(BGframes, 1)));

% identify the frames where the paw is visible over the shelf
if strcmpi(pawPref,'left')
    % use the right mirror for triggering
    BG_ROI = uint8(BGimg(ROI_to_find_trigger_frame(2,2):ROI_to_find_trigger_frame(2,2) + ROI_to_find_trigger_frame(2,4), ...
                         ROI_to_find_trigger_frame(2,1):ROI_to_find_trigger_frame(2,1) + ROI_to_find_trigger_frame(2,3), :));
else
    % use the left mirror for triggering
    BG_ROI = uint8(BGimg(ROI_to_find_trigger_frame(1,2):ROI_to_find_trigger_frame(1,2) + ROI_to_find_trigger_frame(1,4), ...
                         ROI_to_find_trigger_frame(1,1):ROI_to_find_trigger_frame(1,1) + ROI_to_find_trigger_frame(1,3), :));
end

[BG_hist, histBins] = imhist(BG_ROI);
binLimits = zeros(1,2);
binLimits(1) = find(abs(grayLimit(1) - histBins) == min(abs(grayLimit(1) - histBins)));
binLimits(2) = find(abs(grayLimit(2) - histBins) == min(abs(grayLimit(2) - histBins)));
BGsum = sum(BG_hist(binLimits(1):binLimits(2)));

histDiff = zeros(1, numFrames);
for iFrame = 1 : numFrames
%     iFrame
    img = read(video, iFrame);
    
    if strcmpi(pawPref,'left')
        ROI_img = img(ROI_to_find_trigger_frame(2,2):ROI_to_find_trigger_frame(2,2) + ROI_to_find_trigger_frame(2,4), ...
                      ROI_to_find_trigger_frame(2,1):ROI_to_find_trigger_frame(2,1) + ROI_to_find_trigger_frame(2,3), :);
    else
        ROI_img = img(ROI_to_find_trigger_frame(1,2):ROI_to_find_trigger_frame(1,2) + ROI_to_find_trigger_frame(1,4), ...
                      ROI_to_find_trigger_frame(1,1):ROI_to_find_trigger_frame(1,1) + ROI_to_find_trigger_frame(1,3), :);
    end

    ROI_gry = rgb2gray(ROI_img);
    ROI_hist = imhist(ROI_gry);
    ROI_sum = sum(ROI_hist(binLimits(1):binLimits(2)));
    
    histDiff(iFrame) = ROI_sum - BGsum;

end

% find frame with maximum difference between background and current frame
% in the region of interest
histDiff_delta = diff(histDiff);
maxDiffFrame = find(mean_BG_subt_values(mirror_idx,:) == max(mean_BG_subt_values(mirror_idx,:)));
maxDeltaFrame = find(diffFrame_delta(maxDiffFrame-frames_before_max:maxDiffFrame) == ...
                     max(diffFrame_delta(maxDiffFrame-frames_before_max:maxDiffFrame)));
triggerFrame = maxDeltaFrame + (maxDiffFrame-frames_before_max);
% now find the frame with the first significant deviation from baseline
figure
plot(mean_BG_subt_values(1,:))
hold on
plot(mean_BG_subt_values(2,:),'r')
plot(triggerFrame, mean_BG_subt_values(mirror_idx,triggerFrame),'linestyle','none','marker','*')