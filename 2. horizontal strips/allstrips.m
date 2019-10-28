%%%%%%%%%%%%%%% IMAGE STITCHING STEP 5 %%%%%%%%%%%%%%%%%

clear;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%    FILEDS TO COMPLETE BEFORE RUNNING THE FILE    %%%

% path to folder where raw images are stored
folder = '/shares/lab/sjain/Data/Barbados/1950/undistort';

% Create a folder in which to store the strips (please include forward 
% slash in the end)
output_path = '/shares/lab/sjain/Output/Barbados/1950/strips/';

% O = path to overview_strips file
O = readtable('/shares/lab/sjain/Data/Barbados/1950/kml files/overview_strips.xlsx');

% parameters for co-registration
hor = 1; % hor refers to starting point (for matching) on image 1 
res = 3; % factor by which resolution should be declined (co-registration)
key_size = 300; % image_size/~3 (image_size after reducing resolution)
j_begin = 530; % image_size/2 + image_size/~11.5 (image_size after reducing resolution)
i_travel = 121; % image_size/~7.5 (image_size after reducing resolution) [odd]
j_travel = 221; % image_size/~3.5 (image_size after reducing resolution) [odd]
thr = 800; % feature recognition threshold (1000 is best, but least number of features)
res2 = 3; % factor by which resolution should be declined (feature recognition)
blend = 200; % horizontal length for blending - to create a seamless merge

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Leave these fields as is. Do not edit.
code_folder = pwd;
cd(folder)
load('n.mat')
cd(code_folder)
S = dir(fullfile(folder,'*.tif'));
mkdir(output_path(1:end-1));
cd(output_path(1:end-1))
save('n', 'n')
cd(code_folder)

rights = O.Right;
lefts = O.Left;
output_files = O.StripNumber;

for strip = 1:length(rights)

    right = rights(strip); % righmost image
    left = lefts(strip); % leftmost image 
    
    Images = uint8(zeros(n,n,abs(right-left)+1));

    if right<left
        index = 1;
        for m = 1:numel(S)
            if str2double(S(m).name(end-7:end-4)) >= right && str2double(S(m).name(end-7:end-4)) <= left
                F = fullfile(folder,S(m).name);
                Images(:,:,index) = imread(F);
                index = index+1;
            end
        end
    else
        index = 1;
        for m = numel(S):-1:1
            if str2double(S(m).name(end-7:end-4)) <= right && str2double(S(m).name(end-7:end-4)) >= left
                F = fullfile(folder,S(m).name);
                Images(:,:,index) = imread(F);
                index = index+1;
            end
        end
    end

    mask = any(any(Images)); 
    Images = Images(:,:,mask);
    a = size(Images);
    xtforms = zeros(3,3,a(3)-1);

    for image = 2:a(3)
        x1 = Images(:,:,image-1);
        x2 = Images(:,:,image);
        x1 = x1(1:n,1:n);
        x2 = x2(1:n,1:n);

        I1 = imresize(x1,1/res2);
        I2 = imresize(x2,1/res2);

        points = detectSURFFeatures(I1,'MetricThreshold',thr);
        [featuresPrev, pointsPrev] = extractFeatures(I1,points);

        points = detectSURFFeatures(I2,'MetricThreshold',thr);
        [features, points] = extractFeatures(I2,points); 

        indexPairs = matchFeatures(features,featuresPrev);
        matchedPoints     = points(indexPairs(:, 1), :);
        matchedPointsPrev = pointsPrev(indexPairs(:, 2), :);

        tform = estimateGeometricTransform(matchedPoints,matchedPointsPrev,'affine'); 
        xtform = tform.T;

        xtform(3,1:2) = [0 0];

        xtforms(:,:,image-1) = xtform;
    end

    for image = 2:a(3)
        x2 = Images(:,:,image);
        x2 = x2(1:n,1:n);

        xtform = xtforms(:,:,image-1);

        x2 = imwarp(x2,affine2d(xtform));

        n = size(x1,1);

        if size(x2,1)>=n && size(x2,2)>=n
            x2 = x2(1:n,1:n);
        elseif size(x2,1)>=n
            x2 = x2(1:n,:);
            x2 = cat(2,x2,zeros(n,n-size(x2,2)));
        elseif size(x2,2)>=n
            x2 = x2(:,1:n);
            x2 = cat(1,x2,zeros(n-size(x2,1),n));
        else
            x2 = cat(1,x2,zeros(n-size(x2,1),size(x2,2)));
            x2 = cat(2,x2,zeros(n,n-size(x2,2)));
        end

        Images(:,:,image) = x2;
    end

    ij = zeros(a(3)-1,2);

    parpool(10);

    Images1 = Images(:,:,1:a(3)-1);
    Images2 = Images(:,:,2:a(3));

    parfor m = 1:a(3)-1
        ij(m,:) = merge2_v6(Images1(:,:,m),Images2(:,:,m),key_size,j_begin,i_travel,j_travel,hor,res);
    end
    
    delete(gcp('nocreate'));

    im1 = Images(:,:,1);

    for image = 2:a(3)
        im2 = Images(:,:,image);

        overlap_j = ij(image-1,1);
        shift = ij(image-1,2);

        overlap_j = overlap_j - blend;

        if shift>0 

            im_left = im2(:,1:end-floor(overlap_j/2));
            im_left = cat(1,im_left,zeros(shift,size(im_left,2)));
            im_right = im1(:,floor(overlap_j/2):end);
            im_right = cat(1,zeros(shift,size(im_right,2)),im_right);

            Images = cat(1,Images,zeros(shift,size(Images,2),size(Images,3)));
            
        else  
            im_left = im2(:,1:end-floor(overlap_j/2));
            im_left = cat(1,zeros(-shift,size(im_left,2)),im_left);
            im_right = im1(:,floor(overlap_j/2):end);
            im_right = cat(1,im_right,zeros(-shift,size(im_right,2)));

            Images = cat(1,zeros(-shift,size(Images,2),size(Images,3)),Images);

        end

        weights1 = linspace(1,0,blend);
        weights2 = fliplr(weights1);

        seamless_left = im_left(:,end-blend+1:end);
        seamless_right = im_right(:,1:blend);

        seamlessImage = uint8(weights1 .* single(im_left(:,end-blend+1:end)) + weights2 .* single(im_right(:,1:blend)));
        seamlessImage(seamless_left == 0) = seamless_right(seamless_left == 0);
        seamlessImage(seamless_right == 0) = seamless_left(seamless_right == 0);
        
        im1 = cat(2,im_left(:,1:end-blend),seamlessImage,im_right(:,blend+1:end));

    end

    im1 = im1(any(im1,2),:);

    name = num2str(output_files(strip));

    imwrite(im1,cat(2,output_path,name,'.tif'))
    
    fprintf('Strip %d done.\n',output_files(strip));
    
end