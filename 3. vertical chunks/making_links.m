%%%%%%%%%%%%%%% IMAGE STITCHING STEP 6 %%%%%%%%%%%%%%%%%

clear;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%    FILEDS TO COMPLETE BEFORE RUNNING THE FILE    %%%

% path to folder where raw images are stored (please include forward slash
% in the end)
folder = '/shares/lab/sjain/Data/Barbados/1950/undistort/';

% Create a folder in which to store the chunks (please
% include forward slash in the end)
output_path = '/shares/lab/sjain/Output/Barbados/1950/links/';

% O = path to links file
O = readtable('/shares/lab/sjain/Data/Barbados/1950/kml files/links.xlsx');

% parameters for feature recognition
scale = 1; % factor by which images should be downsampled 
add_vert = 2000; % vertical increase in size of mosaic
add_left = 1500; % increase in size of mosaic to the left
add_right = 1500; % increase in size of mosaic to the right
height = 1100; % vertical length in which to detect features in the 2 images
thr = 700; % threshold for feature detection (1000 is most accurate but least number of features)
met = 'SSD'; % metric for matching features

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Leave these fields as is. Do not edit.
code_folder = pwd;
cd(folder(1:end-1))
load('n.mat')
cd(code_folder)
mkdir(output_path(1:end-1));
S = dir(fullfile(folder,'*.tif')); 

bottoms = O.Bottom;
tops = O.Top;
output_files = O.Output;

for i = 1:length(bottoms)
    
    for m = 1:numel(S)
        if str2double(S(m).name(end-7:end-4)) == bottoms(i)
            F = fullfile(folder,S(m).name);
            x1 = imread(F);
        end
        if str2double(S(m).name(end-7:end-4)) == tops(i)
            F = fullfile(folder,S(m).name);
            x2 = imread(F);
        end
    end
    
    height = floor(height/scale);
    I1 = x1;
    I2 = x2;

    %create mosaic background
    sz = size(I1);
    h = sz(1) + add_vert;
    w = sz(2) + add_left + add_right;
    %create a world coordinate system
    outputView = imref2d([h,w]);
    xtform = [1 0 0; 0 1 0; add_left add_vert 1];
    mosaic = imwarp(I1, affine2d(xtform),'OutputView', outputView);
    
    % features in bottom image
    I1 = mosaic;
    I1 = imresize(I1,1/scale);
    add_left = floor(add_left/scale);
    add_vert = floor(add_vert/scale);
    points = detectSURFFeatures(I1,'MetricThreshold',thr,'ROI',[add_left+1 add_vert+1 size(I1,2)-add_left height]); 
    [featuresPrev, pointsPrev] = extractFeatures(I1,points);
        
    %Detect SURFFeatures in the top image
    I2 = imresize(I2,1/scale);
    points = detectSURFFeatures(I2,'MetricThreshold',thr,'ROI',[1 size(I2,1)-height size(I2,2) height]); 
    [features, points] = extractFeatures(I2,points); 

    % Match features computed from the refernce and the target images
    indexPairs = matchFeatures(features, featuresPrev, 'MatchThreshold',40,'MaxRatio',0.8,'Metric',met);  
    matchedPoints     = points(indexPairs(:, 1), :);
    matchedPointsPrev = pointsPrev(indexPairs(:, 2), :);
    
    % Compute a geometric transformation from the  corresponding locations
    tform = estimateGeometricTransform(matchedPoints,matchedPointsPrev,'affine','Confidence',99,'MaxNumTrials',20000); 
    xtform = tform.T;
    
    I2 = x2;
    xtform(3,1) = scale*xtform(3,1);
    xtform(3,2) = scale*xtform(3,2);

    % Warp the current image onto the mosaic image
    mosaicnew = imwarp(I2, affine2d(xtform), 'OutputView', outputView); 
    halphablender = vision.AlphaBlender('Operation', 'Binary mask', 'MaskSource', 'Input port');
    mask= imwarp(ones(size(I2)), affine2d(xtform), 'OutputView', outputView)>=1; 
    mosaicfinal = step(halphablender, mosaic,mosaicnew, mask);

    mosaic(mosaic==0) = mosaicfinal(mosaic==0);
    mosaic = mosaic(any(mosaic,2),:);
    mosaic = mosaic(:,any(mosaic,1));
        
    imwrite(mosaic,cat(2,output_path,output_files{i},'.tif'))
    
end