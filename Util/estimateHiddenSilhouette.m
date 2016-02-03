function newMasks = estimateHiddenSilhouette(fullMasks,...
                                             bbox,...
                                             fundMat,...
                                             imSize)
                                         
%
% INPUTS:
%
% OUTPUTS:

h = imSize(1); w = imSize(2);

tangentPoints = zeros(2,2,2);    % mxnxp where m is number of points, n is (x,y), p is the view index (1 for direct, 2 for mirror)
tangentLines = zeros(2,3,2);     % mxnxp where m is number of points, n is (A,B,C), p is the view index (1 for direct, 2 for mirror)
epiPts = zeros(2,4,2);           % mxnxp where m is number of points, n is (x1,y1,x2,y2), p is the view index (1 for direct, 2 for mirror)
matchLineIdx = zeros(2,2);       % mxn where m is upper vs lower line (idx 1 for upper, 2 for lower), n is the view idx (1 = direct, 2 = mirror)
bpts = zeros(2,4,2);

projMask = cell(1,2);
newMasks = fullMasks;

for iView = 1 : 2
    if iView == 2
        F = fundMat';
    else
        F = fundMat;
    end
    [tangentPoints(:,:,iView), tangentLines(:,:,iView)] = ...
        findTangentToEpipolarLine(fullMasks{iView}, F, bbox(iView,:));
    % rearrange tangent points so that top one comes first in both views
    [~,idx] = sort(tangentPoints(:,2,iView));
    tangentPoints(:,:,iView) = tangentPoints(idx,:,iView);
    tangentLines(:,:,iView) = tangentLines(idx,:,iView);
    bpts(:,:,iView) = lineToBorderPoints(tangentLines(:,:,iView),imSize);
end

% now, check to see which mask extends higher above the other's projection,
% then find the one that extends below the other's projection
% find the top tangent point in each view

for iView = 1 : 2
    otherView = 3 - iView;
    for iLine = 1 : 2   % 1- top, 2 - bottom
        mask_x = [1,w,w,1,1];
        if iLine == 1
            mask_y = [1,1,bpts(iLine,4,iView),bpts(iLine,2,iView),1];
        else
            mask_y = [h,h,bpts(iLine,4,iView),bpts(iLine,2,iView),h];
        end
        nonProjMask = poly2mask(mask_x,mask_y,h,w);

        overlap_mask = fullMasks{otherView} & nonProjMask;

        if ~any(overlap_mask(:))    % otherView doesn't extend to the edge of the projection of iView, so need to extend it
            % find the point in nonProjMask closest to the current mask,
            % and add it to newMask in that view
            ext_nonProjMask = bwmorph(nonProjMask,'remove');
            ext_curMask = bwmorph(fullMasks{otherView},'remove');
            [y_np,x_np] = find(ext_nonProjMask);
            [y_cm,x_cm] = find(ext_curMask);
            
            [idx1,idx2] = nearestPointsInSets([x_np,y_np],[x_cm,y_cm]);
            
            newMasks{otherView}(y_np(idx1),x_np(idx1)) = true;
            newMasks{otherView} = bwconvhull(newMasks{otherView},'union');
            
        end
    end
    
end