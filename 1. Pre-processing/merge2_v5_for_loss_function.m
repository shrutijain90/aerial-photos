function ij = merge2_v5_for_loss_function(x1,x2,key_size,j_begin,i_travel,j_travel,hor)
%Merges 2 images horizontally, x2 (left) is added to x1 (right)
%Chooses a particular region to find best match
%hor refers to starting point (for matching) on image 1 
%key_size: image_size/~3 (image_size after reducing resolution)
%j_begin: image_size/2 + image_size/~11.5 (image_size after reducing resolution)
%i_travel: image_size/~7.5 (image_size after reducing resolution)
%j_travel: image_size/~3.5 (image_size after reducing resolution)

x1 = double(x1);
x2 = double(x2);

n = size(x2,1);

i_begin1 = ceil(i_travel/2) + floor(n/20);
i_begin2 = floor(n/2)-floor(key_size/2);
i_begin3 = n - ceil(i_travel/2) - key_size - floor(n/20);

key1 = x2(i_begin1:i_begin1+key_size-1,j_begin:j_begin+key_size-1);
key2 = x2(i_begin2:i_begin2+key_size-1,j_begin:j_begin+key_size-1);
key3 = x2(i_begin3:i_begin3+key_size-1,j_begin:j_begin+key_size-1);

k = 1;
diff = NaN(i_travel*j_travel,3);  

for j= hor:hor-1+j_travel  
    for i=1:i_travel 
        i_start1 = i-1+i_begin1-(i_travel-1)/2;
        b1 = x1(i_start1:(i_start1+key_size-1),j:(j+key_size-1));
        
        i_start2 = i-1+i_begin2-(i_travel-1)/2;
        b2 = x1(i_start2:(i_start2+key_size-1),j:(j+key_size-1));
        
        i_start3 = i-1+i_begin3-(i_travel-1)/2;
        b3 = x1(i_start3:(i_start3+key_size-1),j:(j+key_size-1));
        
        diff(k,1) = sumabs(b1 - key1); %minimize
        diff(k,2) = sumabs(b2 - key2); %minimize
        diff(k,3) = sumabs(b3 - key3); %minimize
        
        k=k+1;
    end
end

diff_tot = diff(:,1).^2 + diff(:,2).^2 + diff(:,3).^2;
k_res = find(diff_tot == min(diff_tot));

i_res1 = i_begin1-(i_travel-1)/2 + rem(k_res-1,i_travel);
j_res = hor + floor(k_res/i_travel);

a = x2(i_begin1:i_begin1+200-1,j_begin:j_begin+100-1);
b = x1(i_res1:i_res1+200-1,j_res:j_res+100-1);

ij = sumsqr(a-b);

end