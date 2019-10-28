%%%%%%%%%%%%%%% IMAGE STITCHING STEP 6 %%%%%%%%%%%%%%%%%

clear;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%    FILEDS TO COMPLETE BEFORE RUNNING THE FILE    %%%

% path to folder where raw images are stored (please include forward slash
% in the end)
folder = '/shares/lab/sjain/Output/Barbados/1950/strips/';

% Create a folder in which to store the chunks (please
% include forward slash in the end)
output_path = '/shares/lab/sjain/Output/Barbados/1950/chunks/';

% O = path to overview_chunks file
O = readtable('/shares/lab/sjain/Data/Barbados/1950/kml files/overview_chunks.xlsx');

% parameters for feature recognition
scale = 1; % factor by which images should be downsampled 
add_vert = 2500; % vertical increase in size of mosaic
add_left = 1500; % increase in size of mosaic to the left
add_right = 1500; % increase in size of mosaic to the right
height1 = 1200; % vertical length in which to detect features in backbone
height2 = 1200; % vertical length in which to detect features in strip2
section = 3000; % strip2 pieces length 
overlap = 250; % strip2 pieces overlap
thr = 700; % threshold for feature detection (1000 is most accurate but least number of features)
met = 'SAD'; % metric for matching features

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Leave these fields as is. Do not edit.
code_folder = pwd;
cd(folder(1:end-1))
load('n.mat')
cd(code_folder)
mkdir(output_path(1:end-1));

backbones = O.Backbone;
additions = O.Addition;
directions = O.Direction;
output_files = O.ChunkNumber;

for i = 1:length(backbones)

    x1 = imread(cat(2,folder,num2str(backbones(i)),'.tif')); % backbone strip
    x2 = imread(cat(2,folder,num2str(additions(i)),'.tif')); % strip being added
    direction = directions{i}; % adding above ('a') or below ('b')

    mosaic = merge_strips(x1,x2,direction,scale,add_vert,add_left,add_right,height1,height2,section,overlap,thr,met);

    imwrite(mosaic,cat(2,output_path,num2str(output_files(i)),'.tif'))
    
end