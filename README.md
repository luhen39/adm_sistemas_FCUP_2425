## DISCLAIMER

**Please note that the documentation and comments are primarily in Portuguese. English translations are not provided, interested users should translate content as needed.**

# Administração de Sistemas - Relatório de Projeto

## Membros do grupo

- Ricardo Sá (up202408664)
- Luís Henrique (up202004196)
- Xavier Santos (up202108894)

## Resumo do projeto

O projeto consiste num sistema de informação com autenticação LDAP (Lightweight Directory Access Protocol) e diretórios montados com SMB.

Quatro máquinas virtuais foram usadas, a correr em servidores da Google Cloud, com os seguintes SOs e funções:
- Windows Datacenter 2019 : Criação de um utilizador a autenticar mais tarde com LDAP.
- Ubuntu Desktop 24.04 : Criação de um utilizador a autenticar mais tarde com LDAP, e acesso aos diretórios SMB da máquina OMV.
- Debian 12 : Usa OMV (Open Media Vault) para montar os diretórios SMB, usando RAID 1 para fazer os *backups* dos mesmos.
- Ubuntu Server 24.04 : Servidor LDAP, utiliza OpenLDAP para autenticar os utilizadores.

## Script: sync_ldap_omv.sh

Para a configuração do projeto foi criado o script [sync_ldap_omv.sh](sync_ldap_omv.sh), que periodicamente lista os clientes do servidor LDAP e, com base nas informações deles, cria/modifica/elimina utilizadores da máquina OMV, de forma a promover consistência entre o servidor e o sistema de diretórios.

![](antes_script.png)
> Lista de utilizadores antes da execução do *script*

![](pos_script_1.png)
> Lista de utilizadores após a execução do *script*

![](pos_script_2.png)
> *Logs* do *script*, descrevendo as alterações feitas à base de dados de utilizadores do OMV.

O *script* foi configurado para ser executado a cada hora (16:00, 17:00, etc), como podemos ver na imagem seguinte.

![](cron_script_conf.png)

## Sistema de *backup*: RAID 1

Para o sistema de *backup* do OMV escolhemos usar RAID 1, por uma questão de simplicidade. Nas imagens seguintes podemos ver as configurações do mesmo.

![](raid_1_1.png)
![](raid_1_2.png)

## Outras configurações

Para poder utilizar o serviço *share* do OpenMediaVault é necessário fazer as seguintes alterações na máquina OMV:

![](permissoes_share.png)

O processo de instalação de OpenLDAP na máquina Windows está ilustrado nas seguintes imagens:

![](InstalacaoWindows1.png)
![](InstalacaoWindows2.png)
![](InstalacaoWindows3.png)
![](InstalacaoWindows4.png)
![](Resultado_ldap_win.png)

A configuração do SMB na máquina OMV foi feita da seguinte forma:

![](smb_conf_1.png)
![](smb_conf_2.png)
![](smb_conf_3.png)

Para instalar o OpenLDAP no servidor Ubuntu seguimos [este tutorial](https://youtu.be/p857CNi60LM?si=n3LMQyKlC8fjil5P).

---

Final Grade: 15/20
