function srCal = sr_calibration(x1_left,x2_left,x1_right,x2_right, varargin)
%
% performs skilled reaching box calibration (calculates fundamental
% matrices, essential matrices, and camera matrices for each session for
% both the right and left mirrors)
%
% INPUTS:
%
% OUTPUTS:
%
computeCamParams = false;
camParamFile = '/Users/dleventh/Documents/Leventhal_lab_github/SkilledReaching/Manual Tracking Analysis/ConvertMarkedPointsToReal/cameraParameters.mat';
cb_path = '/Users/dleventh/Documents/Leventhal_lab_github/SkilledReaching/tattoo_track_testing/intrinsics calibration images';
% cb_path is to checkerboard patterns for computing the camera parameters

for iarg = 1 : 2 : nargin - 4
    switch lower(varargin{iarg})
        case 'computecamparams',
            computeCamParams = varargin{iarg};
        case 'camparamfile',
            camParamFile = varargin{iarg};
        case 'cbpath',
            cb_path = varargin{iarg};
    end
end

if computeCamParams
    [cameraParams, ~, ~] = cb_calibration(...
                           'cb_path', cb_path, ...
                           'num_rad_coeff', num_rad_coeff, ...
                           'est_tan_distortion', est_tan_distortion, ...
                           'estimateskew', estimateSkew);
else
    load(camParamFile);    % contains a cameraParameters object named cameraParams
end
K = cameraParams.IntrinsicMatrix;   % camera intrinsic matrix (matlab format, meaning lower triangular
                                    %       version - Hartley and Zisserman and the rest of the world seem to
                                    %       use the transpose of matlab K)

F = sr_fundMatrix(x1_left,x2_left,x1_right,x2_right);

numSessions = size(F,4);
E = zeros(size(F));
P = zeros(4,3,2,numSessions);

for iSession = 1 : numSessions
    
    for iMirror = 1 : 2
        switch iMirror
            case 1,
                x1 = x1_left{iSession};
                x2 = x2_left{iSession};
            case 2,
                x1 = x1_right{iSession};
                x2 = x2_right{iSession};
        end
        
        E(:,:,iMirror,iSession) = K * squeeze(F(:,:,iMirror,iSession)) * K';
        [rot,t] = EssentialMatrixToCameraMatrix(squeeze(E(:,:,iMirror,iSession)));
        [cRot,cT,~] = SelectCorrectEssentialCameraMatrix_mirror(rot,t,x1',x2',K');
        Ptrans = [cRot,cT];
        P(:,:,iMirror,iSession) = Ptrans';
    end
end

srCal.F = F;
srCal.P = P;
srCal.E = E;
