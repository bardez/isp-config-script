#!/bin/bash

# Script de instalação automatizada do ISPConfig 3.2 em Ubuntu 22.04/24.04
# Este script foi projetado para ser executado em um Droplet novo e limpo da DigitalOcean.
# Ele automatiza a instalação do ISPConfig e suas dependências, seguindo as melhores práticas.

# ATENÇÃO: Este script irá reconfigurar seu servidor. Execute-o apenas em um sistema novo ou onde você esteja ciente das consequências.

# --- Configurações Personalizáveis ---

# Endereço de e-mail para alertas do Monit (substitua pelo seu e-mail real)
MONIT_ALERT_EMAIL="seu_email@example.com"

# Versões do PHP a serem instaladas (separadas por vírgula, ex: 8.3,8.2,8.1)
# Verifique as versões disponíveis na documentação do ISPConfig.
PHP_VERSIONS="8.3,8.2,8.1"

# --- Fim das Configurações Personalizáveis ---

set -e

echo "Iniciando a instalação automatizada do ISPConfig..."

# 1. Atualizar o sistema
echo "Atualizando e fazendo upgrade dos pacotes do sistema..."
apt update -y
apt upgrade -y
apt autoremove -y

# 2. Instalar dependências básicas (curl e wget)
echo "Verificando e instalando dependências básicas (curl, wget, git)..."
apt install -y curl wget git

# 3. Executar o instalador automático do ISPConfig
echo "Baixando e executando o instalador automático do ISPConfig..."
wget -O - https://get.ispconfig.org | sh -s -- \
  --channel=stable \
  --use-nginx \
  --use-php=${PHP_VERSIONS} \
  --use-certbot \
  --monit \
  --monit-alert-email=${MONIT_ALERT_EMAIL} \
  --ssh-harden \
  --unattended-upgrades=autoclean,reboot \
  --i-know-what-i-am-doing

echo "Instalação do ISPConfig concluída. Por favor, verifique os logs para quaisquer erros."
echo "Lembre-se de substituir 'seu_email@example.com' pelo seu e-mail real no script antes de executar."
echo "Você pode acessar o painel do ISPConfig através do IP do seu Droplet na porta 8080 (ex: https://your_droplet_ip:8080)"
