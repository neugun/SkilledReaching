function combineCentroids()
    m = 7;
    s = 2;
    load('data_centroids_red.mat');
    centroids_red = smoothCentroids(data_centroids,m,s);

    load('data_centroids_yellow.mat');
    centroids_yellow = smoothCentroids(data_centroids,m,s);

    load('data_centroids_blue.mat');
    centroids_blue = smoothCentroids(data_centroids,m,s);

    load('data_centroids_green.mat');
    centroids_green = smoothCentroids(data_centroids,m,s);
    
    load('data_mask_blue.mat');
    data_mask_blue = data_mask;

    video = VideoReader('R0000_20140308_11-49-12_008_MIDDLE.avi');

    combinedVideo = VideoWriter('R0000_20140308_11-49-12_008_MIDDLE_alltracks.avi', 'Motion JPEG AVI');
    combinedVideo.Quality = 85;
    combinedVideo.FrameRate = 25;
    open(combinedVideo);

    for i = 1:video.NumberOfFrames
        disp(i)
        image = read(video, i);
        
        image = applyColorMask(image, data_mask(:,:,i), .61);
        
        if(~isnan(centroids_red(:,1,i)))
            image = annotateImage(image, centroids_red(:,:,i), 'r', 'red');
        end
        if(~isnan(centroids_yellow(:,1,i)))
            image = annotateImage(image, centroids_yellow(:,:,i), 'y', 'yellow');
        end
        if(~isnan(centroids_blue(:,1,i)))
            image = annotateImage(image, centroids_blue(:,:,i), 'b', 'blue');
        end
        if(~isnan(centroids_green(:,1,i)))
            image = annotateImage(image, centroids_green(:,:,i), 'g', 'green');
        end
        writeVideo(combinedVideo, im2frame(image));
        imshow(image)
    end
    close(combinedVideo);
end

function [coloredMask] = applyColorMask(image, mask, hue)
    hsv = rgb2hsv(image);
    edgeMask = edge(mask);
    h = hsv(:,:,1);
    s = hsv(:,:,2);
    v = hsv(:,:,3);
    h(edgeMask > 0) = hue;
    s(edgeMask > 0) = .75;
    v(edgeMask > 0) = 1;
    hsv(:,:,1) = h;
    hsv(:,:,2) = s;
    hsv(:,:,3) = v;
    coloredMask = hsv2rgb(hsv);
end

function [data_centroids] = smoothCentroids(data_centroids, medianWindow, averageWindow)
    x = squeeze(data_centroids(1,1,:));
    y = squeeze(data_centroids(1,2,:));
    for i=1:15
        [x ip] = func_despike_phasespace3d(x,0,0);
        [y ip] = func_despike_phasespace3d(y,0,0);
    end
    x = medfilt1(x, medianWindow);
    y = medfilt1(y, medianWindow);
    data_centroids(1,1,:) = smooth(x, averageWindow);
    data_centroids(1,2,:) = smooth(y, averageWindow);
end

function [annotatedImage] = annotateImage(image, coordinates, label, color)
    annotatedImage = insertObjectAnnotation(image, 'circle', ...
                        [coordinates,2], label, 'Color', color);
end