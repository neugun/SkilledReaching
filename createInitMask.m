function createInitMask(videoFile, saveInitMaskAs, hsvBounds)
    obj = VideoReader(videoFile);
    avgImage = read(obj, 1);
    setupInitMask = avgImage;
    setupInitMask(:,:,1) = 0;
    colorMask = logical(setupInitMask(:,:,1));

    for i = 1:obj.NumberOfFrames
        image = read(obj, i);
%         avgImage = (avgImage + image)/2;
        hsv = rgb2hsv(image);

        h = hsv(:,:,1);
        s = hsv(:,:,2);
        v = hsv(:,:,3);

        h = h(h > hsvBounds(1) & h < hsvBounds(2));
        s = s(s > hsvBounds(3) & s < hsvBounds(4));
        v = v(v > hsvBounds(5) & v < hsvBounds(6));

        h = imopen(h, strel('disk', 10, 0));
        h = imfill(h, 'holes');
        h = imdilate(h, strel('disk', 17, 0));
           
        % concat these together over time
        colorMask = colorMask | logical(h);
    end
    
%     hsv = rgb2hsv(avgImage);
% 
%     h = hsv(:,:,1);
%     s = hsv(:,:,2);
%     v = hsv(:,:,3);
% 
%     h(h < .25 | h > .45) = 0;
%     h(s < .15) = 0;
%     h(v < .07) = 0;
% 
%     h = imclose(h, strel('disk', 5, 0));
%     h = imdilate(h, strel('disk', 5, 0));
%     h = imfill(h, 'holes');
% 
%     avgMask = ~logical(h);

    %imwrite((colorMask & avgMask), saveInitMaskAs);
    % not sure if averaging will work, rat my sit in same place for a while
    imwrite((colorMask), saveInitMaskAs);
end