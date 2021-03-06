function [fullMask, meanRelColor] = trackNextStep_mirror_relRGB( image_ud, prev_im_ud, fundMat, BGimg_ud, prevMask, isPrevPawVisible, meanRelColor, boxRegions, pawPref,varargin)

% CONSIDER SUBTRACTING EACH IMAGE FROM THE PREVIOUS ONE, USING THAT AS A
% BACKGROUND MASK EXCEPT IN THE IMMEDIATE VICINITY OF THE LAST PAW
% LOCATION?

h = size(image_ud,1); w = size(image_ud,2);
% image_ud = imadjust(image_ud,[0.05,0.05,0.05;0.95,0.95,0.95],[]);

relBG = relativeRGB(BGimg_ud);
maxFrontPanelSep = 30;
maxDistBehindFrontPanel = 15;
maxDistPerFrame = 20;
shelfThick = 50;

frontPanelMask = imdilate(boxRegions.frontPanelMask,strel('disk',2));
% frontPanelEdge = imdilate(frontPanelMask, strel('disk',maxDistBehindFrontPanel)) & ~frontPanelMask;

% rThresh = 0.25;
% gThresh = 0.98;
% bThresh = 0.10;
darkThresh = 0.05;
% diffThresh = 0.15;
BGthresh = 0.05;
% pawColorThresh = [0.5,0.7,0.5];
meanRelColor = [0.4,0.8,0.4;0.4,0.8,0.4];
% diff_thresh = [0.2,0.2,0.2];

intMask = boxRegions.intMask;
extMask = boxRegions.extMask;
floorMask = boxRegions.floorMask;
belowShelfMask = boxRegions.belowShelfMask;
shelfMask = boxRegions.shelfMask;
% slotMask = boxRegions.slotMask;
[y,~] = find(floorMask);
% ROI_bot = min(y);

for iarg = 1 : 2 : nargin - 9
    switch lower(varargin{iarg})
        case 'pawhsvrange'
            pawHSVrange = varargin{iarg + 1};
        case 'maxdistperframe'
            maxDistPerFrame = varargin{iarg + 1};
    end
end

% shelfLims = regionprops(boxRegions.shelfMask,'boundingbox');
% directViewWidth = round(w - shelfLims.BoundingBox(1) - shelfLims.BoundingBox(3));
% switch lower(pawPref)
%     case 'right'
%         ROI = [ceil(shelfLims.BoundingBox(1)),1,ceil(shelfLims.BoundingBox(3)),ROI_bot;...
%                1,1,floor(shelfLims.BoundingBox(1)),ROI_bot;...
%                ceil(shelfLims.BoundingBox(1)+shelfLims.BoundingBox(3)),1,w-ceil(shelfLims.BoundingBox(1)+shelfLims.BoundingBox(3)),ROI_bot];
%         SE_fromExt = [zeros(1,maxFrontPanelSep+25),ones(1,maxFrontPanelSep+35)];
%         SE_fromInt = [ones(1,maxFrontPanelSep+35),zeros(1,maxFrontPanelSep+25)];
%         
%         overlapCheck_SE_fromExt = [zeros(1,5),ones(1,5)];
%         overlapCheck_SE_fromInt = [ones(1,15),zeros(1,15)];
% %         ext_white_check_SE = [zeros(1,10),ones(1,10)];
%     case 'left'
%         ROI = [ceil(shelfLims.BoundingBox(1)),1,ceil(shelfLims.BoundingBox(3)),ROI_bot;...
%                ceil(shelfLims.BoundingBox(1)+shelfLims.BoundingBox(3)),1,w-ceil(shelfLims.BoundingBox(1)+shelfLims.BoundingBox(3)),ROI_bot;...
%                1,1,floor(shelfLims.BoundingBox(1)),ROI_bot];
%         SE_fromExt = [ones(1,maxFrontPanelSep+25),zeros(1,maxFrontPanelSep+25)];
%         SE_fromInt = [zeros(1,maxFrontPanelSep+25),ones(1,maxFrontPanelSep+25)];
%         overlapCheck_SE_fromExt = [ones(1,5),zeros(1,5)];
%         overlapCheck_SE_fromInt = [zeros(1,15),ones(1,15)];
% %         ext_white_check_SE = [ones(1,10),zeros(1,10)];
% end

