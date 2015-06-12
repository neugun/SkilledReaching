function digitMask = identifyMirrorDigits(digitImg, rat_metadata, varargin)
%
% usage
%
% INPUTS:
%   digitImg - rgb masked image of paw in the relevant mirror. Seems to
%       work better if decorrstretched first to enhance color contrast
%   pawMask - black/white paw mask. easier to include this as an input than
%       extract from digitImg; if decorrstretch has been performed,
%       backgound isn't necessarily zero
%   rat_metadata - needed to know whether to look to the left or right of
%       the dorsal aspect of the paw to exclude points that can't be digits
%
% VARARGS:
%
% OUTPUTS:
%   digitMask - m x n x 5 matrix, where each m x n matrix contains a mask
%       for a part of the paw. 1st row - dorsum of paw, 2nd through 5th
%       rows are each digit from index finger to pinky

% WORKING HERE - NEED TO ADJUST THE VALUES TO ENHANCE THE DESIRED PAW BITS
decorrStretchMean  = [100.0 100.0 127.5     % to isolate dorsum of paw
                      100.0 127.5 100.0     % to isolate blue digits
                      100.0 127.5 100.0     % to isolate red digits
                      127.5 127.5 127.5     % to isolate green digits
                      100.0 127.5 100.0];   % to isolate red digits
decorrStretchSigma = [050 025 050       % to isolate dorsum of paw
                      025 025 025       % to isolate blue digits
                      025 025 025       % to isolate red digits
                      025 025 025       % to isolate green digits
                      025 025 025];     % to isolate red digits

hsv_digitBounds = [0.33 0.33 0.00 0.90 0.00 0.90
                   0.67 0.16 0.90 1.00 0.80 1.00
                   0.00 0.16 0.90 1.00 0.80 1.00
                   0.33 0.16 0.90 1.00 0.90 1.00
                   0.00 0.16 0.90 1.00 0.80 1.00];
rgb_digitBounds = [0.00 0.40 0.10 0.50 0.60 1.00
                   0.00 0.10 0.00 0.60 0.80 1.00
                   0.90 1.00 0.00 0.40 0.00 0.40
                   0.33 0.16 0.90 1.00 0.90 1.00
                   0.00 0.16 0.90 1.00 0.80 1.00];

for iarg = 1 : 2 : nargin - 2
    switch lower(varargin{iarg})
        case digitBounds,
            hsv_digitBounds = varargin{iarg + 1};
    end
end

pawDorsumBlob = vision.BlobAnalysis;
pawDorsumBlob.AreaOutputPort = true;
pawDorsumBlob.CentroidOutputPort = true;
pawDorsumBlob.BoundingBoxOutputPort = true;
pawDorsumBlob.ExtentOutputPort = true;
pawDorsumBlob.LabelMatrixOutputPort = true;
pawDorsumBlob.MinimumBlobArea = 1000;

digitBlob = vision.BlobAnalysis;
digitBlob.AreaOutputPort = true;
digitBlob.CentroidOutputPort = true;
digitBlob.BoundingBoxOutputPort = true;
digitBlob.ExtentOutputPort = true;
digitBlob.LabelMatrixOutputPort = true;
digitBlob.MinimumBlobArea = 50;
digitBlob.MaximumBlobArea = 500;

% 1st row masks the dorsum of the paw
% next 4 rows mask the digits
pawMask = (rgb2gray(digitImg) > 0);
s = regionprops(pawMask,'area','centroid');
wholePawCentroid = s.Centroid;
wholePawArea     = s.Area;      % this might be useful to set minimum and maximum digit/paw dorsum sizes as a function of the total paw size


