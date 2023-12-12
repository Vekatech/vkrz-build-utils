#!/bin/bash

VERSION=0.2.0

# Make sure that the following packages have been downloaded from the official website
# RZ/G Verified Linux Package [5.10-CIP]  V3.0.4
REN_LINUX_BSP_PKG="RTK0EF0045Z0024AZJ-v3.0.4"
SUFFIX_ZIP=".zip"

# RZ MPU Graphics Library V1.1.0 Unrestricted Version
REN_GPU_MALI_LIB_PKG="RTK0EF0045Z14001ZJ-v1.1.0_rzv_EN"
# RZ MPU Graphics Library Evaluation Version V1.1.0
REN_GPU_MALI_LIB_PKG_EVAL="RTK0EF0045Z13001ZJ-v1.1.0_EN"

# RZ MPU Video Codec Library v1.1.0 Unrestricted Version
REN_VEDIO_CODEC_LIB_PKG="RTK0EF0045Z16001ZJ-v1.1.0_rzv_EN"
# RZ MPU Video Codec Library Evaluation Version V1.0
REN_VEDIO_CODEC_LIB_PKG_EVAL="RTK0EF0045Z15001ZJ-v1.1.0_EN"

# RZ/V2L DRP-AI Support Package Version 7.40
REN_V2L_DRPAI_PKG="r11an0549ej0740-rzv2l-drpai-sp"

# RZ/V2L ISP Support Package Version 1.30
REN_V2L_ISP_PKG="r11an0561ej0130-rzv2l-isp-sp"

# RZ/V2L Multi-OS Package V1.11
REN_G2L_MULTI_OS_PKG="r01an6238ej0111-rzv2l-cm33-multi-os-pkg"  

VKRZ_RCP_GIT_URL="https://github.com/Vekatech/meta-vkrzv2l.git"

OSS_PKG="oss_pkg_rzv_v3.0.4"
SUFIX_7Z=".7z"
                   
# ----------------------------------------------------------------
PKGKDIR=~/work/rzv_vlp_v3.0.4
WORKSPACE=$(pwd)
YOCTO_HOME="${WORKSPACE}/yocto_304"
BUILD_DIR="build"

function main_process(){
	if [ ! -d ${YOCTO_HOME} ];then
		mkdir -p ${YOCTO_HOME}
	fi

	check_pkg_require
	unpack_bsp
	unpack_gpu
	unpack_codec
	unpack_drpai
	unpack_isp
	unpack_multi_os
	unzip_src
	getrcp
	echo ""
	echo "ls ${YOCTO_HOME}"
	ls ${YOCTO_HOME}
	echo ""
	echo "---Finished---"
}

log_error(){
    local string=$1
    echo -ne "\e[1;31m $string \e[0m\n"
}

log_warn(){
    local string=$1
    echo -ne "\e[1;33m $string \e[0m\n"
}