% check to see if the paw was entirely outside the box, entirely inside the
% box, or partially in both in the last frame
testOut = prevMask{2} & extMask;
if any(testOut(:))
    prev_pawOut = true;
else
    prev_pawOut = false;
end
testIn = prevMask{2} & intMask;
if any(testIn(:))
    prev_pawIn = true;
else
    prev_pawIn = false;
end
testBelow = prevMask{1} & belowShelfMask;
if any(testBelow(:))
    pawBelow = true;
else
    pawBelow = false;
end
testAbove = prevMask{1} & (~belowShelfMask & ~shelfMask);
if any(testAbove(:))
    pawAbove = true;
else
    pawAbove = false;
end

prev_bbox = zeros(2,4);
prev_ROI = cell(1,2);
cur_ROI = cell(1,2);
prev_mask_ROI = cell(1,2);
prev_mask_curROI = cell(1,2);
prev_mask_dilate_ROI = cell(1,2);
% prev_im_relRGB = cell(1,2);
RGBdiffs = cell(1,2);
pawPixels = cell(1,2);
im_relRGB = cell(1,2);
drkmsk = cell(1,2);
dilated_bbox = zeros(2,4);
relBG_ROI = cell(1,2);
for ii = 2 : -1 : 1
    temp = regionprops(bwconvhull(prevMask{ii},'union'),'BoundingBox');
    prev_bbox(ii,:) = round(temp.BoundingBox);
    dilated_bbox(ii,:) = [prev_bbox(ii,1)-maxDistPerFrame,...
                          prev_bbox(ii,2)-maxDistPerFrame,...
                          prev_bbox(ii,3)+(2*maxDistPerFrame),...
                          prev_bbox(ii,4)+(2*maxDistPerFrame)];
                          
    if ii == 2   
        
%         if any(frontPanelMask_ROI(:))
            SE = [ones(1,maxDistBehindFrontPanel),zeros(1,maxDistBehindFrontPanel)];
            behindPanelMask = imdilate(frontPanelMask,SE) & ~frontPanelMask;
%         end
        
        prevMask_dilate = imdilate(prevMask{2},strel('disk',maxDistPerFrame));
        
        frontPanelTest = (prevMask_dilate & frontPanelMask);
        if any(frontPanelTest(:))
            if prev_pawIn == false 
                if strcmpi(pawPref,'left')
                    % extend the bounding box backward by maxFrontPanelSep
                    dilated_bbox(2,1) = dilated_bbox(2,1) - maxFrontPanelSep;
                    dilated_bbox(2,3) = dilated_bbox(2,3) + maxFrontPanelSep;

                    % extend prevMask_dilate back by maxFrontPanelSep
                    SE = [ones(1,maxFrontPanelSep+maxDistPerFrame),zeros(1,maxFrontPanelSep+maxDistPerFrame)];
%                     prevMask_temp = imdilate(prevMask{2}, SE);
%                     prevMask_dilate = prevMask_temp | prevMask_dilate;
                    prevMask_dilate = imdilate(prevMask_dilate, SE);
                else
                    % extend the bounding box forward by maxFrontPanelSep
                    dilated_bbox(2,3) = dilated_bbox(2,3) + maxFrontPanelSep;

                    % extend prevMask_dilate forward by maxFrontPanelSep
                    SE = [zeros(1,maxFrontPanelSep+maxDistPerFrame),ones(1,maxFrontPanelSep+maxDistPerFrame)];
%                     prevMask_temp = imdilate(prevMask{2}, SE);
%                     prevMask_dilate = prevMask_temp | prevMask_dilate;
                    prevMask_dilate = imdilate(prevMask_dilate, SE);
                end
            end
            if prev_pawOut == false
                if strcmpi(pawPref,'left')
                    % extend the bounding box forward by maxFrontPanelSep
                    dilated_bbox(2,3) = dilated_bbox(2,3) + maxFrontPanelSep;

                    % extend prevMask_dilate forward by maxFrontPanelSep
                    SE = [zeros(1,maxFrontPanelSep+maxDistPerFrame),ones(1,maxFrontPanelSep+maxDistPerFrame)];