digitMask = zeros(size(digitImg,1), size(digitImg,2), size(hsv_digitBounds,1));
SE = strel('disk',2);
digitCtr = zeros(size(hsv_digitBounds,1), 2);
rgb_enh = zeros(size(hsv_digitBounds,1), size(digitImg,1),size(digitImg,2),size(digitImg,3));
for ii = 1 : size(hsv_digitBounds, 1)
    
    % CREATE THE ENHANCED IMAGE DEPENDING ON ii BEFORE DOING ANYTHING ELSE
    rgb_enh(ii,:,:,:)  = enhanceColorImage(digitImg, ...
                                           decorrStretchMean(ii,:), ...
                                           decorrStretchSigma(ii,:), ...
                                           'mask',pawMask);
end
% mask out the purple and red digits first
idxMask = squeeze(rgb_enh(2,:,:,1)) >= rgb_digitBounds(2,1) & ...
          squeeze(rgb_enh(2,:,:,1)) <= rgb_digitBounds(2,2) & ...
          squeeze(rgb_enh(2,:,:,2)) >= rgb_digitBounds(2,3) & ...
          squeeze(rgb_enh(2,:,:,2)) <= rgb_digitBounds(2,4) & ...
          squeeze(rgb_enh(2,:,:,3)) >= rgb_digitBounds(2,5) & ...
          squeeze(rgb_enh(2,:,:,3)) <= rgb_digitBounds(2,6);
idxMask = bwdist(idxMask) < 2;
idxMask = imopen(idxMask, SE);
idxMask = imclose(idxMask, SE);
idxMask = imfill(idxMask, 'holes');
[~,idx_c,~,~,idxLabMask] = step(digitBlob, idxMask);
% index finger must be to the right of the whole paw centroid
if strcmpi(rat_metadata.pawPref,'right')    % back of paw in the left mirror
    % looking in the left mirror for the digits
    validIdx = find(idx_c(:,1) > wholePawCentroid(1));
else
    % looking in the right mirror for the digits
    validIdx = find(idx_c(:,1) < wholePawCentroid(1));
end
idxMask = false(size(idxMask));
for ii = 1 : length(validIdx)
    idxMask = idxMask | (idxLabMask == validIdx(ii));
end
[idx_A,~,~,~,idxLabMask] = step(digitBlob, idxMask);
validIdx = find(idx_A == max(idx_A));
idxMask = (idxLabMask == validIdx);

mpMask  = squeeze(rgb_enh(3,:,:,1)) >= rgb_digitBounds(3,1) & ...
          squeeze(rgb_enh(3,:,:,1)) <= rgb_digitBounds(3,2) & ...
          squeeze(rgb_enh(3,:,:,2)) >= rgb_digitBounds(3,3) & ...
          squeeze(rgb_enh(3,:,:,2)) <= rgb_digitBounds(3,4) & ...
          squeeze(rgb_enh(3,:,:,3)) >= rgb_digitBounds(3,5) & ...
          squeeze(rgb_enh(3,:,:,3)) <= rgb_digitBounds(3,6);
mpMask = bwdist(mpMask) < 2;
mpMask = imopen(mpMask, SE);
mpMask = imclose(mpMask, SE);
mpMask = imfill(mpMask, 'holes');
[~,mp_c,~,~,mpLabMask] = step(digitBlob, mpMask);
% fingers must be to the right of the whole paw centroid
if strcmpi(rat_metadata.pawPref,'right')    % back of paw in the left mirror
    % looking in the left mirror for the digits
    validIdx = find(mp_c(:,1) > wholePawCentroid(1));
else
    % looking in the right mirror for the digits
    validIdx = find(mp_c(:,1) < wholePawCentroid(1));
end
mpMask = false(size(mpMask));
for ii = 1 : length(validIdx)
    mpMask = mpMask | (mpLabMask == validIdx(ii));
end
[mp_A,~,~,~,mpLabMask] = step(digitBlob, mpMask);
% take the two largest remaining blobs as the middle and pinky digits
[~, sortIdx] = sort(mp_A);
sortIdx = sortIdx(end-1:end);
mpMask = false(size(mpMask));
for ii = 1 : 2
    mpMask = mpMask | (mpLabMask == sortIdx(ii));
end