check_pkg_require(){
	# check required pacakages are downloaded from Renesas website
	local check=0
	cd ${PKGKDIR}

	if [ ! -e ${REN_LINUX_BSP_PKG}${SUFFIX_ZIP} ];then
		log_error "Error: Cannot found ${REN_LINUX_BSP_PKG}${SUFFIX_ZIP} !"
		log_error "Please download 'RZ/V Verified Linux Package' from Renesas RZ/V2L Website"
		echo ""
		check=1
	fi
	if [ ! -e ${REN_GPU_MALI_LIB_PKG}${SUFFIX_ZIP} ] && [ ! -e ${REN_GPU_MALI_LIB_PKG_EVAL}${SUFFIX_ZIP} ]; then
		log_error "Error: Cannot found ${REN_GPU_MALI_LIB_PKG}${SUFFIX_ZIP} !"
		log_error "Please download 'RZ MPU Graphics Library' from Renesas RZ/V2L Website"
		echo ""
		check=2
	elif [ ! -e ${REN_GPU_MALI_LIB_PKG}${SUFFIX_ZIP} ] && [ -e ${REN_GPU_MALI_LIB_PKG_EVAL}${SUFFIX_ZIP} ]; then
		log_warn "This is an Evaluation Version package ${REN_GPU_MALI_LIB_PKG_EVAL}${SUFFIX_ZIP}"
		log_warn "It is recommended to download 'MPU Graphics Library Unrestricted Version' from Renesas Website"
		echo ""
	fi
	if [ ! -e ${REN_VEDIO_CODEC_LIB_PKG}${SUFFIX_ZIP} ] && [ ! -e ${REN_VEDIO_CODEC_LIB_PKG_EVAL}${SUFFIX_ZIP} ] ;then
		log_error "Error: Cannot found ${REN_VEDIO_CODEC_LIB_PKG}${SUFFIX_ZIP} !"
		log_error "Please download 'RZ MPU Codec Library' from Renesas RZ/V2L Website"
		echo ""
		check=3
	elif [ ! -e ${REN_VEDIO_CODEC_LIB_PKG}${SUFFIX_ZIP} ] && [ -e ${REN_VEDIO_CODEC_LIB_PKG_EVAL}${SUFFIX_ZIP}  ]; then
		log_warn "This is an Evaluation Version package ${REN_VEDIO_CODEC_LIB_PKG_EVAL}${SUFFIX_ZIP}"
		log_warn "It is recommended to download 'MPU Video Codec Library Unrestricted Version' from Renesas Website"
		echo ""
	fi   
	if [ ! -e ${REN_V2L_DRPAI_PKG}${SUFFIX_ZIP} ];then
		log_error "Error: Cannot found ${REN_V2L_DRPAI_PKG}${SUFFIX_ZIP} !"
		log_error "Please download 'RZ/V2L DRP-AI Support Package' from Renesas RZ/V2L Website"
		echo ""
		check=4
	fi
	if [ ! -e ${REN_V2L_ISP_PKG}${SUFFIX_ZIP} ];then
		log_error "Error: Cannot found ${REN_V2L_ISP_PKG}${SUFFIX_ZIP} !"
		log_error "Please download 'RZ/V2L ISP Support Package' from Renesas RZ/V2L Website"
		echo ""
		check=5
	fi
	if [ ! -e ${REN_G2L_MULTI_OS_PKG}${SUFFIX_ZIP} ];then
		log_error "Error: Cannot found ${REN_V2L_MULTI_OS_PKG}${SUFFIX_ZIP} !"
		log_error "Please download 'RZ/V2L Group Multi-OS Package' from Renesas RZ/V2L Website"
		echo ""
		check=6
	fi

	[ ${check} -ne 0 ] && echo "---Failed---" && exit
}

# usage: extract_to_meta zipfile zipdir tarfile tardir
function extract_to_meta(){
	local zipfile=$1
	local zipdir=$2
        echo "DEBUG: zipdir=$zipdir"
	local tarfile_tmp=$3
	local tardir=$4
	local tarfile=

	echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!display zipfile, zipdir !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ."
	echo $zipfile $zipdir
	echo "tarfile_tmp $tardir ."	
	echo $tarfile_tmp $tardir


	cd ${WORKSPACE}
	pwd
	echo "Extract zip file to ${zipdir} and then untar ${tarfile_tmp} file"
	unzip -d ${zipdir} ${zipfile}
	tarfile=$(find ${zipdir} -type f -name ${tarfile_tmp})

	echo "!!!!!!!!!!!TARFILE: "${tarfile}
	echo "!!!!!!!!!!!TARDIR: "${tardir}
	tar -xzf ${tarfile} -C ${tardir}
	sync
}

function unpack_bsp(){
	local pkg_file=${PKGKDIR}/${REN_LINUX_BSP_PKG}${SUFFIX_ZIP}
	local zip_dir="REN_LINUX_BSP"
	local bsp="rzv*_vlp_v*.tar.gz"
	local bsp_patch=""

	extract_to_meta ${pkg_file} ${zip_dir} ${bsp} ${YOCTO_HOME}
	bsp_patch=$(find ${zip_dir} -type f -name "rzv*.patch")
	if [ -n "${bsp_patch}" ]; then
		echo ${bsp_patch}
		patch -d ${YOCTO_HOME} -p1 < ${bsp_patch}
	fi
	rm -fr ${zip_dir}
}

