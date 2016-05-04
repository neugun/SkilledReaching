function [boxRegions] = boxRegionsfromMatchedPoints(session_mp, imSize)


% mask of the front panel in both mirror views
leftCorners_x = [session_mp.leftMirror.front_panel_top_front(1),...
                 session_mp.leftMirror.front_panel_top_back(1),...
                 session_mp.leftMirror.front_panel_bot_back(1),...
                 session_mp.leftMirror.front_panel_bot_front(1),...
                 session_mp.leftMirror.front_panel_top_front(1)];
             
leftCorners_y = [session_mp.leftMirror.front_panel_top_front(2),...
                 session_mp.leftMirror.front_panel_top_back(2),...
                 session_mp.leftMirror.front_panel_bot_back(2),...
                 session_mp.leftMirror.front_panel_bot_front(2),...
                 session_mp.leftMirror.front_panel_top_front(2)];
             
rightCorners_x = [session_mp.rightMirror.front_panel_top_front(1),...
                  session_mp.rightMirror.front_panel_top_back(1),...
                  session_mp.rightMirror.front_panel_bot_back(1),...
                  session_mp.rightMirror.front_panel_bot_front(1),...
                  session_mp.rightMirror.front_panel_top_front(1)];
             
rightCorners_y = [session_mp.rightMirror.front_panel_top_front(2),...
                  session_mp.rightMirror.front_panel_top_back(2),...
                  session_mp.rightMirror.front_panel_bot_back(2),...
                  session_mp.rightMirror.front_panel_bot_front(2),...
                  session_mp.rightMirror.front_panel_top_front(2)];
              
frontPanelMask_left = poly2mask(leftCorners_x,leftCorners_y,imSize(1),imSize(2));
frontPanelMask_right = poly2mask(rightCorners_x,rightCorners_y,imSize(1),imSize(2));

boxRegions.frontPanelMask = frontPanelMask_left | frontPanelMask_right;

% mask out the region between the front panels in the mirror views
leftLine = lineCoeffFromPoints([session_mp.leftMirror.front_panel_top_back;...
                                session_mp.leftMirror.front_panel_bot_back]);
rightLine = lineCoeffFromPoints([session_mp.rightMirror.front_panel_top_back;...
                                 session_mp.rightMirror.front_panel_bot_back]);
                             
leftEdgePts = round(lineToBorderPoints(leftLine, imSize));
rightEdgePts = round(lineToBorderPoints(rightLine, imSize));

intCorners_x = [session_mp.leftMirror.front_panel_top_back(1),...
                session_mp.leftMirror.left_top_floor_corner(1),...
                session_mp.rightMirror.right_top_floor_corner(1),...
                session_mp.rightMirror.front_panel_top_back(1),...
                session_mp.leftMirror.front_panel_top_back(1)];
            
intCorners_y = [session_mp.leftMirror.front_panel_top_back(2),...
                session_mp.leftMirror.left_top_floor_corner(2),...
                session_mp.rightMirror.right_top_floor_corner(2),...
                session_mp.rightMirror.front_panel_top_back(2),...
                session_mp.leftMirror.front_panel_top_back(2)];
            
% intCorners_x = [leftEdgePts(1),...
%                 leftEdgePts(3),...
%                 rightEdgePts(3),...
%                 rightEdgePts(1),...
%                 leftEdgePts(1)];
%             
% intCorners_y = [leftEdgePts(2),...
%                 leftEdgePts(4),...
%                 rightEdgePts(4),...
%                 rightEdgePts(2),...
%                 leftEdgePts(2)];
            
% intCorners_x = [session_mp.leftMirror.front_panel_top_back(1),...
%                 session_mp.rightMirror.front_panel_top_back(1),...
%                 session_mp.rightMirror.front_panel_bot_back(1),...
%                 session_mp.leftMirror.front_panel_bot_back(1),...
%                 session_mp.leftMirror.front_panel_top_back(1)];
%             
% intCorners_y = [session_mp.leftMirror.front_panel_top_back(2),...
%                 session_mp.rightMirror.front_panel_top_back(2),...
%                 session_mp.rightMirror.front_panel_bot_back(2),...
%                 session_mp.leftMirror.front_panel_bot_back(2),...
%                 session_mp.leftMirror.front_panel_top_back(2)];
            
boxRegions.intMask = poly2mask(intCorners_x,intCorners_y,imSize(1),imSize(2));

% mask out the region outside the front panels in the mirror views
left_extCorners_x = [1,...
                     session_mp.leftMirror.front_panel_top_front(1),...
                     session_mp.leftMirror.front_panel_bot_front(1),...
                     1,...
                     1];
                 
left_extCorners_y = [1,...
                     session_mp.leftMirror.front_panel_top_front(2),...
                     session_mp.leftMirror.front_panel_bot_front(2),...
                     imSize(1),...
                     1];
                 
