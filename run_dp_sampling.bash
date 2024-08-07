#!/bin/bash
# data paths
# define top most directory path
main_dir="/home/grads/m/mareti/GapDetect/"
sub_dir="data/disaster_city/raw_data_complete/mat_xyz/"
dir_str="$main_dir""$sub_dir"
# output paths
op_save_val="op_dp_930"
file_ext=".txt"
op_save_str="$op_save_val""$file_ext"
if test -f "$op_save_str";then
# check if the file was already replaced
	upd_str_val="$op_save_str""_old"
	num_old=$(ls |"$main_dir" | grep "$upd_str_val" | wc -l)
	upd_val=$((num_old+1))
	mv "$op_save_str" "$op_save_val""_old""$upd_val"".txt"
fi
nohup matlab -nosplash -nodisplay -nodesktop -r "clear; addpath(genpath('$main_dir'));distcomp.feature('LocalUseMpiexec',false);run('douglaspuecker_trail5_linux.m');quit;" >> "$op_save_str"

