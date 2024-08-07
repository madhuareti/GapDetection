#!/bin/bash
code_file_name="point_iter_anal_noGT_dh_v6.m"
run_file_name="run_dh_v6.bash"
sed -i '/DIR_ITR/d' ~/.bashrc &
bashrc_pid=$!
wait $bashrc_pid
sed -i '/DATA_ITR/d' ~/.bashrc &
bashrc_pid=$!
wait $bashrc_pid
dir_ct=0
file_ct=0
echo 'start'
data_dir="/home/grads/m/mareti/madhu_workspace/GapDetect/data/disaster_city/sample_data_complete_1007"
num_files=$(ls $data_dir | wc -l)
let cond=$num_files
echo "there are $cond files"
echo 'export DIR_ITR='"$cond" >> ~/.bashrc # start from up to down
source ~/.bashrc &
bashrc_pid=$!
wait $bashrc_pid
key_str_dir="ip_sample_itr = "
key_str_file="ip_data_dir_itr = "
ignore_str_dir="key_str_dir""ip_sample_itr "
replace_str_dir="$key_str_dir""$num_files"" + "
# clean the file from any previous edits
num_occur=0
for itr in {1..1000}
do
	check_str_dir="$key_str_dir""$itr"" + "
	let num_occur=$(cat "$code_file_name" | grep "$check_str_dir" | wc -l)
	if [ $num_occur -eq 1 ]
	then
		sed -i "s/$check_str_dir/$key_str_dir/g" "./""$code_file_name"
		break
	fi
done
# edit the matlab code to match the number of unique directories
sed -i "s/$key_str_dir/$replace_str_dir/g" "./""$code_file_name" 
rep_ct=1
let dir_ct=$DIR_ITR
let file_ct=$DATA_ITR
echo "dir_ct = $dir_ct"
echo "file_ct = $file_ct"
while [[ $dir_ct -le $cond ]]
do
	# check if matlab is running
	mat_ct=$(ps | grep MATLAB | wc -l)
	if [ $mat_ct -le 1 ] 
	then
		# main directory level status check	
		cur_str_dir="$key_str_dir""$dir_ct"" "
		if [[ $dir_ct -lt $num_files ]]
                then
			source ~/.bashrc &
			bashrc_pid=$!
			wait $bashrc_pid
		fi
		if [[ $dir_ct -ge $DIR_ITR ]] # check if the analysis directory was moved to the next one
		then
			echo "enter dir loop"
			dir_ct=$(($DIR_ITR-1))
			echo "dir_ct = $dir_ct"
			replace_str_dir="$key_str_dir""$dir_ct"" "
			echo "cur str dir = $cur_str_dir"
			echo "replace str dir = $replace_str_dir"
			sed -i "s/$cur_str_dir/$replace_str_dir/g" "./""$code_file_name" &
			sed_code_pid=$!
			wait $sed_code_pid
		fi
		# secondary directory(individual file) level data check
		cur_str_file="$key_str_file""$file_ct"" "
		if [ $file_ct -gt 1 ] # check if the analysis directory was moved to the next one
		then
			echo "enter file loop"
			file_ct=$(($DATA_ITR+1))
			echo "file_ct = $file_ct"
			replace_str_file="$key_str_file""$file_ct"" "
			echo "cur str file = $cur_str_file"
			echo "replace str file = $replace_str_file"
			sed -i "s/$cur_str_file/$replace_str_file/g" "./""$code_file_name" &
			sed_code_pid=$!
			wait $sed_code_pid
		fi
		# run the code once these modifications are done
		bash $run_file_name &
		mat_pid=$!
		echo "matlab was intialized"
		while kill -s 0 $mat_pid; do
			sleep 120
		done
		echo "iteration $ct complete"

		let rep_ct++
		if [[ $rep_ct -eq 100 ]]
        	then
                	echo "terminating program due to high repetitions"
                	break
        	fi
	else
		while kill -s 0 $mat_pid; do
			sleep 240
		done
	fi
done
cur_str_dir="$key_str_dir""$ct"" "
replace_str_dir="$key_str_dir""$num_files"" "
sed -i "s/$cur_str_dir/$replace_str_dir/g" "./""$code_file_name" &
cur_str_file="$cur_str_file""$file_ct"" "
replace_str_file="$key_str_file""1"" "
sed -i "s/$cur_str_file/$replace_str_file/g" "./""$code_file_name" &


