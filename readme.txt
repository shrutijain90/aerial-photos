This repository can help you create a seamless panaromic image out of several overlapping images using a technique called image coregistration. This is different from typical image stitching algorithms such as SURF or SIFT, in that it uses a 'key' to match images instead of features. This offers more controlf over the merge, and can be useful when you want to avoid distortion caused by affine transformations. 

There are 3 files in this repository:
1) merge2_v6.m - This is the function employed by the other 2 files
2) making_strips.m - Use this file to stitch images from right to left
3) making_strips_geolocated.m - Use this file to stitch geolocated images from right to left, while updating geolocation indices. 
