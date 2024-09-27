#!/bin/bash

VERSION=0.3.0

TARGET_STR="RZ/G2LC"
TARGET="vkrzg2lc"
SUFFIX_ZIP=".zip"

# Make sure that the following packages have been downloaded from the official website
# Verified Linux Package
REN_LINUX_BSP_PKG="RTK0EF0045Z0021AZJ-v3.0.5-update3"

# RZ MPU Graphics Library Unrestricted Version
REN_GPU_MALI_LIB_PKG="RTK0EF0045Z14001ZJ-v1.1.2_rzg_EN"

# RZ MPU Graphics Library Evaluation Version
REN_GPU_MALI_LIB_PKG_EVAL="RTK0EF0045Z13001ZJ-v1.1.2_EN"

# Multi-OS Package
REN_MULTI_OS_PKG="r01an5869ej0201_rzg-multi-os-pkg"

VKRZ_RCP_GIT_URL="https://github.com/Vekatech/meta-"${TARGET}".git"
VKRZ_RCP_BRANCH="VLP-v3.0.5-update3"

OSS_PKG="oss_pkg_rzg_v3.0.5"
SUFIX_7Z=".7z"

# ----------------------------------------------------------------
PKGKDIR=$HOME/work/rzg_vlp_v3.0.5
WORKSPACE=$(pwd)
YOCTO_HOME="${WORKSPACE}/yocto_305u3"
BUILD_DIR="${TARGET}"

function main_process() {
	if [ ! -d ${YOCTO_HOME} ];then
		mkdir -p ${YOCTO_HOME}
	fi

	check_pkg_require
	unpack_bsp
	unpack_gpu
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
		log_error "Please download '${TARGET_STR} Verified Linux Package' from Renesas Website"
		echo ""
		check=1
	fi
	if [ ! -e ${REN_GPU_MALI_LIB_PKG}${SUFFIX_ZIP} ] && [ ! -e ${REN_GPU_MALI_LIB_PKG_EVAL}${SUFFIX_ZIP} ]; then
		log_error "Error: Cannot found ${REN_GPU_MALI_LIB_PKG}${SUFFIX_ZIP} !"
		log_error "Please download '${TARGET_STR} MPU Graphics Library' from Renesas Website"
		echo ""
		check=2
	elif [ ! -e ${REN_GPU_MALI_LIB_PKG}${SUFFIX_ZIP} ] && [ -e ${REN_GPU_MALI_LIB_PKG_EVAL}${SUFFIX_ZIP} ]; then
		log_warn "This is an Evaluation Version package ${REN_GPU_MALI_LIB_PKG_EVAL}${SUFFIX_ZIP}"
		log_warn "It is recommended to download '${TARGET_STR} MPU Graphics Library Unrestricted Version' from Renesas Website"
		echo ""
	fi
	if [ ! -e ${REN_MULTI_OS_PKG}${SUFFIX_ZIP} ];then
		log_error "Error: Cannot found ${REN_MULTI_OS_PKG}${SUFFIX_ZIP} !"
		log_error "Please download '${TARGET_STR} Group Multi-OS Package' from Renesas Website"
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

	if [ -z "${tarfile}" ]; then
		log_error "Can't find archives in ${zipdir}! Please check the package file."
		exit
	fi

	echo "!!!!!!!!!!!TARFILE: "${tarfile}
	echo "!!!!!!!!!!!TARDIR: "${tardir}
	tar -xzf ${tarfile} -C ${tardir}
	sync
}

function copy_docs(){
    local zipdir=$1
    local tardir=$2
    mkdir -p "${tardir}"
    while IFS= read -r doc
    do
        echo "Copy '${doc}' to '${tardir}'"
        cp -ar "${doc}" "${tardir}"
    done < <(find "${zipdir}" -type f -name "*.pdf")
}

function unpack_bsp(){
	local pkg_file=${PKGKDIR}/${REN_LINUX_BSP_PKG}${SUFFIX_ZIP}
	local zip_dir="REN_LINUX_BSP"
	local bsp="rzg_vlp_v*.tar.gz"
	local bsp_patch=""

	extract_to_meta ${pkg_file} ${zip_dir} ${bsp} ${YOCTO_HOME}
	copy_docs ${zip_dir} ${YOCTO_HOME}/docs/bsp
	bsp_patch=$(find ${zip_dir} -type f -name "*.patch")
	for patch in $bsp_patch
	do
		echo "Applying patch: $patch"
		patch -d ${YOCTO_HOME} -p1 < ${patch}
	done
	bsp_patch=$(find ${YOCTO_HOME}/extra -type f -name "*.patch")
	for patch in $bsp_patch
	do
		echo "Applying patch: $patch"
		patch -d ${YOCTO_HOME}/meta-renesas -p1 < ${patch}
	done
	rm -fr ${YOCTO_HOME}/extra
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
	copy_docs ${zip_dir} ${YOCTO_HOME}/docs/gpu
	rm -fr ${zip_dir}
}

function unpack_multi_os(){
	local pkg_file=${PKGKDIR}/${REN_MULTI_OS_PKG}${SUFFIX_ZIP}
	local zip_dir="REN_MULTI_OS"
	local rtos="meta-rz-features_multi-os_v*.tar.gz"

	extract_to_meta ${pkg_file} ${zip_dir} ${rtos} ${YOCTO_HOME}
	copy_docs ${zip_dir} ${YOCTO_HOME}/docs/multi-os
	rm -fr ${zip_dir}
}

function getrcp()
{
    cd ${YOCTO_HOME}/
    #download
    git clone ${VKRZ_RCP_GIT_URL} ${YOCTO_HOME}/meta-${TARGET}
    git -C ${YOCTO_HOME}/meta-${TARGET} checkout ${VKRZ_RCP_BRANCH}
    cd ${WORKPWD}/
    #cp -rf ./meta-${TARGET} ${YOCTO_HOME}/
}

function unzip_src()
{
	if [ ! -d ${YOCTO_HOME}/${BUILD_DIR} ]; then
	   mkdir -p ${YOCTO_HOME}/${BUILD_DIR}
	fi
	7z -o${YOCTO_HOME}/../ x ${PKGKDIR}/${OSS_PKG}${SUFIX_7Z}
}

#---start--------
main_process $*
exit
