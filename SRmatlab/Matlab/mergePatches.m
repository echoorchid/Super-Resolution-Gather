% function to merge all the patches onto one image
function im = mergePatches(Patches,overlapSize,width,height)
[nDim,h,w]=size(Patches);

patchDim = sqrt(nDim);
patchSize  = (patchDim-1)/2;
intervalSize = patchSize*2-overlapSize;

% set the dimension for the output image
if exist('width','var')~=1
    width = patchDim*w - (overlapSize+1)*(w-1);
end
if exist('height','var')~=1
    height = patchDim*h - (overlapSize+1)*(h-1);
end
im = zeros([height,width]);
weight = zeros([height,width]);

% set the individual mask
foo = linspace(0,1,overlapSize+2);
foo = foo(2:end-1);
mask = [foo ones(1,patchDim-overlapSize*2) foo(end:-1:1)];
mask = kron(mask,mask');

for i=1:h
    for j=1:w
        x = (j-1)*intervalSize+patchSize+1;
        y = (i-1)*intervalSize+patchSize+1;
        xindex = x-patchSize:x+patchSize;
        yindex = y-patchSize:y+patchSize;
        im(yindex,xindex) = im(yindex,xindex) + reshape(Patches(:,i,j),[patchDim,patchDim]).*mask;
        weight(yindex,xindex) = weight(yindex,xindex) + mask;
    end
end
index = (im==0);
im = im./weight;
im(index)=0;