% now identify the dorsum of the paw as everything on the opposite side of
% a line connecting the base of the index finger and pinky compared to the
% digit centroids
% start by finding the convex hull around the digits masked out thus far -
% this isn't as easy as it sounds... WORKING HERE...
% draw lines between the centroids of each digit
digitMask = mpMask | idxMask;
s = regionprops(digitMask,'boundingbox','conveximage');
[~,centroids,~,~,~] = step(digitBlob, digitMask);
digLine
for ii = 1 : length(centroids) - 1
    for jj = ii + 1 : length(centroids)
        lftCentroid = round(min(centroids(ii,1),centroids(jj,1)));
        rgtCentroid = round(max(centroids(ii,1),centroids(jj,1)));
        topCentroid = round(min(centroids(ii,2),centroids(jj,2)));
        botCentroid = round(max(centroids(ii,2),centroids(jj,2)));
        x = lftCentroid : rgtCentroid;
        m = (centroids(ii,2)-centroids(jj,2)) / (centroids(ii,1)-centroids(jj,1));
        b = centroids(ii,2) - m * centroids(ii,1);
        lineMap = zeros(botCentroid-topCentroid-1, length(x));
        lineMask = false(size(digitMask));
        for kk = 1 : size(lineMap,2)
            lineMap(kk,:) = m * x + b - (kk + topCentroid - 1);
        end
        
        lineMask(topCentroid:botCentroid,lftCentroid:rgtCentroid) = (abs(lineMask < 0.5));
    end
end
        
% digitMask = 
pdMask  = squeeze(rgb_enh(1,:,:,1)) >= rgb_digitBounds(1,1) & ...
          squeeze(rgb_enh(1,:,:,1)) <= rgb_digitBounds(1,2) & ...
          squeeze(rgb_enh(1,:,:,2)) >= rgb_digitBounds(1,3) & ...
          squeeze(rgb_enh(1,:,:,2)) <= rgb_digitBounds(1,4) & ...
          squeeze(rgb_enh(1,:,:,3)) >= rgb_digitBounds(1,5) & ...
          squeeze(rgb_enh(1,:,:,3)) <= rgb_digitBounds(1,6); 
for ii = 1 : size(hsv_digitBounds, 1)
    tempMask = squeeze(rgb_enh(ii,:,:,1)) >= rgb_digitBounds(ii,1) & ...
               squeeze(rgb_enh(ii,:,:,1)) <= rgb_digitBounds(ii,2) & ...
               squeeze(rgb_enh(ii,:,:,2)) >= rgb_digitBounds(ii,3) & ...
               squeeze(rgb_enh(ii,:,:,2)) <= rgb_digitBounds(ii,4) & ...
               squeeze(rgb_enh(ii,:,:,3)) >= rgb_digitBounds(ii,5) & ...
               squeeze(rgb_enh(ii,:,:,3)) <= rgb_digitBounds(ii,6);
           % WORKING HERE - WHAT HAPPENS IF WE PULL OUT THE PURPLE AND RED
           % DIGITS FIRST, SINCE THEY SHOW UP PRETTY ROBUSTLY?
           
           