%                     prevMask_temp = imdilate(prevMask{2}, SE);
%                     prevMask_dilate = prevMask_temp | prevMask_dilate;
                    prevMask_dilate = imdilate(prevMask_dilate, SE);
                else
                    % extend the bounding box backward by maxFrontPanelSep
                    dilated_bbox(2,1) = dilated_bbox(2,1) - maxFrontPanelSep;
                    dilated_bbox(2,3) = dilated_bbox(2,3) + maxFrontPanelSep;

                    % extend prevMask_dilate back by maxFrontPanelSep
                    SE = [ones(1,maxFrontPanelSep+maxDistPerFrame),zeros(1,maxFrontPanelSep+maxDistPerFrame)];
%                     prevMask_temp = imdilate(prevMask{2}, SE);
%                     prevMask_dilate = prevMask_temp | prevMask_dilate;
                    prevMask_dilate = imdilate(prevMask_dilate, SE);
                end
            end
        end
        behindPanelMask = prevMask_dilate & behindPanelMask;
%         behindPanelMask = prevMask_temp & behindPanelMask;
        behindPanelMask = behindPanelMask(dilated_bbox(ii,2):dilated_bbox(ii,2)+dilated_bbox(ii,4),dilated_bbox(ii,1):dilated_bbox(ii,1)+dilated_bbox(ii,3));
    else
        prevMask_dilate = imdilate(prevMask{1},strel('disk',maxDistPerFrame));
        shelfTest = (prevMask_dilate & shelfMask);
        if any(shelfTest(:)) && (pawIn == true)  % check that part of the paw is currently inside the box on the last frame. Note this is set on the first loop iteration.
            if pawAbove == false
                % extend the bounding box up
                dilated_bbox(1,2) = dilated_bbox(1,2) - shelfThick;
                dilated_bbox(1,4) = dilated_bbox(1,4) + shelfThick;
                
                % extend prevMask_dilate up
                SE = [ones(shelfThick,1);zeros(shelfThick,1)];
                prevMask_dilate = imdilate(prevMask_dilate, SE);
            end
            if pawBelow == false
                % extend the bounding box down
                dilated_bbox(1,4) = dilated_bbox(1,4) + shelfThick;
                
                % extend prevMask_dilate down
                SE = [zeros(shelfThick,1);ones(shelfThick,1)];
                prevMask_dilate = imdilate(prevMask_dilate, SE);
            end
        end
    end
    
    prev_ROI{ii} = prev_im_ud(prev_bbox(ii,2):prev_bbox(ii,2)+prev_bbox(ii,4),prev_bbox(ii,1):prev_bbox(ii,1)+prev_bbox(ii,3),:);
    prev_ROI{ii} = imboxfilt(prev_ROI{ii});
    cur_ROI{ii} = image_ud(dilated_bbox(ii,2):dilated_bbox(ii,2)+dilated_bbox(ii,4),dilated_bbox(ii,1):dilated_bbox(ii,1)+dilated_bbox(ii,3),:);
    cur_ROI{ii} = imboxfilt(cur_ROI{ii});
    prev_mask_ROI{ii} = prevMask{ii}(prev_bbox(ii,2):prev_bbox(ii,2)+prev_bbox(ii,4),prev_bbox(ii,1):prev_bbox(ii,1)+prev_bbox(ii,3));
    prev_mask_curROI{ii} = prevMask{ii}(dilated_bbox(ii,2):dilated_bbox(ii,2)+dilated_bbox(ii,4),dilated_bbox(ii,1):dilated_bbox(ii,1)+dilated_bbox(ii,3));
    prev_mask_dilate_ROI{ii} = prevMask_dilate(dilated_bbox(ii,2):dilated_bbox(ii,2)+dilated_bbox(ii,4),dilated_bbox(ii,1):dilated_bbox(ii,1)+dilated_bbox(ii,3));
    prev_im_relRGB{ii} = relativeRGB(prev_ROI{ii});
    prev_im_relRGB{ii} = imboxfilt(prev_im_relRGB{ii});
    im_relRGB{ii} = relativeRGB(cur_ROI{ii});
    relBG_ROI{ii} = relBG(dilated_bbox(ii,2):dilated_bbox(ii,2)+dilated_bbox(ii,4),dilated_bbox(ii,1):dilated_bbox(ii,1)+dilated_bbox(ii,3),:);
    frontPanelMask_ROI = frontPanelMask(dilated_bbox(ii,2):dilated_bbox(ii,2)+dilated_bbox(ii,4),dilated_bbox(ii,1):dilated_bbox(ii,1)+dilated_bbox(ii,3));
    
    BGdiff = imabsdiff(relBG_ROI{ii},im_relRGB{ii});
    BGdiffmag = sqrt(sum(BGdiff.^2,3));
    BGadjust = imadjust(BGdiffmag);
    BGthresh = graythresh(BGadjust);
    BGmask = imbinarize(BGadjust,BGthresh);%(BGdiffmag < BGthresh);
    
    % extract pixels classified as part of the paw in the previous frame
    % and find their mean values only if the paw was identified in the
    % previous frame. Otherwise, use the last valid mean normalized RGB
    % values
    if isPrevPawVisible(ii)
        pawPixels{ii} = zeros(sum(prev_mask_ROI{ii}(:)), 3);
        RGBdiffs{ii} = zeros(size(cur_ROI{ii}));
        for iRGB = 1 : 3
            ROI_temp = squeeze(prev_im_relRGB{ii}(:,:,iRGB));
            pawPixels{ii}(:,iRGB) = ROI_temp(prev_mask_ROI{ii});
        end
        meanRelColor(ii,:) = mean(pawPixels{ii});
    end
