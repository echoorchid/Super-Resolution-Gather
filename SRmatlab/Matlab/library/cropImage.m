function im=cropImage(im,patch_size)
m=patch_size/2;
im=im(m:end-m+1,m:end-m+1,:);