% function to add boundary to an image
function Im = imaddbd(im,color,margin)

if exist('margin','var')~=1
    margin = 2;
end
[h,w,nchannels] = size(im);

if nchannels == 1
    im = repmat(im,[1 1 3]);
end
if isfloat(im)~=1
    im = im2double(im);
end

Im = repmat(reshape(color,[1 1 3]),[h+margin*2,w+margin*2,1]);
Im(margin+1:margin+h,margin+1:margin+w,:) = im;