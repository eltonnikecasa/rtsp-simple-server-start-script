#!/bin/bash
# Simple RTSP Server Script by Elton Nike Casa
### BEGIN INIT INFO
# Provides: RTSP
# Required-Start: $local_fs $remote_fs
# Required-Stop: $local_fs $remote_fs
# Should-Start: $network
# Should-Stop: $network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Simple RTSP Server Script
# Description: Inicia Simple RTSP Server Script, deve ser localizado dentro da pasta do software
# rtsp-simple-server, na pasta scripts
### END INIT INFO

# Nome do Serviço
SERVERNAME="RTSP SIMPLE SERVEr"
# Nome do serviço
SERVICE="rtsp"
# Nome de usuario para rodar
USERNAME="administrador"
# Pasta do servidor
RSTPPATH="/dados/rtsp"
# Nome Sessáo Screen
SCRNAME="screen-rtsp"

## Verificar se o servidor esta rodando e informar o ID do processo
verifica() {
  # Pegar o ID do processo "Screen":
  SCREENPID=""
  SCREENPID="$(ps -ef | grep -v grep | grep -i screen | grep $SCRNAME | awk '{print $2}')"

  if [ -z "$SCREENPID" ]
  then
   return 1
  fi

  RTSPPID="$(ps -f --ppid $SCREENPID | grep $SERVICE | awk '{print $2}')"

  if [ -z "$RTSPPID" ]
  then
    return 1
  fi

  return 0
}

rtsp_start() {
  if verifica
  then
    echo " * [ERRO] $SERVERNAME esta rodando com processo (pid $RTSPPID). Não iniciar!"
    exit 1
  else
    echo " * $SERVERNAME não está rodando. Iniciando..."
    echo " * Verificando se $SERVERNAME está rodando..."

    # Checando se servidor esta rodando por 15 segundos
    COUNT=0
    while [ $COUNT -lt 15 ]; do
      if verifica
      then
        echo " * [OK] $SERVERNAME agora está rodando com ID: (pid $RTSPPID)."
	exit 0
      else
        let COUNT=COUNT+1
        sleep 1
      fi
    done
    # se o servidor não estiver rodando por 15 segundos
    echo " * [ERRO] Não foi possivel rodar o $SERVERNAME."
    exit 1
  fi
}

rtsp_stop() {
  if verifica
  then
    echo " * $SERVERNAME está rodadndo com ID (pid $RTSPPID). Iniciando o desligamento..."
    echo -n " * Parando $SERVERNAME"
    as_user "screen -p 0 -S $SCRNAME -X eval 'stuff \"stop\"\015'"

    # Checando se servidor esta rodando por 15 segundos
    COUNT=0
    while [ $COUNT -lt 15 ]; do
      if verifica
      then
        echo -n "."
        let COUNT=COUNT+1
        sleep 1
      else
        echo ""
        echo " * [OK] $SERVERNAME está fechado."
        exit 0
      fi
    done
    echo ""
    # servidor não fechou
    echo " * [ERROR] $SERVERNAME ainda está rodando com ID: (pid $RTSPPID). Não foi possivel fechar!"
    exit 1
  else
    echo " * [OK] $SERVERNAME fechou corretamente."
  fi
}

rtsp_status() {
  if verifica
  then
    echo " * $SERVERNAME status: Rodando (pid $RTSPPID)."
  else
    echo " * $SERVERNAME status: Não está rodando."
    exit 1
  fi
}

## Conectar ao console do minecraft "Sessão do Screen", para desconectar use Ctrl+a então d
mc_console() {
  if verifica
  then
    as_user "screen -S $SCRNAME -dr"
  else
    echo " * [ERRO] $SERVERNAME não está rodando! Impossivel conectar ao console."
    exit 1
  fi
}

## parametros dos scripts

case "$1" in
  start)
 rtsp_start
 ;;
  verificar)
 verifica
 ;;
  stop)
 rtsp_stop
 ;;
  restart)
 rtsp_stop
 sleep 5
 rtsp_start
 rtsp_console
 ;;
  status)
 rtsp_status
 ;;
  console)
 rtsp_console
 ;;
 *)
 echo " * Uso: rtsp_start {start|stop|restart|status|console}"
 exit 1
 ;;
esac

exit 0
