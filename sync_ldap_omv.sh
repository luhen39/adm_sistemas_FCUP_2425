#!/bin/bash

# PATH para garantir que os comandos sejam encontrados pelo cron
export PATH=$PATH:/usr/sbin

# Configurações do LDAP
#LDAP_SERVER="ldap://34.147.112.189"
LDAP_SERVER="ldap://10.164.0.7"
LDAP_BIND_DN="cn=admin,dc=proj-sistemas,dc=internal"
LDAP_BIND_PW="admsistemas2425"
LDAP_BASE_DN="ou=users,dc=proj-sistemas,dc=internal"
LDAP_SEARCH_FILTER="(objectClass=person)"
LDAP_ATTRS="uid"

# Função para listar utilizadores no LDAP
get_ldap_users() {
    ldapsearch -x -H "$LDAP_SERVER" -D "$LDAP_BIND_DN" -w "$LDAP_BIND_PW" -b "$LDAP_BASE_DN" "$LDAP_SEARCH_FILTER>
        awk '/^uid: / {print $2}'
}


# Função para listar utilizadores no OMV
get_omv_users() {
    # Uso do omv-rpc para listar utilizadores no OMV
    omv-rpc -u admin 'UserMgmt' 'enumerateUsers' '{}' | jq -r '.[].name'
}


# Função para adicionar utilizadores no OMV
add_user_to_omv() {
    local username=$1
    local password=$2  # Optional
    local comment="Utilizador LDAP $username"
    local email="$username@proj-sistemas.internal"  # Default email format
    local sshpubkey="$3"  # Optional SSH public key parameter


    # Verificar se o utilizador já existe no OMV
    user_exists=$(omv-rpc -u admin 'UserMgmt' 'enumerateUsers' '{}' | grep -q "\"name\": \"$username\""; echo $?)

    if [ "$user_exists" -eq 0 ]; then
        echo "Utilizador $username já existe no OMV."
    else
        # Se a chave SSH não for fornecida, passar um array vazio para 'sshpubkeys'
        if [ -n "$sshpubkey" ]; then
            sshpubkeys="[$sshpubkey]"
        else
            sshpubkeys="[]"
        fi

        # Criar o user no OMV utilizando omv-rpc e o método setUser
        response=$(omv-rpc -u admin 'UserMgmt' 'setUser' \
            "{\"name\":\"$username\", \"comment\":\"$comment\", \"email\":\"$email\", \"groups\":[\"users\"], \"p>

        if echo "$response" | grep -q "error"; then
            echo "Erro ao adicionar utilizador $username no OMV. Resposta: $response"
            return 1
        fi

        # Mensagem de sucesso, após verificar se a criação do user foi bem-sucedida
        echo "Utilizador $username adicionado ao OMV com sucesso."
    fi
}

# Função para remover utilizadores no OMV
remove_user_from_omv() {
    local username=$1

    # Verificar se o user está no grupo 'adm'
    if groups "$username" | grep -q '\badm\b'; then
        echo "O utilizador $username está no grupo 'adm'. Não será removido."
        return 0
    fi

    # Verificar se o user existe no OMV usando o RPC
    user_exists=$(omv-rpc -u admin 'UserMgmt' 'enumerateUsers' '{}' | jq -r ".[] | select(.name==\"$username\") |>

    if [ -z "$user_exists" ]; then
        echo "Utilizador $username não existe no OMV."
        return 0
    fi

    # Obter o UUID do utilizador OMV usando o RPC
    uuid=$(omv-rpc -u admin 'UserMgmt' 'getUser' "{\"name\":\"$username\"}" | jq -r '.uuid')

    if [ -n "$uuid" ]; then
        # Remover o user usando a função deleteUser com o UUID
        response=$(omv-rpc -u admin 'UserMgmt' 'deleteUser' "{\"name\":\"$username\"}")

        if echo "$response" | grep -q "error"; then
            echo "Erro ao remover utilizador $username do OMV. Resposta: $response"
            return 1
        else
            echo "Utilizador $username removido com sucesso do OMV."
        fi
    else
        echo "UUID do utilizador $username não encontrado no OMV."
    fi
}

# Sincronizar utilizadores do LDAP com o OMV
sync_users() {
    local ldap_users omv_users
    ldap_users=$(get_ldap_users)
     # Exibir a lista de utilizadores do LDAP
    echo "Utilizadores LDAP encontrados:"
    echo "$ldap_users"
    omv_users=$(get_omv_users)

    echo "$ldap_users" | while read -r user uidNumber gidNumber homeDirectory loginShell; do
        if echo "$omv_users" | grep -qw "$user"; then
            echo "Utilizador $user já existe no OMV."
        else
            add_user_to_omv "$user" "$uidNumber" "$gidNumber" "$homeDirectory" "$loginShell"
        fi
    done

    # Remover utilizadores presentes no OMV, mas ausentes no LDAP
    IFS=$'\n' read -r -d '' -a ldap_array <<< "$ldap_users"
    IFS=$'\n' read -r -d '' -a omv_array <<< "$omv_users"

    for user in "${omv_array[@]}"; do
        if ! printf '%s\n' "${ldap_array[@]}" | grep -q "^$user$"; then
            remove_user_from_omv "$user"
        fi
    done
}

# Execução da Sincronização
sync_users