%     filt_relRGB = imboxfilt(im_relRGB{ii},5);
    for iRGB = 1 : 3
        % in the red or blue channels, if current values are smaller
        % than previous mean, set difference to zero. For green, if current
        % values are greater than previous mean, set difference to
        % zero. In this way, distance from the mean only counts as
        % being far from the previous blob in RGB space if it's in a
        % direction
        if iRGB == 2
%             RGBdiffs{ii}(:,:,iRGB) = max(-filt_relRGB(:,:,iRGB) + meanRelColor(ii,iRGB), 0);
            RGBdiffs{ii}(:,:,iRGB) = max(-im_relRGB{ii}(:,:,iRGB) + meanRelColor(ii,iRGB), 0);
        else
%             RGBdiffs{ii}(:,:,iRGB) = max(filt_relRGB(:,:,iRGB) - meanRelColor(ii,iRGB),0);
            RGBdiffs{ii}(:,:,iRGB) = max(im_relRGB{ii}(:,:,iRGB) - meanRelColor(ii,iRGB),0);
        end
    end
    
    % very crude thresholding to find pixels highly likely to be part of
    % the paw
%     thresh_img = sqrt(sum(RGBdiffs{ii}.^2,3));
    scaled_im = zeros([size(prev_mask_curROI{ii}),2]);
    sl = zeros(2,2);
    for jj = 1 : 2
        sl(:,jj) = stretchlim(im_relRGB{ii}(:,:,jj));
    end
    sl2 = zeros(2,1);
    sl2(1) = min(sl(1,:));
    sl2(2) = max(sl(2,:));
    for jj = 1 : 2
        scaled_im(:,:,jj) = imadjust(im_relRGB{ii}(:,:,jj),sl2,[]);
    end
    
    thresh_img = scaled_im(:,:,2) - scaled_im(:,:,1);
%     thresh_img = im_relRGB{ii}(:,:,2) - im_relRGB{ii}(:,:,1);
    l = graythresh(thresh_img);
    tempMask = thresh_img > l;
