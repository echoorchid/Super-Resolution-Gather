% function to extract pathces
function [Patches,Mask] = extractPatches(im,patchSize,overlapSize,gridPatchSize)

if exist('gridPatchSize','var')~=1
    gridPatchSize = patchSize;
end

% first assume that the image is gray scale
[height,width] = size(im);
intervalSize = gridPatchSize*2 - overlapSize;
[grid_xx, grid_yy] = meshgrid(gridPatchSize+1:intervalSize:width-gridPatchSize,...
                              gridPatchSize+1:intervalSize:height-gridPatchSize);
[h,w]=size(grid_xx);

patchDim = patchSize*2+1;
Patches  = zeros([patchDim^2,h,w]);
Mask     = Patches;

for i = 1:h
    for j= 1:w
        x0 = grid_xx(i,j); y0 = grid_yy(i,j);
        x1 = max(x0-patchSize,1);
        x2 = min(x0+patchSize,width);
        y1 = max(y0-patchSize,1);
        y2 = min(y0+patchSize,height);
        
        yindex = patchSize+1+y1-y0:patchSize+1+y2-y0;
        xindex = patchSize+1+x1-x0:patchSize+1+x2-x0;

        % set the patch
        patch                = zeros(patchDim);
        patch(yindex,xindex) = im(y1:y2,x1:x2);
        Patches(:,i,j)       = patch(:);
        
        % set the mask
        mask                = zeros(patchDim);
        mask(yindex,xindex) = 1;
        Mask(:,i,j)         = mask(:);
    end
end