%     tempMask = double(HSVthreshold(hsv_digitImg, hsv_digitBounds(ii,:)));
    tempMask = tempMask & (rgb2gray(digitImg) > 0);
    tempMask = bwdist(tempMask) < 2;
    tempMask = imopen(tempMask, SE);
    if ii ~= 3 && ii ~=5    % this can put the two red digits in contact and screw up the analysis
        tempMask = imclose(tempMask, SE);
    end
    tempMask = imfill(tempMask, 'holes');
    if ii == 1    % masking out the dorsum of the paw
        % keep only the largest region
        [paw_a, ~, ~, ~, pawLabMat] = step(pawDorsumBlob,tempMask);
        maxRegionIdx = find(paw_a == max(paw_a));
        tempMask = (pawLabMat == maxRegionIdx);
        % fill in the convex hull
        s = regionprops(tempMask,'boundingbox','conveximage');
        x_w = size(s.ConvexImage,1);
        y_w = size(s.ConvexImage,2);
        x_maskBorders = round([s.BoundingBox(2),s.BoundingBox(2)+x_w-1]);
        y_maskBorders = round([s.BoundingBox(1),s.BoundingBox(1)+y_w-1]);
        tempMask2 = false(size(tempMask));
        tempMask2(x_maskBorders(1):x_maskBorders(2),y_maskBorders(1):y_maskBorders(2)) = s.ConvexImage;
        [~, digitCtr(ii,:), ~, ~, paw_labMat] = step(pawDorsumBlob,tempMask2);
        tempMask = (paw_labMat > 0);
    else
        % use the coordinates of the dorsum of the paw to help identify
        % which digit is which. needed because orange and red look so much
        % alike
        % first, exclude any points labeled as the dorsal aspect of the paw
        % from the digits
        tempMask = logical(tempMask .* ~squeeze(digitMask(:,:,1)));
        [~, digit_c, ~, ~, digitLabMat] = step(digitBlob, tempMask);
        % first, eliminate blobs that are on the wrong side of the paw
        % centroid (to the left if looking in the left mirror, to the right
        % if looking in the right mirror).
        if strcmpi(rat_metadata.pawPref,'right')    % back of paw in the left mirror
            % looking in the left mirror for the digits
            digitIdx = find(digit_c(:,1) < digitCtr(1));
        else
            % looking in the right mirror for the digits
            digitIdx = find(digit_c(:,1) > digitCtr(1));
        end
        if ~isempty(digitIdx)
            for jj = 1 : length(digitIdx)
                digitLabMat(digitLabMat == digitIdx(jj)) = 0;
            end
            tempMask = (digitLabMat > 0);
        end
        [~, digit_c, ~, ~, digitLabMat] = step(digitBlob, tempMask);
        tempMask = (digitLabMat > 0);
        % incorporate an extent condition for digits here?
        
        % now, take the blob that is closest to the previous digit & below
        % it. Can't do this for the first digit
        if ii > 2
            % get rid of any blobs whose centroid is above the previous
            % digit centroid
            digitIdx = find(digit_c(:,2) < digitCtr(ii-1,2));
            if ~isempty(digitIdx)
                for jj = 1 : length(digitIdx)
                    digitLabMat(digitLabMat == digitIdx(jj)) = 0;
                end
                tempMask = (digitLabMat > 0);
            end
            [~, digit_c, ~, ~, digitLabMat] = step(digitBlob, tempMask);
            % now, take the blob closest to the previous digit
            digitDist = zeros(size(digit_c,1),2);
            digitDist(:,1) = digitCtr(ii-1,1) - digit_c(:,1);
            digitDist(:,2) = digitCtr(ii-1,2) - digit_c(:,2);
            digitDistances = sum(digitDist.^2,2);
            minDistIdx = find(digitDistances == min(digitDistances));
            tempMask = (digitLabMat == minDistIdx);
            [~, digit_c, ~, ~, ~] = step(digitBlob, tempMask);
        elseif size(digit_c,1) > 1
            % take the centroid closest to the dorsum of the paw if this is
            % the first digit identified
            x_dist = digit_c(:,1) - digitCtr(1,1);
            y_dist = digit_c(:,2) - digitCtr(1,2);
            dist_from_paw = x_dist.^2 + y_dist.^2;
            minDistIdx = find(dist_from_paw == min(dist_from_paw));
            tempMask = (digitLabMat == minDistIdx);
            [~, digit_c, ~, ~, ~] = step(digitBlob, tempMask);
            % NOTE, NOT SURE IF THIS WILL BE ROBUST - COULD GET BLOBS
            % CLOSER TO THE PAW CENTROID THAN THE DIGITS - DL 20150609
        end    % if ii > 2
        digitCtr(ii,:) = digit_c;
    end
        
    digitMask(:,:,ii) = tempMask;
end


% find the centroids of the digits

end