%     tempMask = thresh_img < diffThresh;
    
    drkmsk{ii} = true(size(tempMask));
    for jj = 1 : 3
        drkmsk{ii} = drkmsk{ii} & cur_ROI{ii}(:,:,jj) < darkThresh;
    end
    if ii == 2
        drkmsk{2} = drkmsk{2} & ~behindPanelMask;
    end
    tempMask = tempMask & ~drkmsk{ii};
    tempMask = tempMask & BGmask;
    tempMask = tempMask & prev_mask_dilate_ROI{ii};
    
    tempMask = processMask(tempMask,'sesize',2);
    if ii == 2
        intMask = intMask(dilated_bbox(ii,2):dilated_bbox(ii,2)+dilated_bbox(ii,4),dilated_bbox(ii,1):dilated_bbox(ii,1)+dilated_bbox(ii,3));
        testIn = intMask & tempMask;
        pawIn = false;
        if any(testIn(:))
            pawIn = true;
        end
        tempMask = tempMask & ~frontPanelMask_ROI;
    end
    
    newMask{ii} = false(h,w);
    newMask{ii}(dilated_bbox(ii,2):dilated_bbox(ii,2)+dilated_bbox(ii,4),dilated_bbox(ii,1):dilated_bbox(ii,1)+dilated_bbox(ii,3)) = tempMask;
    
end

fullMask = newMask;
if any(newMask{1}(:)) && any(newMask{2}(:))
    fullMask = maskProjectionBlobs(newMask,[1,1,w-1,h-1;1,1,w-1,h-1],fundMat,[h,w]);
end

% for ii = 1 : 2
%     fullMask{ii} = false(h,w);
%     fullMask{ii}(ROI(ii,2):ROI(ii,2)+ROI(ii,4),ROI(ii,1):ROI(ii,1)+ROI(ii,3)) = tempMask{ii};
%     fullMask{ii} = bwconvhull(fullMask{ii},'union');
% end
% frontPanelEdge = frontPanelEdge(ROI(2,2):ROI(2,2)+ROI(2,4),ROI(2,1):ROI(2,1)+ROI(2,3));
% frontPanelMask = frontPanelMask(ROI(2,2):ROI(2,2)+ROI(2,4),ROI(2,1):ROI(2,1)+ROI(2,3));
% extMask = extMask(ROI(2,2):ROI(2,2)+ROI(2,4),ROI(2,1):ROI(2,1)+ROI(2,3));
% intMask = intMask(ROI(2,2):ROI(2,2)+ROI(2,4),ROI(2,1):ROI(2,1)+ROI(2,3));
% shelfMask = shelfMask(ROI(1,2):ROI(1,2)+ROI(1,4),ROI(1,1):ROI(1,1)+ROI(1,3));

% for ii = 1 : 2
%     prevMask{ii} = prevMask{ii}(ROI(ii,2):ROI(ii,2)+ROI(ii,4),ROI(ii,1):ROI(ii,1)+ROI(ii,3));
% end


% % check the mirror view to see if the paw is passing through the front
% % panel (or at least getting close)
% prevMask_dilate = imdilate(prevMask{2},strel('disk',maxDistPerFrame));
% prevMask_panel_dilate = false(size(prevMask{2}));
% dil_mask = imdilate(prevMask{2},overlapCheck_SE_fromExt) & ~prevMask{2};    % look to see if the paw is at the outside edge of the front panel
% side_overlap_mask = dil_mask & frontPanelMask;
% prevExtMask = prevMask{2} & extMask;
% prevIntMask = prevMask{2} & intMask;
% if any(side_overlap_mask(:)) && any(prevExtMask(:)) && ~any(prevIntMask(:))   % only extend the masked region behind the front panel if the paw
%                                                                               % was entirely in the exterior region on the previous frame (there
%                                                                               % will already be part of the mask on the inside if part of the 
%                                                                               % previous paw detection was inside the box)
%     prevMask_panel_dilate = imdilate(prevMask_panel_dilate, SE_fromExt);
%     SE = strel('line',10,90);
%     prevMask_panel_dilate = imdilate(prevMask_panel_dilate, SE);
% end
% 
% dil_mask = imdilate(prevMask{2},overlapCheck_SE_fromInt) & ~prevMask{2};    % look to see if the paw is at the outside edge of the front panel
% side_overlap_mask = dil_mask & frontPanelMask;
% if any(side_overlap_mask(:)) && any(prevIntMask(:)) && ~any(prevExtMask(:))
%     prevMask_panel_dilate = imdilate(prevMask_panel_dilate, SE_fromInt);
%     SE = strel('line',10,90);
%     prevMask_panel_dilate = imdilate(prevMask_panel_dilate, SE);
% end
% 
% 
% im_ud_views = cell(1,2);
% rel_im_views = cell(1,2);
% rel_im_dstr = cell(1,2);
% grnmsk = cell(1,2);
% drkmsk = cell(1,2);
% for ii = 1 : 2
%     im_ud_views{ii} = image_ud(ROI(ii,2):ROI(ii,2)+ROI(ii,4),ROI(ii,1):ROI(ii,1)+ROI(ii,3),:);
%     rel_im_views{ii} = relativeRGB(im_ud_views{ii});
%     rel_im_dstr{ii} = decorrstretch(rel_im_views{ii},'tol',0.01);
%     
%     grnmsk{ii} = rel_im_dstr{ii}(:,:,2) > gThresh;
%     grnmsk{ii} = grnmsk{ii} & rel_im_dstr{ii}(:,:,1) < rThresh;
%     grnmsk{ii} = grnmsk{ii} & rel_im_dstr{ii}(:,:,3) < bThresh;
%     
%     drkmsk{ii} = true(size(grnmsk{ii}));
%     for jj = 1 : 3
%         drkmsk{ii} = drkmsk{ii} & im_ud_views{ii}(:,:,jj) < darkThresh;
%     end
% 
%     grnmsk{ii} = grnmsk{ii} & ~drkmsk{ii};
%     
% end
% rel_im = relativeRGB(image_ud);
% 
% rel_im_dstr = decorrstretch(rel_im,'tol',0.01);

