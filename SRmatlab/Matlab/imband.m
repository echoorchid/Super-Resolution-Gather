% function to generate the high, low and band-pass channels of an image
% im = im_lowlow + im_bandpass + im_laplacian
function [im_laplacian,im_bandpass,im_lowlow]=imband(im)

[height,width,nchannels]=size(im);
if isfloat(im)
    im = im2double(im);
end

% downsample 
im_Low = imresize(imfilter(im,fspecial('gaussian',7,1),'same','replicate'),0.25,'bicubic');

% upsample
im_low = imresize(im_Low,[height,width],'bicubic');

% obtain laplacian
im_laplacian = im - im_low;

% downsample to even lower res
im_lowlow = imfilter(im,fspecial('gaussian',25,5),'same','replicate');
%im_lowlow = imresize(imfilter(im_Low,fspecial('gaussian',9,1.5),'same','replicate'),0.25,'bicubic');
%im_lowlow = imresize(im_lowlow,[height,width],'bicubic');

% get the band-pass 
im_bandpass = im_low - im_lowlow;
