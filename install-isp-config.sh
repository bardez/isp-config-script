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

# FQDN (Fully Qualified Domain Name) para o servidor. Ex: painel.seudominio.com
# Se deixado em branco, será gerado um FQDN temporário usando o IP do Droplet.
SERVER_FQDN=""

# Desabilitar Quota de disco. Defina como "yes" para desabilitar, "no" para tentar instalar com quota.
# Se você não precisa de quotas de disco ou está tendo problemas com elas, defina como "yes".
DISABLE_QUOTA="yes"

# --- Fim das Configurações Personalizáveis ---

set -e

echo "Iniciando a instalação automatizada do ISPConfig..."

# 1. Atualizar o sistema
echo "Atualizando e fazendo upgrade dos pacotes do sistema..."
apt update -y
apt upgrade -y
apt autoremove -y

# Verificar se um reboot é necessário após as atualizações
if [ -f /var/run/reboot-required ]; then
  echo "Um reboot é necessário para aplicar as atualizações do kernel. Por favor, reinicie o servidor e execute o script novamente."
  echo "Ou, se preferir, o script pode continuar com --no-quota se DISABLE_QUOTA estiver definido como 'yes'."
  read -p "Deseja continuar sem reboot e com --no-quota (se configurado)? (y/N) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    echo "Por favor, reinicie o servidor e execute o script novamente."
    exit 1
  fi
fi

# 2. Instalar dependências básicas (curl e wget)
echo "Verificando e instalando dependências básicas (curl, wget, git)..."
apt install -y curl wget git

# 3. Configurar FQDN
if [ -z "$SERVER_FQDN" ]; then
  echo "Nenhum FQDN fornecido. Gerando um FQDN temporário..."
  PUBLIC_IP=$(curl -s ifconfig.me)
  SERVER_FQDN="ispconfig-$PUBLIC_IP.local"
  echo "FQDN temporário gerado: $SERVER_FQDN"
else
  echo "Utilizando FQDN fornecido: $SERVER_FQDN"
fi

HOSTNAME=$(echo $SERVER_FQDN | cut -d. -f1)

# Definir hostname
hostnamectl set-hostname $SERVER_FQDN

# Atualizar /etc/hosts
# Remover entradas antigas para o hostname padrão da DigitalOcean
sed -i "/^127.0.1.1/d" /etc/hosts

# Adicionar a nova entrada FQDN
if ! grep -q "127.0.1.1\s\+$SERVER_FQDN\s\+$HOSTNAME" /etc/hosts; then
  echo "127.0.1.1 $SERVER_FQDN $HOSTNAME" >> /etc/hosts
fi

echo "FQDN configurado para $SERVER_FQDN"

# 4. Executar o instalador automático do ISPConfig
echo "Baixando e executando o instalador automático do ISPConfig..."

ISPCONFIG_INSTALL_ARGS=""
if [ "$DISABLE_QUOTA" = "yes" ]; then
  ISPCONFIG_INSTALL_ARGS="--no-quota"
  echo "Quota de disco desabilitada (--no-quota)."
fi

wget -O - https://get.ispconfig.org | sh -s -- \
  --channel=stable \
  --use-nginx \
  --use-php=${PHP_VERSIONS} \
  --use-certbot \
  --monit \
  --monit-alert-email=${MONIT_ALERT_EMAIL} \
  --ssh-harden \
  --unattended-upgrades=autoclean,reboot \
  ${ISPCONFIG_INSTALL_ARGS} \
  --i-know-what-i-am-doing

echo "Instalação do ISPConfig concluída. Por favor, verifique os logs para quaisquer erros."
echo "Lembre-se de substituir 'seu_email@example.com' pelo seu e-mail real no script antes de executar."
echo "Se você usou um FQDN temporário, considere configurar um FQDN real e um registro DNS apontando para o IP do seu Droplet."
echo "Você pode acessar o painel do ISPConfig através do IP do seu Droplet na porta 8080 (ex: https://your_droplet_ip:8080)"