right_extCorners_x = [session_mp.rightMirror.front_panel_top_front(1),...
                      session_mp.rightMirror.front_panel_bot_front(1),...
                      imSize(2),...
                      imSize(2),...
                      session_mp.rightMirror.front_panel_top_front(1)];
                 
right_extCorners_y = [session_mp.rightMirror.front_panel_top_front(2),...
                      session_mp.rightMirror.front_panel_bot_front(2),...
                      imSize(1),...
                      1,...
                      session_mp.rightMirror.front_panel_top_front(2)];
                  
left_extMask = poly2mask(left_extCorners_x,left_extCorners_y,imSize(1),imSize(2));
right_extMask = poly2mask(right_extCorners_x,right_extCorners_y,imSize(1),imSize(2));

boxRegions.extMask = (left_extMask | right_extMask);
                 

% mask out the regions above and below the shelf
above_shelf_x = [session_mp.direct.left_back_shelf_corner(1),...
                session_mp.direct.right_back_shelf_corner(1),...
                session_mp.direct.right_back_shelf_corner(1),...
                session_mp.direct.left_back_shelf_corner(1),...
                session_mp.direct.left_back_shelf_corner(1)];
above_shelf_y = [session_mp.direct.left_back_shelf_corner(2),...
                session_mp.direct.right_back_shelf_corner(2),...
                1,...
                1,...
                session_mp.direct.left_back_shelf_corner(2)];
            
boxMarkers.aboveShelfMask = poly2mask(above_shelf_x,above_shelf_y,imSize(1),imSize(2));

% mask out the regions above and below the shelf
below_shelf_x = [session_mp.direct.left_bottom_shelf_corner(1),...
                 session_mp.direct.right_bottom_shelf_corner(1),...
                 session_mp.direct.right_bottom_shelf_corner(1),...
                 session_mp.direct.left_bottom_shelf_corner(1),...
                 session_mp.direct.left_bottom_shelf_corner(1)];
below_shelf_y = [session_mp.direct.left_bottom_shelf_corner(2),...
                 session_mp.direct.right_bottom_shelf_corner(2),...
                 imSize(1),...
                 imSize(1),...
                 session_mp.direct.left_bottom_shelf_corner(2)];
            
boxRegions.belowShelfMask = poly2mask(below_shelf_x,below_shelf_y,imSize(1),imSize(2));

% mask out the shelf itself
shelf_x = [session_mp.direct.left_back_shelf_corner(1),...
           session_mp.direct.right_back_shelf_corner(1),...
           session_mp.direct.right_top_shelf_corner(1),...
           session_mp.direct.right_bottom_shelf_corner(1),...
           session_mp.direct.left_bottom_shelf_corner(1),...
           session_mp.direct.left_top_shelf_corner(1),...
           session_mp.direct.left_back_shelf_corner(1)];
shelf_y = [session_mp.direct.left_back_shelf_corner(2),...
           session_mp.direct.right_back_shelf_corner(2),...
           session_mp.direct.right_top_shelf_corner(2),...
           session_mp.direct.right_bottom_shelf_corner(2),...
           session_mp.direct.left_bottom_shelf_corner(2),...
           session_mp.direct.left_top_shelf_corner(2),...
           session_mp.direct.left_back_shelf_corner(2)];
       
boxRegions.shelfMask = poly2mask(shelf_x,shelf_y,imSize(1),imSize(2));

% mask of the front edge of the floor
floor_x = [session_mp.direct.left_top_floor_corner(1),...
           session_mp.direct.right_top_floor_corner(1),...
           imSize(2),...
           1,...
           session_mp.direct.left_top_floor_corner(1)];
       
floor_y = [session_mp.direct.left_top_floor_corner(2),...
           session_mp.direct.right_top_floor_corner(2),...
           imSize(1),...
           imSize(1),...
           session_mp.direct.left_top_floor_corner(2)];
       
boxRegions.floorMask = poly2mask(floor_x,floor_y,imSize(1),imSize(2));

% mask of the slot
slot_x = [session_mp.direct.left_top_slot_corner(1), ...
          session_mp.direct.right_top_slot_corner(1), ...
          session_mp.direct.right_bottom_slot_corner(1), ...
          session_mp.direct.left_bottom_slot_corner(1), ...
          session_mp.direct.left_top_slot_corner(1)];
      
slot_y = [session_mp.direct.left_top_slot_corner(2), ...
          session_mp.direct.right_top_slot_corner(2), ...
          session_mp.direct.right_bottom_slot_corner(2), ...
          session_mp.direct.left_bottom_slot_corner(2), ...
          session_mp.direct.left_top_slot_corner(2)];
      
boxRegions.slotMask = poly2mask(slot_x,slot_y,imSize(1),imSize(2));
