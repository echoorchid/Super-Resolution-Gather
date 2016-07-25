% function to decompose an image into luminance and chrominance part
function [Im_luminance,Im_chrominance] = decomposeImage(im)

s = [0.2989,0.5870,0.1140];
A = null(repmat(s,[3,1]));

[height,width,nchannels] = size(im);
if nchannels ~= 3
    error('The input images must be a rgb image!');
end

im = reshape(im,[height*width,nchannels]);
Im_luminance = reshape(im*s',[height,width]);
Im_chrominance = reshape(im*A,[height,width,2]);

