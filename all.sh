#!/bin/sh

setup() {
    #安装必备软件
    echo "安装必备软件"
    apt update -y
    apt install sudo btop net-tools lsd git chrony -y
    # 安装ssh
    apt install openssh-server -y
    # 安装sftp
    apt install openssh-sftp-server -y
    # 安装nexttrace
    curl nxtrace.org/nt | bash
    # 安装nali
    curl -o /usr/bin/nali https://data.tnzzz.top/software/nali/nali && chmod +x /usr/bin/nali
}

# 配置ssh
init_ssh() {
    echo "开始配置ssh"
    curl -fsSL -o /tmp/sshd_config https://tnzzzhlp.oss-cn-guangzhou.aliyuncs.com/ssh/sshd_config
    curl -fsSL -o /tmp/authorized_keys https://tnzzzhlp.oss-cn-guangzhou.aliyuncs.com/ssh/authorized_keys
    curl -fsSL -o /tmp/sshd_config.sha256.sum https://tnzzzhlp.oss-cn-guangzhou.aliyuncs.com/ssh/sshd_config.sha256.sum
    curl -fsSL -o /tmp/authorized_keys.sha256.sum https://tnzzzhlp.oss-cn-guangzhou.aliyuncs.com/ssh/authorized_keys.sha256.sum

    if [ "$(sha256sum /tmp/sshd_config | awk '{print $1}')" = "$(cat /tmp/sshd_config.sha256.sum)" ]; then
        echo "sha256校验通过"
        mv /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
        mv /tmp/sshd_config /etc/ssh/sshd_config
    else
        echo "sha256校验失败"
    fi

    if [ "$(sha256sum /tmp/authorized_keys | awk '{print $1}')" = "$(cat /tmp/authorized_keys.sha256.sum)" ]; then
        echo "sha256校验通过"
        #判断文件夹是否存在
        if [ -d "/root/.ssh" ]; then
            rm -r /root/.ssh
        fi
        mkdir /root/.ssh
        mv /tmp/authorized_keys /root/.ssh/authorized_keys
        service sshd restart
    else
        echo "sha256校验失败"
    fi

    #删除临时文件
    if [ -d "/tmp/sshd_config" ]; then
        rm /tmp/sshd_config
    fi

    if [ -d "/tmp/authorized_keys" ]; then
        rm /tmp/authorized_keys
    fi

    if [ -d "/tmp/sshd_config.sha256.sum" ]; then
        rm /tmp/sshd_config.sha256.sum
    fi

    if [ -d "/tmp/sshd_config.sha256.sum" ]; then
        rm /tmp/sshd_config.sha256.sum
    fi

    if [ -d "/tmp/authorized_keys.sha256.sum" ]; then
        rm /tmp/authorized_keys.sha256.sum
    fi
}

# 安装zsh
init_zsh() {
    echo "开始安装zsh"

    # 如果没有sudo 则安装sudo
    if [ ! -f /usr/bin/sudo ]; then
        apt install sudo -y
    fi
    sudo apt install zsh git -y

    chsh -s $(which zsh)
    # 安装oh-my-zsh，如果已安装则跳过安装oh-my-zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "开始安装oh-my-zsh"
        curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sh
    fi

    # 安装主题
    echo "开始安装主题"
    # 如果已安装则跳过安装powerlevel10k
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
    fi
    curl -fsSL https://tnzzzhlp.oss-cn-guangzhou.aliyuncs.com/zsh/.p10k.zsh -o ~/.p10k.zsh

    # 安装插件
    echo "开始安装插件"
    # 如果已安装则跳过安装插件
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    fi
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    fi

    # 下载配置
    echo "开始下载配置"
    curl -fsSL https://tnzzzhlp.oss-cn-guangzhou.aliyuncs.com/zsh/.zshrc -o ~/.zshrc

    zsh
}

# 切换官方源
switch_source() {
    echo "开始切换官方源"
    sudo apt update
    sudo apt install apt-transport-https ca-certificates -y
    cat <<'EOF' >/etc/apt/sources.list
deb https://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware
# deb-src https://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware

deb https://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
# deb-src https://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware

deb https://deb.debian.org/debian/ bookworm-backports main contrib non-free non-free-firmware
# deb-src https://deb.debian.org/debian/ bookworm-backports main contrib non-free non-free-firmware

deb https://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware
# deb-src https://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware
EOF
}

# Build
build() {
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    sudo apt install build-essential -y
}

all() {
    setup
    init_ssh
    init_zsh
    switch_source
}

# 执行函数
if [ "$1" = "" ]; then
    all
else
    if [ "$1" = "setup" ]; then
        setup
    else
        if [ "$1" = "ssh" ]; then
            init_ssh
        else
            if [ "$1" = "zsh" ]; then
                init_zsh
            else
                if [ "$1" = "source" ]; then
                    switch_source
                else
                    echo "参数错误"
                fi
            fi
        fi
    fi
fi
