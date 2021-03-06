function [endMasks, tangentPoints] = matchSilhouettes(initMasks, ...
                                                      fundmat, ...
                                                      bboxes, ...
                                                      imSize, ...
                                                      fullPawMasks, ...
                                                      digitMasks, ...
                                                      possObscuredMatrix, ...
                                                      currentDigitIdx)    % could also be the paw dorsum
%
% INPUTS:
%   initMasks - 1x2 cell array where each cell contains the mask within the
%       bounding box of the object for each view (1 = direct, 2 = mirror)
%   fundmat - 
%   bboxes - 
%   imSize - 2-element vector, height by width
%   fullPawMasks - 
%   digitMasks - 
%
% OUTPUTS:
%   endMasks - 
%   tangentPoints - 

tangentPoints = zeros(2,2,2);    % mxnxp where m is number of points, n is (x,y), p is the view index (1 for direct, 2 for mirror)
tangentLines = zeros(2,3,2);     % mxnxp where m is number of points, n is (A,B,C), p is the view index (1 for direct, 2 for mirror)
epiPts = zeros(2,4,2);           % mxnxp where m is number of points, n is (x1,y1,x2,y2), p is the view index (1 for direct, 2 for mirror)
matchLineIdx = zeros(2,2);       % mxn where m is upper vs lower line (idx 1 for upper, 2 for lower), n is the view idx (1 = direct, 2 = mirror)

interiorMask = zeros(1,2);       % first element is whether the direct or mirror (1 or 2 respectively) views are intersected by the other view's upper tangent line;
                                 % second element is whether the direct or mirror (1 or 2 respectively) views are intersected by the other view's lower tangent line
mask_ext = cell(1,2);
ext_pts = cell(1,2);
endMasks = cell(1,2);

for iView = 1 : 2
    endMasks{iView} = initMasks{iView};
    mask_ext{iView} = bwmorph(initMasks{iView},'remove');
    
    [y,x] = find(mask_ext{iView});
    s = regionprops(mask_ext{iView},'Centroid');
    ext_pts{iView} = sortClockWise(s.Centroid,[x,y]);
    ext_pts{iView} = bsxfun(@plus,ext_pts{iView}, bboxes(iView,1:2)-1);
end

