% function to contrast normalize an image
function Im = imcontrastnormalize(im,wsize)

[height,width] = size(im);

H = zeros(height,width);

for i = 1:height
    for j = 1:width
        x1 = max(j-wsize,1);
        y1 = max(i-wsize,1);
        x2 = min(j+wsize,width);
        y2 = min(i+wsize,height);
        patch = im(y1:y2,x1:x2);
        H(i,j) = std(patch(:));
    end
end

Im = im./(H+0.01);