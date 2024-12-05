#!/bin/sh

ROOTFS_DIR=$(pwd)
export PATH=$PATH:~/.local/usr/bin
max_retries=50
timeout=1
ARCH=$(uname -m)

# Kiểm tra kiến trúc hệ thống
if [ "$ARCH" = "x86_64" ]; then
  ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
  ARCH_ALT=arm64
else
  printf "Unsupported CPU architecture: ${ARCH}\n"
  exit 1
fi

# Kiểm tra xem đã cài đặt Ubuntu hay chưa
if [ ! -e $ROOTFS_DIR/.installed ]; then
  echo "#######################################################################################"
  echo "#"
  echo "#                                    Yuty - Almost MC"
  echo "#"
  echo "#                           Copyright (C) 2025, 🅰🅻🅼🅾🆂🆃 🅲🅻🅾🆄🅳"
  echo "#"
  echo "#"
  echo "#######################################################################################"

  read -p "Bạn có muốn cài đặt Ubuntu 22.04 không? (YES/no): " install_ubuntu
fi

# Cài đặt Ubuntu 22.04 nếu người dùng chọn YES
case $install_ubuntu in
  [yY][eE][sS])
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O /tmp/rootfs.tar.gz \
      "http://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/ubuntu-base-22.04.2-base-${ARCH_ALT}.tar.gz"
    tar -xf /tmp/rootfs.tar.gz -C $ROOTFS_DIR
    ;;
  *)
    echo "Bỏ qua cài đặt Ubuntu."
    ;;
esac

# Cài đặt PRoot nếu chưa có
if [ ! -e $ROOTFS_DIR/.installed ]; then
  mkdir -p $ROOTFS_DIR/usr/local/bin
  wget --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot "https://raw.githubusercontent.com/AlmostCloud/root/main/proot-${ARCH}"

  while [ ! -s "$ROOTFS_DIR/usr/local/bin/proot" ]; do
    rm -rf $ROOTFS_DIR/usr/local/bin/proot
    wget --tries=$max_retries --timeout=$timeout --no-hsts -O $ROOTFS_DIR/usr/local/bin/proot "https://raw.githubusercontent.com/AlmostCloud/root/main/proot-${ARCH}"

    if [ -s "$ROOTFS_DIR/usr/local/bin/proot" ]; then
      chmod 755 $ROOTFS_DIR/usr/local/bin/proot
      break
    fi

    sleep 1
  done

  chmod 755 $ROOTFS_DIR/usr/local/bin/proot
fi

# Cấu hình DNS nếu chưa có
if [ ! -e $ROOTFS_DIR/.installed ]; then
  printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > ${ROOTFS_DIR}/etc/resolv.conf
  rm -rf /tmp/rootfs.tar.xz /tmp/sbin
  touch $ROOTFS_DIR/.installed
fi

# Kiểm tra Docker và Systemctl
check_docker() {
  if command -v docker >/dev/null 2>&1; then
    echo "Docker đã được cài đặt và sẵn sàng sử dụng."
  else
    echo "Docker chưa được cài đặt, đang cài đặt."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
  fi
}

check_systemctl() {
  if command -v systemctl >/dev/null 2>&1; then
    echo "Systemctl hiện đã có sẵn."
  else
    echo "Systemctl không khả dụng. Bạn có thể cần quyền root hoặc sử dụng Docker để khởi động dịch vụ."
  fi
}

# Cấu hình hiển thị
CYAN='\e[0;36m'
WHITE='\e[0;37m'
RESET_COLOR='\e[0m'

display_gg() {
  echo -e "${WHITE}___________________________________________________${RESET_COLOR}"
  echo -e ""
  echo -e "           ${CYAN}-----> Thành Công! <----${RESET_COLOR}"
}

clear
display_gg

# Kiểm tra Docker và Systemctl
check_docker
check_systemctl

# Sử dụng PRoot để chạy hệ thống chroot hoặc docker container
$ROOTFS_DIR/usr/local/bin/pro
ot \
  --rootfs="${ROOTFS_DIR}" \
  -0 -w "/root" -b /dev -b /sys -b /proc -b /etc/resolv.conf --kill-on-exit
