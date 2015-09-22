function tracks = reconstructPartiallyHiddenObjects(tracks, bboxes, fundMat, imSize, BG_mask, varargin)
%
% INPUTS:
%   tracks - 2-element cell array containing the masks of the object within
%       a bounding box in each view
%   bboxes - 2 x 4 array containing the bounding boxes of mask1 and mask2
%       within their larger images. (row 1--> mask 1, row 2 --> mask2)
%   fundMat is the fundamental matrix going from view 1 to view 2
%   imSize - 1 x 2 vector containing the height and width of the image
%   BG_mask - 1 x 3 cell array containing the background mask in the
%       center, dorsum mirror, and palm mirror, respectively. The mask only
%       contains the corresponding bounding boxes defined by bboxes
% VARARGs:
%   maxdistfromepipolarline - 
%
% OUTPUTS:
%   tracks - 

F = fundMat(:,:,1);    % from view 1 to view 2
maxDistFromEpipolarLine = 5;

for iarg = 1 : 2 : nargin - 5
    switch lower(varargin{iarg})
        case 'maxdistfromepipolarline',
            maxDistFromEpipolarLine = varargin{iarg + 1};
    end
end

obscuredPoints = identifyObscuredPoints(tracks, bboxes, F, imSize, maxDistFromEpipolarLine);

new_tracks = predictObscuredPoints(tracks(2:5), obscuredPoints, BG_mask, bboxes, imSize, F);

tracks(2:5) = new_tracks;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function obscuredPoints = identifyObscuredPoints(tracks, bboxes, F, imSize, maxDistFromEpipolarLine)
%
% INPUTS:
%   tracks - 
%   bboxes - 
%
% OUTUPUTS:
%   obscuredPoints - 4 x 3 x 2 boolean array (digit ID x prox vs centroid
%       vs distal point x 2 views)

obscuredPoints = false(length(tracks)-2, 3, 2);    % number of digits x 3 points per view x 2 views

