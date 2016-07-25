% function to set the environment for the super resolution project
% Ce Liu
% Microsoft Research New England
% Nov 2010

% set the home path
% if ispc
%     setting.Path.Home = 'D:\Workstation\SuperResolution\';
% else
%     setting.Path.Home = '/csail/vision-billf3/Ce/CVPR2010/SuperResolution/';
%     addpath('/csail/vision-billf3/Ce/CVPR2010/library');
% end
setting.Path.Home='../';


% add the library for kdtree
setting.Path.kdtree = fullfile(setting.Path.Home,'Matlab','kdtree');
setting.Path.library = fullfile(setting.Path.Home,'Matlab','library');
addpath(setting.Path.kdtree);
addpath(setting.Path.library);

% if the kdtree library is not there then compile them
foo = pwd;
cd(setting.Path.kdtree);
fprintf('Compile Kdtree library...');
compileKdtree;
fprintf('done!\n');
cd(foo);

% set the parameters
setting.Para.PatchSize.L = 7; % the low res patch should be equal to or greater than the high res
setting.Para.PatchSize.H = 4;
setting.Para.intervalSize = 3; % the interval size used to sample patches from training images
setting.Para.OverlapSize = 2;
setting.Para.NN = 30;          % the number of nearest neighbors
setting.IsContrastNormalize = true; % contrast normalization 
setting.IsKdtree = true;
setting.IsKdtreeGenerated = false;
setting.IsPCA = true;

% set the path
setting.Path.Database           = fullfile(setting.Path.Home,'Database','Berkeley');
setting.Path.Training.Home      = fullfile(setting.Path.Database,'Training');
setting.Path.Training.Image     = fullfile(setting.Path.Training.Home,'Image');
setting.Path.Test.Home          = fullfile(setting.Path.Database,'Test');
setting.Path.Test.Image         = fullfile(setting.Path.Test.Home,'Image');

setting.Path.Training.Laplacian = fullfile(setting.Path.Training.Home,'Laplacian');
setting.Path.Test.Laplacian     = fullfile(setting.Path.Test.Home,'Laplacian');
setting.Path.Training.Bandpass  = fullfile(setting.Path.Training.Home,'Bandpass');
setting.Path.Test.Bandpass      = fullfile(setting.Path.Test.Home,'Bandpass');

setting.Path.Test.Candidates    = fullfile(setting.Path.Test.Home,'Candidates');
setting.Path.Test.Result        = fullfile(setting.Path.Test.Home,'Result');

if setting.IsContrastNormalize
    setting.Path.Test.Candidates    = fullfile(setting.Path.Test.Candidates,'ContrastNormalized');
    setting.Path.Test.Result = fullfile(setting.Path.Test.Result,'ContrastNormalized');
    setting.Filename.Database = fullfile(setting.Path.Training.Home,'database_cn.mat');
else
    setting.Path.Test.Candidates    = fullfile(setting.Path.Test.Candidates,'Straightforward');
    setting.Path.Test.Result = fullfile(setting.Path.Test.Result,'Straightforward');
    setting.Filename.Database = fullfile(setting.Path.Training.Home,'database_s.mat');
end

if exist(setting.Path.Training.Laplacian,'dir')~=7
    mkdir(setting.Path.Training.Laplacian);
end
if exist(setting.Path.Test.Laplacian,'dir')~=7
    mkdir(setting.Path.Test.Laplacian);
end
if exist(setting.Path.Training.Bandpass,'dir')~=7
    mkdir(setting.Path.Training.Bandpass);
end
if exist(setting.Path.Test.Bandpass,'dir')~=7
    mkdir(setting.Path.Test.Bandpass);
end

if exist(setting.Path.Test.Candidates,'dir')~=7
    mkdir(setting.Path.Test.Candidates);
end
if exist(setting.Path.Test.Result,'dir')~=7
    mkdir(setting.Path.Test.Result);
end



