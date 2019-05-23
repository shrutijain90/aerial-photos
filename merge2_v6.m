function ij = merge2_v6(x1,x2,key_size,j_begin,i_travel,j_travel,hor,res)

x1 = imresize(x1,1/res);
x2 = imresize(x2,1/res);

x1 = double(x1);
x2 = double(x2);

n = size(x1,1);
size_j = size(x2,2);

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

overlap_j = j_res+size_j-j_begin+1;
shift = i_begin1-i_res1; %vertical

ij = zeros(1,2);
ij(1,1) = res*overlap_j;
ij(1,2) = res*shift;

end
