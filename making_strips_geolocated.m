clear;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%    FILEDS TO COMPLETE BEFORE RUNNING THE FILE    %%%

% path to folder where raw images are stored
folder = '/shares/lab/sjain/Data/Barbados/1950/undistort';

% T = path to file containing geolocations
T = readtable('/shares/lab/sjain/Data/Barbados/1950/kml files/Coordinates.xlsx'); % should contain columns Image, row, col, lon, lat

% parameters for co-registration
n = 2604; % size of each image
res = 3; % factor by which resolution of images should be declined while matching
key_size = 300; % size of key in the downsampled images
j_begin = 530; % horizontal index of the point where the key must begin on the downsampled left image
hor = 1; % hor refers to starting point (for matching) on image on the right
i_travel = 121; % vertical distance to search over in the downsampled right image
j_travel = 221; % horizontal distance to search over in the downsampled right image
thr = 800; % feature recognition threshold (1000 is best, but least number of features) - to be done pairwise before coregistration
res2 = 3; % factor by which resolution should be declined while performing feature recognition
blend = 200; % horizontal length for blending - to create a seamless merge
ncores = 10; % number of cores for parallel processing

% images in strip
right = 0284; % righmost image
left = 0268; % leftmost image 

% output file name
output_file_name = '/shares/lab/sjain/Output/Barbados/1950/strips/10';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Leave these fields as is. Do not edit.
S = dir(fullfile(folder,'*.tif'));

row = NaN(abs(right-left)+1,1);
col = NaN(abs(right-left)+1,1);
lat = NaN(abs(right-left)+1,1);
lon = NaN(abs(right-left)+1,1);

locations = table(row,col,lat,lon);

Images = uint8(zeros(n,n,abs(right-left)+1));

if right<left
    index = 1;
    for m = 1:numel(S)
        if str2double(S(m).name(end-7:end-4)) >= right && str2double(S(m).name(end-7:end-4)) <= left
            F = fullfile(folder,S(m).name);
            Images(:,:,index) = imread(F);
            locations.row(index) = n/2;
            locations.col(index) = n/2;
            if ~isempty(T.col(string(T.Image) == F(length(folder)+2:end-4)))
                locations.row(index) = T.row(string(T.Image) == F(length(folder)+2:end-4));
                locations.col(index) = T.col(string(T.Image) == F(length(folder)+2:end-4));
                locations.lat(index) = T.lat(string(T.Image) == F(length(folder)+2:end-4));
                locations.lon(index) = T.lon(string(T.Image) == F(length(folder)+2:end-4));
            end
            index = index+1;
        end
    end
else
    index = 1;
    for m = numel(S):-1:1
        if str2double(S(m).name(end-7:end-4)) <= right && str2double(S(m).name(end-7:end-4)) >= left
            F = fullfile(folder,S(m).name);
            Images(:,:,index) = imread(F);
            locations.row(index) = n/2;
            locations.col(index) = n/2;
            if ~isempty(T.col(string(T.Image) == F(length(folder)+2:end-4)))
                locations.row(index) = T.row(string(T.Image) == F(length(folder)+2:end-4));
                locations.col(index) = T.col(string(T.Image) == F(length(folder)+2:end-4));
                locations.lat(index) = T.lat(string(T.Image) == F(length(folder)+2:end-4));
                locations.lon(index) = T.lon(string(T.Image) == F(length(folder)+2:end-4));
            end
            index = index+1;
        end
    end
end

mask = any(any(Images)); 
Images = Images(:,:,mask);
a = size(Images);
xtforms = zeros(3,3,a(3)-1);

locations = rmmissing(locations,'DataVariables',{'row','col'});

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

    [x2,ref] = imwarp(x2,affine2d(xtform));
    
    [new_x,new_y] = transformPointsForward(affine2d(xtform),locations.col(image),locations.row(image));
    locations.row(image) = round(new_y - ref.YWorldLimits(1));
    locations.col(image) = round(new_x - ref.XWorldLimits(1));

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

parpool(ncores);

Images1 = Images(:,:,1:a(3)-1);
Images2 = Images(:,:,2:a(3));

parfor m = 1:a(3)-1
    x1 = Images1(:,:,m);
    x2 = Images2(:,:,m);
    x1 = x1(1:n,1:n);
    x2 = x2(1:n,1:n);
    ij(m,:) = merge2_v6(x1,x2,key_size,j_begin,i_travel,j_travel,hor,res);
end

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
        
        for rightside = 1:image-1
            locations.row(rightside) = locations.row(rightside) + shift;
            locations.col(rightside) = locations.col(rightside) + size(im_left,2) - floor(overlap_j/2) - blend + 1;
        end

    else  
        im_left = im2(:,1:end-floor(overlap_j/2));
        im_left = cat(1,zeros(-shift,size(im_left,2)),im_left);
        im_right = im1(:,floor(overlap_j/2):end);
        im_right = cat(1,im_right,zeros(-shift,size(im_right,2)));
       
        Images = cat(1,zeros(-shift,size(Images,2),size(Images,3)),Images);
        
        for rightside = 1:image-1
            locations.col(rightside) = locations.col(rightside) + size(im_left,2) - floor(overlap_j/2) - blend + 1;
        end
        
        locations.row(image) = locations.row(image) - shift;
        
        for leftside = image+1:size(Images,3)
            locations.row(leftside) = locations.row(leftside) - shift;
        end

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

locations.row = locations.row - sum(find(~any(im1,2)) < n);
im1 = im1(any(im1,2),:);

locations = rmmissing(locations);

imwrite(im1,cat(2,output_file_name,'.tif'))
writetable(locations,cat(2,output_file_name,'.csv'))
