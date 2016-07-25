% function for super resolution

setEnvironment;

% load the training data
if exist('dictionary','var')~=1
    if exist(setting.Filename.Database,'file')==2
        dictionary = load(setting.Filename.Database);
    else
        GenerateTraining;
    end
end
nSamples = size(dictionary.lowres,1);

% the parameters for the chrominance part


% load the test image
filelist = readImages(setting.Path.Test.Image);


for k=1:length(filelist)
%for k = 4:4
    fprintf('\nProcessing %s...\n',filelist(k).name);
    filename = fullfile(setting.Path.Test.Result,filelist(k).name(1:end-4));
    
    
    im = imread(fullfile(setting.Path.Test.Image,filelist(k).name));
    Im = imresize(imfilter(im,fspecial('gaussian',7,1),'same','replicate'),0.25,'bicubic');
    imwrite(Im,[filename '_input.jpg'],'quality',100);
    
    im = im2double(im);
    [im,im_color] = decomposeImage(im);
    [height,width]=size(im);

    im_color = imresize(imfilter(im_color,fspecial('gaussian',7,1),'same','replicate'),0.25,'bicubic');
    im_color = imresize(im_color,[height,width],'bicubic');
    
    %-------------------------------------------------------------------
    % separate the image into several bands
    % we will infer the high-res band from im_bandpass
    %-------------------------------------------------------------------
    [im_laplacian,im_bandpass,im_lowlow]=imband(im);
    im_low = im_bandpass + im_lowlow;
    imwrite(composeImage(im_low,im_color),[filename '_lowres.jpg'],'quality',100);
    imwrite(im_low,[filename '_lowres_gray.jpg'],'quality',100);
    imwrite(im_laplacian+0.5,[filename '_laplacian.jpg'],'quality',100);
    imwrite(im,[filename '_highres.jpg'],'quality',100);
    imwrite(im_bandpass+0.5,[filename '_bandpass.jpg'],'quality',100);
    foo = imcontrastnormalize(im_bandpass,setting.Para.PatchSize.L);
    imwrite(foo/(max(abs(foo(:)))+0.5)+0.5,[filename '_bandpass_cn.jpg'],'quality',100);
    
    %-------------------------------------------------------------------
    % divide the image into patches and search for the nearest neighbors
    % in the training dataset
    %-------------------------------------------------------------------
    patchSizeH  = setting.Para.PatchSize.H;
    patchSizeL  = setting.Para.PatchSize.L;
    overlapSize = setting.Para.OverlapSize;
    NN          = setting.Para.NN;
    intervalSize = patchSizeH*2 - setting.Para.OverlapSize;

    [Patches,Mask] = extractPatches(im_bandpass,patchSizeL,overlapSize,patchSizeH);
    [dim,h,w]=size(Patches);
    
    % if contrast normalization is turned on, then normalize the patches
    if setting.IsContrastNormalize
        foo = squeeze(std(Patches));
        %scale = max(foo,dictionary.lowres_std_max)/dictionary.lowres_std_max;
        scale = foo + 0.0001;
        Patches = Patches./repmat(reshape(scale,[1 h w]),[dim 1 1]);
    end

    if exist(fullfile(setting.Path.Test.Candidates,[filelist(k).name(1:end-3) 'mat']),'file')~=2
        if setting.IsKdtree && ~setting.IsKdtreeGenerated
            
            foo = dictionary.lowres;
            if setting.IsPCA
                dictionary.mean = mean(foo);
                foo = foo - repmat(dictionary.mean,[nSamples,1]);
                [S,V] = eig(foo'*foo);
                V = diag(V);
                V = V(end:-1:1);
                S = S(:,end:-1:1);
                dictionary.rDim = 20;
                dictionary.S = S(:,1:dictionary.rDim);
                foo = foo*dictionary.S;
            end
            fprintf('Generating kdtree...');
            tree = kdtree_build(foo);
            fprintf('done!\n');
            setting.IsKdtreeGenerated = true;
        end
        fprintf('Constructing Markov Network (retrieving nearest neighbors from the database):\n');
        for i=1:h
            fprintf('\tRow %d (out of %d)...',i,h);
            tic;
            for j=1:w
                % use the patch and mask as the key to search the training data
                if setting.IsKdtree
                    if setting.IsPCA
                        foo = (Patches(:,i,j)'-dictionary.mean)*dictionary.S;
                        idx = kdtree_k_nearest_neighbors(tree,foo,setting.Para.NN*4);
                        Dist = sum(((repmat(Patches(:,i,j)',[NN*4,1])-dictionary.lowres(idx,:))).^2,2);
                        [foo, index] = sort(Dist,'ascend');
                        idx = idx(index(1:NN));
                    else
                        idx = kdtree_k_nearest_neighbors(tree,Patches(:,i,j)',setting.Para.NN);
                    end
                    idx = idx(end:-1:1);
                else
                    % retrieve the best candidates
                    Dist       = sum(((repmat(Patches(:,i,j)',[nSamples,1])-dictionary.lowres).^2).*repmat(Mask(:,i,j)',[nSamples,1]),2);
                    [foo, idx] = sort(Dist,'ascend');
                    idx        = idx(1:setting.Para.NN);
                end            
                candidates(i,j).idx     = idx;
                candidates(i,j).patches = dictionary.highres(idx,:);
                if setting.IsContrastNormalize
                    candidates(i,j).patches = candidates(i,j).patches*scale(i,j);
                end
            end
            t = toc;
            fprintf('t=%f done!\n',t);
        end
        % save the candidates
        save(fullfile(setting.Path.Test.Candidates,[filelist(k).name(1:end-3) 'mat']),'candidates');
    else
        load(fullfile(setting.Path.Test.Candidates,[filelist(k).name(1:end-3) 'mat']));
    end

    %-------------------------------------------------------------------
    % put all the patches together on a grid
    %-------------------------------------------------------------------
    patchDim = patchSizeH*2+1;
    PatchesIID = zeros(patchDim^2,h,w);
    for i=1:h
        for j=1:w
            PatchesIID(:,i,j) = candidates(i,j).patches(1,:)';
        end
    end

    % the result of just applying the iid best matches
    Im_high = mergePatches(PatchesIID,setting.Para.OverlapSize,width,height);
    figure;imshow(composeImage(Im_high+im_low,im_color));
    imwrite(composeImage(Im_high+im_low,im_color),[filename '_iid.jpg'],'quality',100);
    imwrite(Im_high+0.5,[filename '_idd_highfrequency.jpg'],'quality',100);

   
    %----------------------------------------------------------------------
    % compute the compatibility function to prepare for belief propagation
    %----------------------------------------------------------------------

    % compute CO
    fprintf('Constructing data compatibility function...');
    nDim = setting.Para.NN;
    CO = zeros(nDim,h,w);
    for i=1:h
        for j=1:w
            lowres = dictionary.lowres(candidates(i,j).idx,:);
            if setting.IsContrastNormalize
                CO(:,i,j) = sum((repmat(Patches(:,i,j)',[nDim,1])-lowres).^2,2)*scale(i,j)^2;
            else
                CO(:,i,j) = sum((repmat(Patches(:,i,j)',[nDim,1])-lowres).^2,2);
            end
        end
    end
    fprintf('done!\n');

    
    % get the patches from the low-res image
    PatchesLowRes = extractPatches(im_low,patchSizeH,overlapSize);
    % add the low res onto the patches
    for i=1:h
        for j=1:w
            candidates(i,j).patchesFull = double(candidates(i,j).patches) + ...
                                          repmat(PatchesLowRes(:,i,j)',[NN,1]);
        end
    end

    fprintf('Constructin spatial compatibility...');
    % compute CM_h
    CM_h = zeros([NN, NN, h, w-1]);
    for i=1:h
        for j=1:w-1
            foo1 = reshape(candidates(i,j).patchesFull',[patchDim,patchDim,NN]);
            foo2 = reshape(candidates(i,j+1).patchesFull',[patchDim,patchDim,NN]);
            foo1 = reshape(foo1(:,end-overlapSize+1:end,:),[patchDim*overlapSize,NN]);
            foo2 = reshape(foo2(:,1:overlapSize,:),[patchDim*overlapSize,NN]);
            foo1 = repmat(foo1(:),[1,NN]);
            foo2 = repmat(foo2,[NN,1]);
            CM_h(:,:,i,j) = reshape(sum(reshape((foo1-foo2).^2,[patchDim*overlapSize,NN^2]),1),[NN,NN]);
        end
    end

    % compute CM_v
    CM_v = zeros([NN, NN, h-1, w]);
    for i=1:h-1
        for j=1:w
            foo1 = reshape(candidates(i,j).patchesFull',[patchDim,patchDim,NN]);
            foo2 = reshape(candidates(i+1,j).patchesFull',[patchDim,patchDim,NN]);
            foo1 = reshape(foo1(end-overlapSize+1:end,:,:),[patchDim*overlapSize,NN]);
            foo2 = reshape(foo2(1:overlapSize,:,:),[patchDim*overlapSize,NN]);
            foo1 = repmat(foo1(:),[1,NN]);
            foo2 = repmat(foo2,[NN,1]);
            CM_v(:,:,i,j) = reshape(sum(reshape((foo1-foo2).^2,[patchDim*overlapSize,NN^2]),1),[NN,NN]);
        end
    end
    fprintf('done!\n');

    %----------------------------------------------------------------------
    % run belief propagation
    %----------------------------------------------------------------------
    alpha = 0.5;
    nIterations = [1,5,10,30,50];
    for ii = 1:length(nIterations)
        [IDX,En] = immaxproduct(CO,CM_h*alpha,CM_v*alpha,nIterations(ii),0.5);

        PatchesBP = zeros(patchDim^2,h,w);
        for i=1:h
            for j=1:w
                PatchesBP(:,i,j) = candidates(i,j).patches(IDX(i,j),:)';
            end
        end

        % the result of just applying the iid best matches
        Im_high = mergePatches(PatchesBP,overlapSize,width,height);
        
        figure;imshow(composeImage(Im_high+im_low,im_color));drawnow;
        
        imwrite(Im_high+0.5,[filename '_' num2str(nIterations(ii)) '_bp_highres.jpg'],'quality',100);
        imwrite(Im_high+im_low,[filename '_' num2str(nIterations(ii)) '_bp_gray.jpg'],'quality',100);
        imwrite(composeImage(Im_high+im_low,im_color),[filename '_' num2str(nIterations(ii)) '_color.jpg'],'quality',100);
    end
    imwrite(Im_high+0.5,[filename '_highfrequency.jpg'],'quality',100);
    figure;plot(En);
    saveas(gcf,[filename '_convergence.jpg']);
    close all;
end

if setting.IsKdtreeGenerated
    kdtree_delete(tree);
end