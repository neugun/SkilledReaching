function np = findNearestPointOnLine(Q1,Q2,Q0)
%
% find the point on a line specified by Q1 and Q2 that is closest to Q0
%
% INPUTS:
%   Q1,Q2 - (x,y) or (x,y,z) coordinates of two points that specify the
%       line
%   Q0  - (x,y) or (x,y,z) coordinates of the point to which we want to
%       find the closest point on the line specified by Q1 and Q2
%
% OUTPUTS:
%

if size(Q1,1) == length(Q1)
    Q1 = Q1';
end
if size(Q2,1) == length(Q2)
    Q2 = Q2';
end
if size(Q1,1) == length(Q1)
    Q0 = Q0';
end

if length(Q1) ~= length(Q2) || ...
   length(Q2) ~= length(Q0)
   error('vectors must be the same length')
end

% 2D or 3D case
if length(Q1) == 2
    np = find2Dpoint(Q1,Q2,Q0);
elseif length(Q1) == 3
    np = find3Dpoint(Q1,Q2,Q0);
else
    error('must be 2D or 3D points')
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function np = find2Dpoint(Q1,Q2,Q0)
% 2D case

np = zeros(1,2);
if Q1(1) == Q2(1)
    np(1) = Q1(1);
    np(2) = Q0(2);
    return;
elseif Q1(2) == Q2(2)
    np(1) = Q0(1);
    np(2) = Q1(2);
    return;
end

m1 = (Q2(2)-Q1(2)) / (Q2(1) - Q1(1));
m2 = -1/m1;

np(1) = (m1*Q1(1) - m2*Q0(1) + Q0(2) - Q1(2)) / (m1-m2);
np(2) = m2 * (np(1) - Q0(1)) + Q0(2);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function np = find3Dpoint(Q1,Q2,Q0)
    
end