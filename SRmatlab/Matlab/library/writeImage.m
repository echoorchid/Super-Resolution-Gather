% function to write image data to a format that can be recognized by Image
% class developed by Ce Liu
function writeImage(im,filename,isderivative)
if ~isfloat(im)
    im=im2double(im);
else if ~isa(im,'double')
        im=double(im);
    end
end

if exist('isderivative','var')~=1
    isderivative=false;
end
[height,width,nchannels]=size(im);
file=fopen(filename,'w');

% write the dimensions of the image
fwrite(file,width,'int32');
fwrite(file,height,'int32');
fwrite(file,nchannels,'int32');
fwrite(file,isderivative,'bool');

for i=1:nchannels
    Im(:,:,i)=im(:,:,i)';
end

% write the image data
Im=reshape(Im,[width*height,nchannels])';
fwrite(file,Im,'double');
fclose(file);
