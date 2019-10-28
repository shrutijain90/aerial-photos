%%%%%%%%%%%%%%% IMAGE STITCHING STEP 6 %%%%%%%%%%%%%%%%%

clear;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%    FILEDS TO COMPLETE BEFORE RUNNING THE FILE    %%%

% path to folder where raw images are stored (please include forward slash
% in the end)
folder = '/shares/lab/sjain/Output/Barbados/1950/strips/';

% strips being merged
backbone_strip = '17'; % bacbone strip
addition_strip = '18'; % strip being added
direction = 'a'; % adding above ('a') or below ('b')

% parameters for feature recognition
scale = 1; % factor by which images should be downsampled 
add_vert = 2500; % vertical increase in size of mosaic
add_left = 0; % increase in size of mosaic to the left
add_right = 0; % increase in size of mosaic to the right
height1 = 1100; % vertical length in which to detect features in backbone
height2 = 1100; % vertical length in which to detect features in strip2
section = 5000; % strip2 pieces length 
overlap = 250; % strip2 pieces overlap
thr = 700; % threshold for feature detection (1000 is most accurate but least number of features)
met = 'SSD'; % metric for matching features

% output file name
output_file_name = '17_18';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Leave these fields as is. Do not edit.
code_folder = pwd;
cd(folder(1:end-1))
load('n.mat')
cd(code_folder)

% loading files
x1 = imread(cat(2,folder,backbone_strip,'.tif')); % backbone strip
x2 = imread(cat(2,folder,addition_strip,'.tif')); % strip being added
loc1 = readtable(cat(2,folder,backbone_strip,'.csv')); % geolocations of backbone
loc2 = readtable(cat(2,folder,addition_strip,'.csv')); % geolocations of strip being added

[mosaic,loc] = merge_strips_centroids(x1,x2,direction,scale,add_vert,add_left,add_right,height1,height2,section,overlap,thr,met,loc1,loc2, n);

imwrite(mosaic,cat(2,output_file_name,'.tif'))
writetable(loc,cat(2,output_file_name,'.csv'))