for iTrack = 2 : length(tracks)-1    % start with the digits
    
    skipDigit = false;
    for iView = 1 : 2
        if ~tracks(iTrack).isvisible(iView)
            obscuredPoints(iTrack-1,:,iView) = true;
            skipDigit = true;
        end
    end
    if skipDigit; continue; end
    
    % calculate the distance from the epipolar lines for each proximal/
    % centroid/distal point to its image point
    centerDigitMarkers = tracks(iTrack).digitMarkers(:,:,1)';
    centerDigitMarkers(:,1) = centerDigitMarkers(:,1) + bboxes(1,1);
    centerDigitMarkers(:,2) = centerDigitMarkers(:,2) + bboxes(1,2);
    
    mirrorDigitMarkers = tracks(iTrack).digitMarkers(:,:,2)';
    mirrorDigitMarkers(:,1) = mirrorDigitMarkers(:,1) + bboxes(2,1);
    mirrorDigitMarkers(:,2) = mirrorDigitMarkers(:,2) + bboxes(2,2);
    center_epiLines = epipolarLine(F, centerDigitMarkers);
    mirror_epiLines = epipolarLine(F', mirrorDigitMarkers);
    
    center_epiPts = lineToBorderPoints(center_epiLines, imSize);
    mirror_epiPts = lineToBorderPoints(mirror_epiLines, imSize);
    d = zeros(3,2);
    center_pts1 = center_epiPts(:,1:2);
    center_pts2 = center_epiPts(:,3:4);
    
    mirror_pts1 = mirror_epiPts(:,1:2);
    mirror_pts2 = mirror_epiPts(:,3:4);
    center_test_pt = zeros(3,2);
    mirror_test_pt = zeros(3,2);
    for iMarker = 1 : 3   % proximal, centroid, distal
        
        center_test_pt(iMarker,:) = tracks(iTrack).digitMarkers(:,iMarker,1)';
        center_test_pt(iMarker,1) = center_test_pt(iMarker,1) + bboxes(1,1);
        center_test_pt(iMarker,2) = center_test_pt(iMarker,2) + bboxes(1,2);
        
        mirror_test_pt(iMarker,:) = tracks(iTrack).digitMarkers(:,iMarker,2)';
        mirror_test_pt(iMarker,1) = mirror_test_pt(iMarker,1) + bboxes(2,1);
        mirror_test_pt(iMarker,2) = mirror_test_pt(iMarker,2) + bboxes(2,2);
        d(iMarker,1) = distanceToLine(center_pts1(iMarker,:), ...
                                      center_pts2(iMarker,:), ...
                                      mirror_test_pt(iMarker,:));
        d(iMarker,2) = distanceToLine(mirror_pts1(iMarker,:), ...
                                      mirror_pts2(iMarker,:), ...
                                      center_test_pt(iMarker,:));
                                  
        if mean(d(iMarker,:)) > maxDistFromEpipolarLine
            % logic here is that if the epipolar line of one of the
            % identified points in one of the views intersects the digit 
            % mask in the other view, the mask containing the original
            % identified point is probably partially occluded. If, however,
            % the epipolar line does not intersect the mask in the other
            % view, the mask in the original view is probably complete
            maskIntersect = doesEpipolarLineIntersectMask(center_epiPts(iMarker,:), ...
                                                          mirror_epiPts(iMarker,:), ...
                                                          tracks(iTrack), ...
                                                          bboxes, ...
                                                          imSize);
                                                          
            if any(~maskIntersect)
                obscuredPoints(iTrack-1, iMarker, :) = ~maskIntersect;
            end
                                                       
        end
    end
    
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function maskIntersect = doesEpipolarLineIntersectMask(center_epiPts, ...
                                                       mirror_epiPts, ...
                                                       track, ...
                                                       bboxes, ...
                                                       imSize)
%
% INPUTS:
%   center_epiPts, mirror_epiPts - the points on the edge of the full mask
%       image defining the epipolar lines from each view
%   track - 
%   
% OUTPUTS:
%   maskIntersect - 1 x 2 boolean array indicating whether the epipolar
%       line from the center view point intersects the mirror mask (index
%       1) and/or the epipolar line from the mirror view point intersects
%       the direct view mask (index 2)

maskIntersect = false(1,2);

center_mask_edge = false(imSize);
mirror_mask_edge = false(imSize);

center_bbox_edge = bwmorph(track.digitmask1,'remove');
mirror_bbox_edge = bwmorph(track.digitmask2,'remove');

center_mask_edge(bboxes(1,2) : bboxes(1,2) + bboxes(1,4), ...
                 bboxes(1,1) : bboxes(1,1) + bboxes(1,3)) = center_bbox_edge;
mirror_mask_edge(bboxes(2,2) : bboxes(2,2) + bboxes(2,4), ...
                 bboxes(2,1) : bboxes(2,1) + bboxes(2,3)) = mirror_bbox_edge;

[center_y, center_x] = find(center_mask_edge);
[mirror_y, mirror_x] = find(mirror_mask_edge);

for ii = 1 : length(center_y)
    d = distanceToLine(center_epiPts(1:2), ...
                       center_epiPts(3:4), ...
                       [center_x(ii), center_y(ii)]);
	if d < 1
        maskIntersect(1) = true;
        break;
    end
end

for ii = 1 : length(mirror_y)
    d = distanceToLine(mirror_epiPts(1:2), ...
                       mirror_epiPts(3:4), ...
                       [mirror_x(ii), mirror_y(ii)]);
	if d < 1
        maskIntersect(1) = true;
        break;
    end
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function new_tracks = predictObscuredPoints(tracks, obscuredPoints, BG_mask, bboxes, imSize, F)
%
% INPUTS:
%
%
% OUTPUTS:
%
% predicted_points = zeros(size(obscuredPoints,1),...
%                          2, ...
%                          size(obscuredPoints,2),...
%                          size(obscuredPoints,3));

new_tracks = tracks;

for iDigit = 1 : size(obscuredPoints, 1)
    for iPoint = 1 : 3
        for iView = 1 : 2
            if obscuredPoints(iDigit,iPoint,iView)
                new_tracks(iDigit) = ...
                    predictObscuredPoint(tracks(iDigit),...
                                         iPoint,...
                                         iView,...
                                         BG_mask,...
                                         bboxes,...
                                         imSize,...
                                         F);
            end
        end
    end
end

end    % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function newTrack = predictObscuredPoint(track, iPoint, iView, BG_mask, bboxes, imSize, F)
% calculate the epipolar line from the non-obscured view of a point on a
% digit, then find the closest point within the background-subtracted mask
% to the "obscured" point

%   iPoint, iView - the indices of the point (prox, centroid, distal) and
%       view (1 = center, 2 = mirror) in which the partial oscuration
%       occurred
%   BG_mask - 
%   F - fundamental matrix going from direct view to paw dorsum mirror view
%

newTrack = track;

visiblePtIdx = 3 - iView;
visible_bbox = bboxes(3-iView,:);
obscured_bbox = bboxes(iView,:);
if iView == 1
    F = F';
end

visiblePt  = track.digitMarkers(:,iPoint,visiblePtIdx)';
obscuredPt = track.digitMarkers(:,iPoint,iView)';
visiblePt = visiblePt + visible_bbox(1:2);
obscuredPt = obscuredPt + obscured_bbox(1:2);

epiLine = epipolarLine(F, visiblePt);
epiPts  = lineToBorderPoints(epiLine, imSize);

predicted_point = findNearestPointOnLine(epiPts(1:2),epiPts(3:4),obscuredPt);

% make sure the predicted point is within the paw mask
paw_mask = false(imSize);
ptMask = false(imSize);
paw_mask(obscured_bbox(2) : obscured_bbox(2) + obscured_bbox(4),...
         obscured_bbox(1) : obscured_bbox(1) + obscured_bbox(3)) = BG_mask{iView};
ptMask(round(predicted_point(2)),round(predicted_point(1))) = true;
overlap = ptMask & paw_mask;

if ~any(overlap(:))    % predicted point is not within the paw mask
    paw_edge = bwmorph(paw_mask,'remove');
    [y, x] = find(paw_edge);
    [~,nnidx] = findNearestNeighbor(predicted_point,[x,y]);
    predicted_point = [x(nnidx),y(nnidx)];
end

newTrack.digitMarkers(:,iPoint,iView) = (predicted_point - obscured_bbox(1:2))';

end % function