#!/bin/bash
# change image file's md5


usage() { 
	echo "Usage: "
	echo "  $0 [-d <iOS project path>] [-t <png|jpg|all>] [-q <compress image quality>]"; 
	echo "  -d iOS project path | required";
	echo "  -t type of images to compress, default is png";
	echo "  -q compress quality, default is 99";
}

prepare_working_dir() {
	if [[ ! -d compress_working_dir ]]; then
		mkdir compress_working_dir
	fi
}

clear_working_dir() {
	if [[ -d ./compress_working_dir ]]; then
		rm -rf ./compress_working_dir
	fi
}

convert_images() {
	project_dir=$1
	image_type=$2
	quality=$3
	
	if [ -z "${project_dir}" ]; then
		usage;
		exit 0;
	fi

	if [[ -z "${image_type}" ]]; then
		image_type="png"
	fi

	if [[ -z "${quality}" ]]; then
		quality="99"
	fi	
	
	echo "project_dir:  ${project_dir}"
	echo "image_type :  ${image_type}"
	echo "quality    :  ${quality}"
	
	files=$(find $project_dir -type f -iregex ".*$image_type\$" | grep -v .git)
	for file in $files
	do
		compressed_file=$(echo $file | awk -F '/' '{print $(NF-1)"_"$NF}')		
		echo "convert $file -quality $quality compress_working_dir/$compressed_file"
		convert $file -quality $quality compress_working_dir/$compressed_file
		mv compress_working_dir/$compressed_file $file
		# echo "i will mv $file to conver_image_tmp/$compressed_file"
	done
}

while getopts ":d:t:q:" o; do
    case "${o}" in
        d)
            project_dir=${OPTARG}
            ;;
        t)
            image_type=${OPTARG}
            ;;
		q)
			quality=${OPTARG}
			;;
        *)
            # usage
            ;;
    esac
done

prepare_working_dir
convert_images $project_dir $image_type $quality
clear_working_dir