[tangentPoints(:,:,1), tangentLines(:,:,1)] = findTangentToEpipolarLine(initMasks{1}, fundmat, bboxes(1,:));
[tangentPoints(:,:,2), tangentLines(:,:,2)] = findTangentToEpipolarLine(initMasks{2}, fundmat', bboxes(2,:));

for iView = 1 : 2
    epiPts(:,:,iView) = lineToBorderPoints(tangentLines(:,:,iView), imSize);
    matchLineIdx(1,iView) = find(epiPts(:,2,iView) == min(epiPts(:,2,iView)));
    matchLineIdx(2,iView) = find(epiPts(:,2,iView) == max(epiPts(:,2,iView)));
    
    temp1 = tangentLines(matchLineIdx(1,iView),:,iView);
    temp2 = tangentLines(matchLineIdx(2,iView),:,iView);
    
    tangentLines(1,:,iView) = temp1;
    tangentLines(2,:,iView) = temp2;
    
    temp1 = tangentPoints(matchLineIdx(1,iView),:,iView);
    temp2 = tangentPoints(matchLineIdx(2,iView),:,iView);
    
    tangentPoints(1,:,iView) = temp1;
    tangentPoints(2,:,iView) = temp2;
    
    temp1 = epiPts(matchLineIdx(1,iView),:,iView);
    temp2 = epiPts(matchLineIdx(2,iView),:,iView);
    
    epiPts(1,:,iView) = temp1;
    epiPts(2,:,iView) = temp2;
end

% for iView = 1 : 2
iView = 1;
    otherViewIdx = 3 - iView;
    for ii = 1 : 2    % upper and lower tangent lines for each view

    %     lineValue = tangentLines(matchLineIdx(ii,iView),1,iView) * ext_pts{otherViewIdx}(:,1) + ...
    %                 tangentLines(matchLineIdx(ii,iView),2,iView) * ext_pts{otherViewIdx}(:,2) + ...
    %                 tangentLines(matchLineIdx(ii,iView),3,iView);

        lineValue = tangentLines(ii,1,iView) * ext_pts{otherViewIdx}(:,1) + ...
                    tangentLines(ii,2,iView) * ext_pts{otherViewIdx}(:,2) + ...
                    tangentLines(ii,3,iView);

        [intersect_idx, isLocalExtremum] = detectCircularZeroCrossings(lineValue);
        switch length(intersect_idx)
            case 0,    % this tangent line from one view does not intersect the blob in the other view
                interiorMask(ii) = otherViewIdx;
            otherwise,
                if all(isLocalExtremum(intersect_idx))
                    % this tangent line from one view is also a tangent line in the other view
                    interiorMask(ii) = 0;
                else    % this tangent line from one view cuts through the blob in the other view
                    interiorMask(ii) = iView;
                end
        end

        if interiorMask(ii)   % figure out where to extend the "interior mask" to
            exteriorMask = 3 - interiorMask(ii);
            % expand the mask of the non-intersected region until the tangent lines
            % meet
            % find the point in the mask closest to the tangent line
    %         linePts = reshape(squeeze(epiPts(matchLineIdx(ii),:,3-interiorMask(ii))),[2,2])';
            linePts = reshape(squeeze(epiPts(ii,:,exteriorMask)),[2,2])';
            % need to find mask of the region that does not contain any of
            % the other digits that could be obscuring the present one, but
            % is windowed out in the initial background subtraction
            poss_silhouette_region = fullPawMasks(:,:,interiorMask(ii));
            for iDigit = 1 : 5
                if ~possObscuredMatrix(currentDigitIdx, iDigit, exteriorMask)  && (iDigit ~= currentDigitIdx)
                    fullDigMask = false(imSize);
                    fullDigMask(bboxes(interiorMask(ii),2):bboxes(interiorMask(ii),2)+bboxes(interiorMask(ii),4), ...
                                bboxes(interiorMask(ii),1):bboxes(interiorMask(ii),1)+bboxes(interiorMask(ii),3)) = ...
                                    digitMasks{interiorMask(ii)}(:,:,iDigit);
                    shadowMask = findShadowRegion(fullDigMask, squeeze(tangentPoints(ii,:,interiorMask(ii))));
                    poss_silhouette_region = poss_silhouette_region & ~fullDigMask & ~shadowMask;
                end
            end
            
            lineMask = lineMaskOverlap(poss_silhouette_region, tangentLines(ii,:,exteriorMask),'distthresh', 1);
            [y,x] = find(lineMask);
            [~,nnidx] = findNearestNeighbor(squeeze(tangentPoints(ii,:,interiorMask(ii))), [x,y]);
%             [~, nearestPtIdx] = findNearestPointToLine(linePts,ext_pts{interiorMask(ii)});
%             np = round(findNearestPointOnLine(linePts(1,:),linePts(2,:),ext_pts{interiorMask(ii)}(nearestPtIdx,:)));
            np = [x(nnidx),y(nnidx)];
            tangentPoints(ii,:,interiorMask(ii)) = np - 1;

            % NOW NEED TO FIGURE OUT HOW TO MAKE SURE NO PART OF THE NEW
            % MASK PASSES THROUGH ANY PART OF A DIGIT THAT SHOULDN'T BE
            % OBSCURED IN THIS VIEW
            
            np = np - bboxes(interiorMask(ii),1:2);
            tempMask = false(size(endMasks{interiorMask(ii)}));
            tempMask(np(2),np(1)) = true;
            endMasks{interiorMask(ii)} = endMasks{interiorMask(ii)} | tempMask;
            endMasks{interiorMask(ii)} = bwconvhull(endMasks{interiorMask(ii)},'union');
            endMasks{interiorMask(ii)} = endMasks{interiorMask(ii)} | tempMask;   % sometimes finding the convex hull turns the new tangent point off again
%             endMasks{interiorMask(ii)} = multiRegionConvexHullMask(endMasks{interiorMask(ii)});
%             endMasks{interiorMask(ii)} = connectBlobs(endMasks{interiorMask(ii)});
        end
    end
% end

for iView = 1 : 2
    tangentPoints(:,:,iView) = bsxfun(@minus,tangentPoints(:,:,iView),bboxes(iView,1:2));
end

end