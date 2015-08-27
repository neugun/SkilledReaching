function F = fundMatrixFromMatchedPoints(matchedPoints)
%
% usage: 
%
% INPUTS:
%   matchedPoints - m x 2 x n matrix, where m is the number of points, the
%       second dimension contains (x,y) coordinates, and n is the number of
%       views. Assumed that n = 1 --> left mirror, n = 2 --> left direct
%       view, n = 3 --> right direct view, n = 4 --> right mirror view

F.left  = estimateFundamentalMatrix(matchedPoints(:,:,2),matchedPoints(:,:,1),'method','norm8point');
F.right = estimateFundamentalMatrix(matchedPoints(:,:,3),matchedPoints(:,:,4),'method','norm8point');

end