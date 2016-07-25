% function to generate training for super resolution
setEnvironment;

filelist = readImages(setting.Path.Training.Image);

if isempty(filelist)
    error(['No images detected in ' setting.Path.Training.Image '!']);
end

dictionary = [];
dictionary.lowres = [];
dictionary.highres = [];

patchSizeLow = setting.Para.PatchSize.L;
patchSizeHigh = setting.Para.PatchSize.H;
intervalSize = setting.Para.intervalSize;

fprintf('Generating training database...\n');
for k=1:length(filelist)
    fprintf('\tProcessing %s...',filelist(k).name);
    
    im = imread(fullfile(setting.Path.Training.Image,filelist(k).name));
    
    % convert the image from color to gray
    im = im2double(rgb2gray(im));

    [im_laplacian,im_bandpass]=imband(im);
    
    % obtain the dictionary
    patches = im2patches(im_bandpass, patchSizeLow, intervalSize);
    dictionary.lowres = [dictionary.lowres; patches];
    patches = im2patches(im_laplacian, patchSizeHigh, intervalSize,[],patchSizeLow);
    dictionary.highres = [dictionary.highres; patches];
    
    % save the laplacian images just for sanity check
    im_laplacian = im_laplacian/2 + 0.5;
    imwrite(im_laplacian,fullfile(setting.Path.Training.Laplacian,filelist(k).name));
    % save the band-pass
    im_bandpass  = im_bandpass/2 + 0.5;
    imwrite(im_bandpass,fullfile(setting.Path.Training.Bandpass,filelist(k).name));
    
    fprintf('done!\n');
end


%-----------------------------------------------------------
% sanity check for the dictionaries
% we are going to display an image of the patches
%-----------------------------------------------------------
nSamples = size(dictionary.lowres,1);
energy = sum(abs(dictionary.lowres),2);
[foo,idx]=sort(energy,'descend');
N = round(nSamples/10);
idx = idx(1:N);
index = idx(randperm(N));

nRow = 10; nCol = 10;

cellSize = patchSizeLow*2+3;
%im_low = ones(nRow*cellSize+2,nCol*cellSize+2)*0.5;
im_low = ones(nRow*cellSize+2,nCol*cellSize+2)*0;
im_high = im_low;

winLenLow = patchSizeLow*2+1;
winLenHigh = patchSizeHigh*2+1;

for i=1:nRow
    for j=1:nCol
        patch_low = reshape(dictionary.lowres(index((i-1)*nCol+j),:),[winLenLow,winLenLow]);
        patch_high = reshape(dictionary.highres(index((i-1)*nCol+j),:),[winLenHigh,winLenHigh]);
        
        patch_low = patch_low/4+0.5;
        patch_high = patch_high/4+0.5;
        
        y = (i-1)*cellSize+patchSizeLow+3;
        x = (j-1)*cellSize+patchSizeLow+3;
        im_low(y-patchSizeLow:y+patchSizeLow,x-patchSizeLow:x+patchSizeLow) = patch_low;
        im_high(y-patchSizeHigh:y+patchSizeHigh,x-patchSizeHigh:x+patchSizeHigh) = patch_high;
    end
end
figure;imshow(im_low);
figure;imshow(im_high);

%---------------------------------------------------------------
% contrast normalize the low-res patches
%---------------------------------------------------------------
if setting.IsContrastNormalize
    fprintf('Contrast normalization...');
    % compute the standard deviation of each low-res patch
    lowres_std = std(dictionary.lowres,[],2);
    % this /3 is arbitrary, maybe we take a percetage
%     dictionary.lowres_std_max = median(lowres_std)/2; 
%     dictionary.scale = max(lowres_std,dictionary.lowres_std_max)/dictionary.lowres_std_max;
    dictionary.scale = lowres_std+0.0001;
    % normalize both low- and high-res patches based on the scale
    dictionary.lowres = dictionary.lowres./repmat(dictionary.scale,[1 size(dictionary.lowres,2)]);
    dictionary.highres = dictionary.highres./repmat(dictionary.scale,[1 size(dictionary.highres,2)]);
    fprintf('done!\n');
end

% save the database and the information
fprintf('Save training data (may take a while)...');
save(setting.Filename.Database,'-struct','dictionary');
imwrite(im_low,fullfile(setting.Path.Training.Home,'dictionary_low.bmp'));
imwrite(im_high,fullfile(setting.Path.Training.Home,'dictionary_high.bmp'));
fprintf('done!\n');