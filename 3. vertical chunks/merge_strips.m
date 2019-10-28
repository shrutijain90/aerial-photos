function [mosaic] = merge_strips(x1,x2,direction,scale,add_vert,add_left,add_right,height1,height2,section,overlap,thr,met)
% merges 2 strips together vertically

height1 = floor(height1/scale);
height2 = floor(height2/scale);

I1 = x1(any(x1,2),:);
I = x2(any(x2,2),:);

if direction == 'b'
    
    % adding below
    
    %create mosaic background
    sz = size(I1);
    h = sz(1) + add_vert;
    w = sz(2) + add_left + add_right;
    %create a world coordinate system
    outputView = imref2d([h,w]);
    xtform = [1 0 0; 0 1 0; add_left 0 1];
    mosaic = imwarp(I1, affine2d(xtform),'OutputView', outputView);
    
    % features in backbone image
    I1 = mosaic;
    I1 = imresize(I1,1/scale);
    add_left = floor(add_left/scale);
    add_vert = floor(add_vert/scale);
    points = detectSURFFeatures(I1,'MetricThreshold',thr,'ROI',[add_left+1 size(I1,1)-add_vert-height1 size(I1,2)-add_left height1]); 
    [featuresPrev, pointsPrev] = extractFeatures(I1,points);
    
    a = floor(size(I,2)/section);

    for m = 1:a
        if a == 1
            I2 = I;
        elseif m == 1
            I2 = I(:,1:section+overlap);
        elseif m == a
            I2 = I(:,1+section*(a-1)-overlap:end);
        else
            I2 = I(:,1+section*(m-1)-overlap:section*m+overlap);
        end

        I2 = imresize(I2,1/scale);

        %Detect SURFFeatures in the target image
        points = detectSURFFeatures(I2,'MetricThreshold',thr,'ROI',[1 1 size(I2,2) height2]); 
        [features, points] = extractFeatures(I2,points); 

        % Match features computed from the refernce and the target images
        indexPairs = matchFeatures(features, featuresPrev, 'MatchThreshold',40,'MaxRatio',0.8,'Metric',met);  
        matchedPoints     = points(indexPairs(:, 1), :);
        matchedPointsPrev = pointsPrev(indexPairs(:, 2), :);

        %compute a geometric transformation from the  corresponding locations
        tform = estimateGeometricTransform(matchedPoints,matchedPointsPrev,'affine','Confidence',99,'MaxNumTrials',20000); 
        xtform = tform.T;

        if a == 1
            I2 = I;
        elseif m == 1
            I2 = I(:,1:section+overlap);
        elseif m == a
            I2 = I(:,1+section*(a-1)-overlap:end);
        else
            I2 = I(:,1+section*(m-1)-overlap:section*m+overlap);
        end

        xtform(3,1) = scale*xtform(3,1);
        xtform(3,2) = scale*xtform(3,2);

        % Warp the current image onto the mosaic image
        mosaicnew = imwarp(I2, affine2d(xtform), 'OutputView', outputView); 
        halphablender = vision.AlphaBlender('Operation', 'Binary mask', 'MaskSource', 'Input port');
        mask= imwarp(ones(size(I2)), affine2d(xtform), 'OutputView', outputView)>=1; 
        mosaicfinal = step(halphablender, mosaic,mosaicnew, mask);

        mosaic(mosaic==0) = mosaicfinal(mosaic==0);
    end

    mosaic = mosaic(any(mosaic,2),:);
    mosaic = mosaic(:,any(mosaic,1));
    
else
    
    % adding above
    
    %create mosaic background
    sz = size(I1);
    h = sz(1) + add_vert;
    w = sz(2) + add_left + add_right;
    %create a world coordinate system
    outputView = imref2d([h,w]);
    xtform = [1 0 0; 0 1 0; add_left add_vert 1];
    mosaic = imwarp(I1, affine2d(xtform),'OutputView', outputView);
    
    % features in backbone image
    I1 = mosaic;
    I1 = imresize(I1,1/scale);
    add_left = floor(add_left/scale);
    add_vert = floor(add_vert/scale);
    points = detectSURFFeatures(I1,'MetricThreshold',thr,'ROI',[add_left+1 add_vert+1 size(I1,2)-add_left height1]); 
    [featuresPrev, pointsPrev] = extractFeatures(I1,points);
    
    a = floor(size(I,2)/section);

    for m = 1:a
        if a == 1
            I2 = I;
        elseif m == 1
            I2 = I(:,1:section+overlap);
        elseif m == a
            I2 = I(:,1+section*(a-1)-overlap:end);
        else
            I2 = I(:,1+section*(m-1)-overlap:section*m+overlap);
        end

        I2 = imresize(I2,1/scale);

        %Detect SURFFeatures in the target image
        points = detectSURFFeatures(I2,'MetricThreshold',thr,'ROI',[1 size(I2,1)-height2 size(I2,2) height2]); 
        [features, points] = extractFeatures(I2,points); 

        % Match features computed from the refernce and the target images
        indexPairs = matchFeatures(features, featuresPrev, 'MatchThreshold',40,'MaxRatio',0.8,'Metric',met);  
        matchedPoints     = points(indexPairs(:, 1), :);
        matchedPointsPrev = pointsPrev(indexPairs(:, 2), :);

        %compute a geometric transformation from the  corresponding locations
        tform = estimateGeometricTransform(matchedPoints,matchedPointsPrev,'affine','Confidence',99,'MaxNumTrials',20000); 
        xtform = tform.T;

        if a == 1
            I2 = I;
        elseif m == 1
            I2 = I(:,1:section+overlap);
        elseif m == a
            I2 = I(:,1+section*(a-1)-overlap:end);
        else
            I2 = I(:,1+section*(m-1)-overlap:section*m+overlap);
        end

        xtform(3,1) = scale*xtform(3,1);
        xtform(3,2) = scale*xtform(3,2);

        % Warp the current image onto the mosaic image
        mosaicnew = imwarp(I2, affine2d(xtform), 'OutputView', outputView); 
        halphablender = vision.AlphaBlender('Operation', 'Binary mask', 'MaskSource', 'Input port');
        mask= imwarp(ones(size(I2)), affine2d(xtform), 'OutputView', outputView)>=1; 
        mosaicfinal = step(halphablender, mosaic,mosaicnew, mask);

        mosaic(mosaic==0) = mosaicfinal(mosaic==0);
    end

    mosaic = mosaic(any(mosaic,2),:);
    mosaic = mosaic(:,any(mosaic,1));
    
end

end

