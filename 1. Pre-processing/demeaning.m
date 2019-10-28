%%%%%%%%%%%%%%% IMAGE STITCHING STEP 3 %%%%%%%%%%%%%%%%%

clear;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%    FILEDS TO COMPLETE BEFORE RUNNING THE FILE    %%%

% path to folder where raw images are stored 
folder = '/shares/lab/sjain/Data/Barbados/1950/raw';

% Create a folder in which to store the pre-processed images (please
% include forward slash in the end)
output_path = '/shares/lab/sjain/Data/Barbados/1950/demean/';

% O = path to overview_strips file 
O = pandas.read('/shares/lab/sjain/Data/Barbados/1950/kml files/overview_strips.xlsx');

% Angles of rotation
right_angle = 0; % rotation if strip begins on right, i.e. right<left
left_angle = 0; % rotation if strip begins on left i.e. right>left

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Leave these fields as is. Do not edit.
code_folder = pwd;
S = dir(fullfile(folder,'*.tif'));
im_name_begin = length(folder) + 2; 
mkdir(output_path(1:end-1));
rights = O.Right;
lefts = O.Left;
x = imread(fullfile(folder,S(1).name));
dim = size(x); % This gives you image dimensions
imshow(x) % This plots an image from the folder

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  VIEW THE IMAGE PLOT AND THE IMAGE DIMENSSIONS TO DECIDE HOW MUCH TO CROP  %%%

remove_top = 100; % how many rows and columns to remove from top 
remove_left = 100; % how many rows and columns to remove from left
n = 2604; % size of image

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Leave these fields as is. Do not edit.  
cd(output_path(1:end-1))
save('n', 'n')
cd(code_folder)

for strip = 1:length(rights)
    
    right = rights(strip); % righmost image
    left = lefts(strip); % leftmost image
    
    % If image numbers correspond to right to left stitching order 
    if right<left
        
        for m = 1:numel(S)
            % If the images are in the current strip 
            if str2double(S(m).name(end-7:end-4)) >= right && str2double(S(m).name(end-7:end-4)) <= left
                
                % Reads in a raw image
                F = fullfile(folder,S(m).name);
                x = imread(F);
                % Crops image to remove empty edges
                x = x(1+remove_top:n+remove_top,1+remove_left:n+remove_left);  
                % Rotates image so we can stitch right to left 
                x = imrotate(x,right_angle);
                % Converts image to double 
                x = double(x);
                % Demeans by row and column
                avgs_xr = nanmean(x,2);
                for i=1:n 
                    x(i,:) = x(i,:) - avgs_xr(i,1);
                end
                avgs_xc = nanmean(x,1);
                for j=1:n
                    x(:,j) = x(:,j) - avgs_xc(1,j);
                end
                % Converts image to unit8
                x = uint8(255*mat2gray(x));
                % Saves pre-processed image in demean folder 
                imwrite(x,cat(2,output_path,F(im_name_begin:end)))
            end
        end
    
    % If image numbers are in reverse order
    else
        
        for m = numel(S):-1:1
            if str2double(S(m).name(end-7:end-4)) <= right && str2double(S(m).name(end-7:end-4)) >= left
                F = fullfile(folder,S(m).name);
                x = imread(F);
                x = x(1+remove_top:n+remove_top,1+remove_left:n+remove_left); 
                x = imrotate(x,left_angle);
                x = double(x);
                avgs_xr = nanmean(x,2);
                for i=1:n
                    x(i,:) = x(i,:) - avgs_xr(i,1);
                end
                avgs_xc = nanmean(x,1);
                for j=1:n
                    x(:,j) = x(:,j) - avgs_xc(1,j);
                end
                x = uint8(255*mat2gray(x));
                imwrite(x,cat(2,output_path,F(im_name_begin:end)))
            end
        end
        
    end
    
end