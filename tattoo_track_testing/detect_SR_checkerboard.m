function [cb_pts] = detect_SR_checkerboard(I, varargin)
%
% usage: 

blackThresh = 60;
whiteThresh = 170;
areaLimits  = [1500 3500];
minExtent   = 0.8;
eccLimits   = [0 1];
maxSeparation = 100;

for iarg = 1 : 2 : nargin - 1
    switch lower(varargin{iarg})
        case 'blackthresh',
            blackThresh = varargin{iarg + 1};
        case 'whitethresh',
            whiteThresh = varargin{iarg + 1};
        case 'arealimits',
            areaLimits = varargin{iarg + 1};
    end
end

squareBlob = vision.BlobAnalysis;
squareBlob.AreaOutputPort = true;
squareBlob.CentroidOutputPort = true;
squareBlob.BoundingBoxOutputPort = true;
squareBlob.EccentricityOutputPort = true;
squareBlob.ExtentOutputPort = true;
squareBlob.LabelMatrixOutputPort = true;
squareBlob.MinimumBlobArea = areaLimits(1);   % eliminate everything that is too small
squareBlob.MaximumBlobArea = areaLimits(2);   % or too big

gray_I = rgb2gray(I);
% first, find the outline of the checkerboard
% threshold to find the black squares
blackSquareMask = gray_I < blackThresh;

SE = strel('disk',2);
blackSquareMask = imopen(blackSquareMask,SE);
blackSquareMask = imclose(blackSquareMask,SE);
blackSquareMask = imfill(blackSquareMask,'holes');
        
[blackSquareArea,blackSquareCent, blackSquarebbox, blackSquareEccentricity,blackSquareExtent,blackSquareLabelMatrix] = step(squareBlob,blackSquareMask);

% check that the extent (area/area of bounding box)of each region is
% large enough
validExtentIdx = find(blackSquareExtent > minExtent);
blackSquareMask = false(size(gray_I));
for ii = 1 : length(validExtentIdx)
    blackSquareMask = blackSquareMask | (blackSquareLabelMatrix == validExtentIdx(ii));
end
[blackSquareArea,blackSquareCent, blackSquarebbox, blackSquareEccentricity,blackSquareExtent,blackSquareLabelMatrix] = step(squareBlob,blackSquareMask);
% check that the eccentricity is in the appropriate range. Excludes, for
% example, vertical or horizontal lines that might not be captured by the
% Extent constraint above
validEccentricityIdx = find(blackSquareEccentricity > eccLimits(1) & blackSquareEccentricity < eccLimits(2));
for ii = 1 : length(validEccentricityIdx)
    blackSquareMask = blackSquareMask | (blackSquareLabelMatrix == validEccentricityIdx(ii));
end
[blackSquareArea,blackSquareCent, blackSquarebbox, blackSquareEccentricity,blackSquareExtent,blackSquareLabelMatrix] = step(squareBlob,blackSquareMask);

% find the minimum quadrilateral that will bound the black squares
% first, find the convex hull for each square
props = regionprops(blackSquareMask,'convexhull');
hullPoints = props(1).ConvexHull;
for ii = 1 : length(props)
    hullPoints = [hullPoints;props(ii).ConvexHull];
end

[qx,qy,quadarea] = minboundquad(hullPoints(:,1),hullPoints(:,2));







% now, throw out blobs that are too far away from the other blobs
[nn, meansep] = nearestNeighbor(blackSquareCent);
% at this point, should have the black squares isolated pretty well

whiteSquareMask = gray_I > whiteThresh;
SE = strel('disk',2);
whiteSquareMask = imopen(whiteSquareMask,SE);
whiteSquareMask = imclose(whiteSquareMask,SE);
whiteSquareMask = imfill(whiteSquareMask,'holes');
[whiteSquareArea,whiteSquareCent, whiteSquarebbox, whiteSquareEccentricity,whiteSquareExtent,whiteSquareLabelMatrix] = step(squareBlob,whiteSquareMask);

% check that the extent (area/area of bounding box)of each region is
% large enough
% validExtentIdx = find(whiteSquareExtent > minExtent);
% whiteSquareMask = false(size(gray_I));
% for ii = 1 : length(validExtentIdx)
%     whiteSquareMask = whiteSquareMask | (whiteSquareLabelMatrix == validExtentIdx(ii));
% end
% [whiteSquareArea,whiteSquareCent, whiteSquarebbox, whiteSquareEccentricity,whiteSquareExtent,whiteSquareLabelMatrix] = step(squareBlob,whiteSquareMask);
% now, throw out blobs that are too far away from the other blobs
[nn, meansep] = nearestNeighbor(whiteSquareCent);

figure(4);imshow(blackSquareMask);
figure(5);imshow(double(blackSquareLabelMatrix)/length(blackSquareArea));
figure(6);imshow(whiteSquareMask);
figure(7);imshow(double(whiteSquareLabelMatrix)/length(whiteSquareArea));
end