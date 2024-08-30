#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 函数定义
check_distribution() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    else
        echo -e "${RED}无法确定操作系统发行版。${NC}"
        exit 1
    fi
    echo -e "${GREEN}检测到操作系统: $OS $VER${NC}"
}

update_system() {
    echo -e "${YELLOW}正在更新系统...${NC}"
    case $OS in
        "Ubuntu" | "Debian GNU/Linux")
            sudo apt update && sudo apt upgrade -y
            ;;
        "CentOS Linux")
            sudo yum update -y
            ;;
        *)
            echo -e "${RED}不支持的操作系统: $OS${NC}"
            exit 1
            ;;
    esac
    echo -e "${GREEN}系统更新完成${NC}"
}

install_dependencies() {
    echo -e "${YELLOW}正在安装 Docker 和 Docker Compose...${NC}"
    case $OS in
        "Ubuntu" | "Debian GNU/Linux")
            sudo apt install -y docker.io docker-compose jq
            ;;
        "CentOS Linux")
            sudo yum install -y yum-utils epel-release
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin jq
            sudo systemctl start docker
            ;;
        *)
            echo -e "${RED}不支持的操作系统: $OS${NC}"
            exit 1
            ;;
    esac
    echo -e "${GREEN}Docker、Docker Compose 和 jq 安装完成${NC}"
}

clone_repository() {
    echo -e "${YELLOW}正在克隆项目仓库...${NC}"
    git clone -b dev https://github.com/syuchua/QFurina.git
    cd QFurina && mkdir -p data/music
    echo -e "${GREEN}项目仓库克隆完成${NC}"
}

configure_model() {
    echo -e "${YELLOW}开始配置模型...${NC}"
    echo "请选择要使用的模型类型:"
    echo "1) GPT 系列"
    echo "2) 其他模型"
    read -p "请输入选项 (1/2): " model_choice

    case $model_choice in
        1)
            read -p "请输入 OpenAI API Key: " api_key
            read -p "请输入 API Base URL (默认为 https://api.openai.com/v1): " base_url
            base_url=${base_url:-https://api.openai.com/v1}
            echo "请选择 GPT 模型:"
            echo "1) gpt-3.5-turbo (默认)"
            echo "2) gpt-4"
            echo "3) 其他"
            read -p "请输入选项 (1/2/3): " gpt_model_choice
            case $gpt_model_choice in
                1) model="gpt-3.5-turbo" ;;
                2) model="gpt-4" ;;
                3) read -p "请输入模型名称: " model ;;
                *) model="gpt-3.5-turbo" ;;
            esac
            ;;
        2)
            read -p "请输入模型名称: " model
            read -p "请输入 API Key: " api_key
            read -p "请输入 API Base URL: " base_url
            ;;
        *)
            echo -e "${RED}无效的选项${NC}"
            exit 1
            ;;
    esac

    echo -e "${GREEN}模型配置完成${NC}"
}

update_config_files() {
    echo -e "${YELLOW}正在更新配置文件...${NC}"
    config_file="config/config.json"
    model_file="config/model.json"

    # 更新 config.json
    jq ".api_key = \"$api_key\" | .model = \"$model\" | .proxy_api_base = \"$base_url\"" $config_file > tmp.$$.json && mv tmp.$$.json $config_file

    # 更新 model.json
    if [ "$model_choice" == "1" ]; then
        jq ".models.gpt = {\"api_key\": \"$api_key\", \"base_url\": \"$base_url\", \"args\": {}, \"timeout\": 120, \"available_models\": [\"$model\"]} | .model = \"$model\" | .vision = true" $model_file > tmp.$$.json && mv tmp.$$.json $model_file
    else
        jq ".models[\"$model\"] = {\"api_key\": \"$api_key\", \"base_url\": \"$base_url\", \"args\": {}, \"timeout\": 120, \"available_models\": [\"$model\"]} | .model = \"$model\" | .vision = true" $model_file > tmp.$$.json && mv tmp.$$.json $model_file
    fi

    echo -e "${GREEN}配置文件更新完成${NC}"
}

configure_qq_bot() {
    echo -e "${YELLOW}正在配置 QQ 机器人...${NC}"
    read -p "请输入 QQ 机器人账号: " qq_account
    sed -i "s/ACCOUNT=3836751864/ACCOUNT=$qq_account/" docker-compose.yaml
    echo -e "${GREEN}QQ 机器人配置完成${NC}"
}

start_services() {
    echo -e "${YELLOW}正在启动服务...${NC}"
    docker-compose up -d
    echo -e "${GREEN}服务启动完成${NC}"
}

show_qr_code() {
    echo -e "${YELLOW}正在获取登录二维码...${NC}"
    echo "请使用以下命令查看 napcat 日志以获取登录二维码:"
    echo -e "${GREEN}docker logs napcat${NC}"
}

# 主程序
main() {
    check_distribution
    update_system
    install_dependencies
    clone_repository
    configure_model
    update_config_files
    configure_qq_bot
    start_services
    show_qr_code
}

# 执行主程序
main