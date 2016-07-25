% function to add boundary to an image
% written by Ce Liu
% Oct 22, 2008
function Im=imaddboundary(im,margin,color)
if exist('margin','var')~=1
    margin=2;
end
[height,width,nchannels]=size(im);
if exist('color','var')~=1
    color=zeros(1,nchannels);
end
if size(color,1)>size(color,2)
    color=color';
end
h=height+margin*2;
w=width+margin*2;
Im=reshape(kron(ones(h*w,1),color),[h,w,nchannels]);
Im(margin+1:margin+height,margin+1:margin+width,:)=im;