% grnmsk = rel_im_dstr(:,:,2) > gThresh;
% grnmsk = grnmsk & rel_im_dstr(:,:,1) < rThresh;
% grnmsk = grnmsk & rel_im_dstr(:,:,3) < bThresh;
% drkmsk = true(h,w);
% for ii = 1 : 3
%     drkmsk = drkmsk & image_ud(:,:,ii) < 0.05;
% end

% grnmsk = grnmsk & ~drkmsk;
% mirror_grnmsk = grnmsk{2};%grnmsk(ROI(2,2):ROI(2,2)+ROI(2,4),ROI(2,1):ROI(2,1)+ROI(2,3));
% direct_grnmsk = grnmsk{1};%grnmsk(ROI(1,2):ROI(1,2)+ROI(1,4),ROI(1,1):ROI(1,1)+ROI(1,3));
% 
% 
% 
% 
% 
% % exclude everything in the mirror view not close enough to the previous
% % mask
% mirror_grnmsk = mirror_grnmsk & (prevMask_dilate | prevMask_panel_dilate);
% 
% 
% behindPanelMask = mirror_grnmsk & intMask;
% % figure out if the paw is passing behind the shelf in the direct view (or
% % about to)
% prevMask_dilate = imdilate(prevMask{1},strel('disk',maxDistPerFrame));
% dil_mask = imdilate(prevMask{1},strel('line',10,90)) | imdilate(prevMask{1},strel('line',10,270));
% shelf_overlap_mask = dil_mask & shelfMask;
% if any(shelf_overlap_mask(:)) && any(behindPanelMask(:))   % previous paw mask is very close to the shelf
%                                 % AND the paw is behind the front panel
%                                 % therefore, check the other side of the
%                                 % shelf to see if the paw shows
%                                 % up there
%     SE = strel('rectangle',[shelfThick + 50, 10]);
%     prevMask_panel_dilate = imdilate(prevMask{1}, SE);
% else
%     prevMask_panel_dilate = false(size(prevMask{1}));
% end
% 
% direct_grnmsk = direct_grnmsk & (prevMask_dilate | prevMask_panel_dilate);
% 
% tempMask = cell(1,2);
% tempMask{2} = processMask(mirror_grnmsk,'sesize',2);
% tempMask{1} = processMask(direct_grnmsk,'sesize',2);
% 
% if any(tempMask{1}(:)) && any(tempMask{2}(:))
%     tempMask = maskProjectionBlobs(tempMask,ROI(1:2,:),fundMat,[h,w]);
% end
% for ii = 1 : 2
%     fullMask{ii} = false(h,w);
%     fullMask{ii}(ROI(ii,2):ROI(ii,2)+ROI(ii,4),ROI(ii,1):ROI(ii,1)+ROI(ii,3)) = tempMask{ii};
%     fullMask{ii} = bwconvhull(fullMask{ii},'union');
% end
% 
% 
