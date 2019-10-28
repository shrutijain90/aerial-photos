%%%%%%%%%%%%%%% IMAGE STITCHING STEP 4 %%%%%%%%%%%%%%%%%

clear;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%    FILEDS TO COMPLETE BEFORE RUNNING THE FILE    %%%

% path to folder where raw images are stored
folder = '/shares/lab/sjain/Data/Barbados/1950/demean';

% Create a folder in which to store the pre-processed images (please
% include forward slash in the end)
output_path = '/shares/lab/sjain/Data/Barbados/1950/undistort/';

% images in strip to calculate distortion parameters
right = 0031; % righmost image
left = 0051; % leftmost image 

% parameters for co-registration 
hor = 1; % hor refers to starting point (for matching) on image 1 
res = 10; % factor by which resolution should be declined (co-registration)
key_size = 90; % image_size/~3 (image_size after reducing resolution)
j_begin = 150; % image_size/2 + image_size/~11.5 (image_size after reducing resolution)
i_travel = 35; % image_size/~7.5 (image_size after reducing resolution) [odd]
j_travel = 75; % image_size/~3.5 (image_size after reducing resolution) [odd]

% range of distortion parameters
k = 0:0.001:0.02;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Leave these fields as is. Do not edit.
code_folder = pwd;
cd(folder)
load('n.mat')
cd(code_folder)
S = dir(fullfile(folder,'*.tif'));
im_name_begin = length(folder) + 2; 
mkdir(output_path(1:end-1));
cd(output_path(1:end-1))
save('n', 'n')
cd(code_folder)

%loading images
% If image numbers correspond to right to left stitching order
if right<left
    Images = uint8(zeros(n,n,left-right+1));
    index = 1;
    for m = 1:numel(S)
        if str2double(S(m).name(end-7:end-4)) >= right && str2double(S(m).name(end-7:end-4)) <= left
            F = fullfile(folder,S(m).name);
            x = imread(F);
            Images(:,:,index) = x;
            index = index+1;
        end
    end
    
% If images are in reverse order    
else
    Images = uint8(zeros(n,n,right-left+1));
    index = 1;
    for m = numel(S):-1:1
        if str2double(S(m).name(end-7:end-4)) <= right && str2double(S(m).name(end-7:end-4)) >= left
            F = fullfile(folder,S(m).name);
            x = imread(F);
            Images(:,:,index) = x;
            index = index+1;
        end
    end
end

mask = any(any(Images)); 
Images = Images(:,:,mask);
a = size(Images);

Images1 = Images(:,:,1:a(3)-1);
Images2 = Images(:,:,2:a(3));

% type 1 loss
loss = zeros(a(3)-1,length(k));

parpool(10);

parfor i=1:a(3)-1
    I1 = Images1(:,:,i);
    I2 = Images2(:,:,i);
    I1 = imresize(I1,1/res);
    I2 = imresize(I2,1/res);
    
    v = zeros(1, length(k));
    for m = 1:length(k)
        if k(m)~=0
            x1 = lensdistort(I1,k(m),'ftype',1,'bordertype','fit');
            x2 = lensdistort(I2,k(m),'ftype',1,'bordertype','fit');
        else 
            x1 = I1;
            x2 = I2;
        end
        v(m) = merge2_v5_for_loss_function(x1,x2,key_size,j_begin,i_travel,j_travel,hor);
    end
    loss(i,:) = v;
    
end

delete(gcp('nocreate'));

k1 = k;
loss1 = mean(loss,1);

%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('Type 1 done. Minimum loss %0.5e at k = %0.3f. \n',min(loss1),k1(loss1 == min(loss1)))
%%%%%%%%%%%%%%%%%%%%%%%%

% type 2 loss
loss = zeros(a(3)-1,length(k));

parpool(10);

parfor i=1:a(3)-1
    I1 = Images1(:,:,i);
    I2 = Images2(:,:,i);
    I1 = imresize(I1,1/res);
    I2 = imresize(I2,1/res);
    
    v = zeros(1, length(k));
    for m = 1:length(k)
        if k(m)~=0
            x1 = lensdistort(I1,k(m),'ftype',2,'bordertype','fit');
            x2 = lensdistort(I2,k(m),'ftype',2,'bordertype','fit');
        else 
            x1 = I1;
            x2 = I2;
        end
        v(m) = merge2_v5_for_loss_function(x1,x2,key_size,j_begin,i_travel,j_travel,hor);
    end
    loss(i,:) = v;
    
end

delete(gcp('nocreate'));

k2 = k;
loss2 = mean(loss,1);

%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('Type 2 done. Minimum loss %0.5e at k = %0.3f. \n',min(loss2),k2(loss2 == min(loss2)))
%%%%%%%%%%%%%%%%%%%%%%%%

