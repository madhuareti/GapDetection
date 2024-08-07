clear;
clc;
close all;
%% Parpool
if ~isempty(gcp('nocreate'))
    delete(gcp('nocreate'));
end
try
   p = parcluster('local');
   parpool(p,feature('numcores'));
catch Err
   disp('parpool intialization failed, quitting matlab');
   quit; % quitting matlab if fails
end
%% Parameters
num_iter = 10; % number of iterations to be performed
nn_mult_vec = (1:0.5:12)'; 
ThrshMultFacArrTemp = (0.1:0.1:2.3)';
nn_mult_vec_str = strcat( strrep(string(min(nn_mult_vec)),'.',''),"_", ...
    strrep(string(nn_mult_vec(2)-nn_mult_vec(1)),'.',''),"_", ...
    strrep(string(max(nn_mult_vec)),'.',''));
thrsh_mult_vec_str = strcat( strrep(string(min(ThrshMultFacArrTemp)),'.',''),"_", ...
    strrep(string(ThrshMultFacArrTemp(2)-ThrshMultFacArrTemp(1)),'.',''),"_", ...
    strrep(string(max(ThrshMultFacArrTemp)),'.',''));
slash_key = 'windows';
switch slash_key
    case 'linux'
        slsh = '/';
    case 'windows'
        slsh = '\';
end
rdrive_str = "\\coe-fs.engr.tamu.edu\research\MEEN\Hasnain_Zohaib\Students\Areti_Madhu_Dhana\GapDetection\3d_point_cloud_geometry\GapDetect\";
local_str = "/home/grads/m/mareti/madhu_workspace/GapDetect/";
save_str1 = strcat("results",slsh,"OITRA",slsh,"panel1_trail1",slsh);