function unpack_gpu(){
	local pkg_file=${PKGKDIR}/${REN_GPU_MALI_LIB_PKG}${SUFFIX_ZIP}
	local zip_dir="REN_GPU_MALI"
	local gpu="meta-rz-features*.tar.gz"

	if [ ! -e ${PKGKDIR}/${REN_GPU_MALI_LIB_PKG}${SUFFIX_ZIP} ]; then
		pkg_file=${PKGKDIR}/${REN_GPU_MALI_LIB_PKG_EVAL}${SUFFIX_ZIP}
	fi

	extract_to_meta ${pkg_file} ${zip_dir} ${gpu} ${YOCTO_HOME}
	rm -fr ${zip_dir}
}

function unpack_codec(){
	local pkg_file=${PKGKDIR}/${REN_VEDIO_CODEC_LIB_PKG}${SUFFIX_ZIP}
	local zip_dir="REN_VEDIO_CODEC"
	local codec="meta-rz-features*.tar.gz"

	if [ ! -e ${PKGKDIR}/${REN_VEDIO_CODEC_LIB_PKG}${SUFFIX_ZIP} ]; then
		pkg_file=${PKGKDIR}/${REN_VEDIO_CODEC_LIB_PKG_EVAL}${SUFFIX_ZIP}
	fi

	extract_to_meta ${pkg_file} ${zip_dir} ${codec} ${YOCTO_HOME}
	rm -fr ${zip_dir}
}

function unpack_drpai(){
	local pkg_file=${PKGKDIR}/${REN_V2L_DRPAI_PKG}${SUFFIX_ZIP}
	local zip_dir="REN_V2L_DRPAI"
	local drpai="meta-rz-drpai*.tar.gz"

	extract_to_meta ${pkg_file} ${zip_dir} ${drpai} ${YOCTO_HOME}
	rm -fr ${zip_dir}
}

function unpack_isp(){
	local pkg_file=${PKGKDIR}/${REN_V2L_ISP_PKG}${SUFFIX_ZIP}
	local zip_dir="REN_V2L_ISP"
	local isp="meta-rz-simple-isp*.tar.gz"

	extract_to_meta ${pkg_file} ${zip_dir} ${isp} ${YOCTO_HOME}
	rm -fr ${zip_dir}
}

function unpack_multi_os(){
	local pkg_file=${PKGKDIR}/${REN_G2L_MULTI_OS_PKG}${SUFFIX_ZIP}
	local zip_dir="REN_MULTI_OS"
	local rtos="meta-rz-features*.tar.gz"

	extract_to_meta ${pkg_file} ${zip_dir} ${rtos} ${zip_dir}
	cp -ar ${zip_dir}/meta-rz-features ${YOCTO_HOME}/meta-multi-os
	rm -fr ${zip_dir}

	# replace the layer name
	#sed -i 's/rz-features/multi-os/g' ${YOCTO_HOME}/meta-multi-os/conf/layer.conf
}

function remove_redundant_patches(){
	# remove linux patches that were merged into the Avnet kernel
	flist=$(find ${YOCTO_HOME} -name "linux-renesas_*.bbappend")
	for ff in ${flist}
	do
		echo ${ff}
		rm -rf ${ff}
	done

	# remove u-boot patches
	find ${YOCTO_HOME} -name "u-boot_*.bbappend" -print -exec rm -rf {} \;

	# remove tfa patches
	find ${YOCTO_HOME} -name "trusted-firmware-a.bbappend" -print -exec mv {} {}.remove \;
}

function getrcp()
{
    cd ${YOCTO_HOME}/
        #download 
        git clone ${VKRZ_RCP_GIT_URL}
    cd ${WORKPWD}/
}


function unzip_src()
{
	if [ ! -d ${YOCTO_HOME}/${BUILD_DIR} ]; then
	   mkdir -p ${YOCTO_HOME}/${BUILD_DIR}
	fi
	7z -o${YOCTO_HOME}/${BUILD_DIR} x ${PKGKDIR}/${OSS_PKG}${SUFIX_7Z}
}


#---start--------
main_process $*
exit