% type 12 loss
loss = zeros(length(k),length(k),a(3)-1);

parpool(10);

parfor i=1:a(3)-1
    I1 = Images1(:,:,i);
    I2 = Images2(:,:,i);
    I1 = imresize(I1,1/res);
    I2 = imresize(I2,1/res);
    
    v = zeros(length(k), length(k));
    for m = 1:length(k)
        
        if k(m)~=0
            x1 = lensdistort(I1,k(m),'ftype',1,'bordertype','fit');
            x2 = lensdistort(I2,k(m),'ftype',1,'bordertype','fit');
        else 
            x1 = I1;
            x2 = I2;
        end
        
        for n = 1:length(k)
            if k(n)~=0
                x1 = lensdistort(x1,k(n),'ftype',2,'bordertype','fit');
                x2 = lensdistort(x2,k(n),'ftype',2,'bordertype','fit');
            end
            v(m,n) = merge2_v5_for_loss_function(x1,x2,key_size,j_begin,i_travel,j_travel,hor); 
        end
                        
    end
    
    loss(:,:,i) = v;
    
end

delete(gcp('nocreate'));

[k2_12,k1_12] = meshgrid(k);
loss12 = mean(loss,3);

%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('Type 12 done. Minimum loss %0.5e at k1 = %0.3f and k2 = %0.3f. \n',min(min(loss12)),k1_12(loss12 == min(min(loss12))),k2_12(loss12 == min(min(loss12))))
%%%%%%%%%%%%%%%%%%%%%%%%

% type 21 loss
loss = zeros(length(k),length(k),a(3)-1);

parpool(10);

parfor i=1:a(3)-1
    I1 = Images1(:,:,i);
    I2 = Images2(:,:,i);
    I1 = imresize(I1,1/res);
    I2 = imresize(I2,1/res);
    
    v = zeros(length(k), length(k));
    for m = 1:length(k)
        
        if k(m)~=0
            x1 = lensdistort(I1,k(m),'ftype',2,'bordertype','fit');
            x2 = lensdistort(I2,k(m),'ftype',2,'bordertype','fit');
        else 
            x1 = I1;
            x2 = I2;
        end
        
        for n = 1:length(k)
            if k(n)~=0
                x1 = lensdistort(x1,k(n),'ftype',1,'bordertype','fit');
                x2 = lensdistort(x2,k(n),'ftype',1,'bordertype','fit');
            end
            v(m,n) = merge2_v5_for_loss_function(x1,x2,key_size,j_begin,i_travel,j_travel,hor); 
        end
                        
    end
    
    loss(:,:,i) = v;
    
end

delete(gcp('nocreate'));

[k1_21,k2_21] = meshgrid(k);
loss21 = mean(loss,3);

%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('Type 21 done. Minimum loss %0.5e at k2 = %0.3f and k1 = %0.3f. \n',min(min(loss21)),k2_21(loss21 == min(min(loss21))),k2_21(loss21 == min(min(loss21))))
%%%%%%%%%%%%%%%%%%%%%%%%

% calculating the undistortion parameters
loss_min = min([min(loss1), min(loss2), min(min(loss12)), min(min(loss21))]);

if min(loss1) == loss_min
    
    loss_type = 1; 
    k1 = k1(loss1 == min(loss1)); 
    k2 = 0; 
    
elseif min(loss2) == loss_min
    
    loss_type = 2;
    k1 = 0;
    k2 = k2(loss2 == min(loss2));
    
elseif min(loss12) == loss_min
    
    loss_type = 12;
    k1 = k1_12(loss12 == min(min(loss12)));
    k2 = k2_12(loss12 == min(min(loss12)));
    
else 
    
    loss_type = 21;
    k1 = k1_21(loss21 == min(min(loss21)));
    k2 = k2_21(loss21 == min(min(loss21)));
    
end

% undistorting
for m = 1:numel(S)
    
    F = fullfile(folder,S(m).name);
    I = imread(F);
    
    if loss_type == 1
        if k1 ~= 0
            I = lensdistort(I,k1,'ftype',1,'bordertype','fit');
        end
    elseif loss_type == 2
        if k2 ~= 0
            I = lensdistort(I,k2,'ftype',2,'bordertype','fit');
        end
    elseif loss_type == 12
        if k1 ~= 0
            I = lensdistort(I,k1,'ftype',1,'bordertype','fit');
        end
        if k2 ~= 0
            I = lensdistort(I,k2,'ftype',2,'bordertype','fit');
        end
    else
        if k2 ~= 0
            I = lensdistort(I,k2,'ftype',2,'bordertype','fit');
        end
        if k1 ~= 0
            I = lensdistort(I,k1,'ftype',1,'bordertype','fit');
        end
    end
    
    imwrite(I,cat(2,output_path,F(im_name_begin:end)))
end