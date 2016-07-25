% function to compose a luminance and chrominance image into one color image
function im = composeImage(Im_luminance,Im_chrominance)

s = [0.2989,0.5870,0.1140];
A = null(repmat(s,[3,1]));

[height,width] = size(Im_luminance);

im = zeros(height,width,3);

Im_luminance = reshape(Im_luminance,[height*width,1]);
Im_chrominance = reshape(Im_chrominance,[height*width,2]);

im = Im_luminance*s*2.2376 + Im_chrominance*A';

im = reshape(im,[height,width,3]);