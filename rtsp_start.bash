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
# Executavel
SERVICE="rtsp-simple-server"
# Nome de usuario para rodar
USERNAME="administrador"
# Pasta do servidor
RSTPPATH="/dados/rtsp"
# Nome Sessáo Screen
SCRNAME="rtsp"

## Rodar todos os comando como usuario especifico
as_user() {  ME="$(whoami)"
  if [ "$ME" == "$USERNAME" ]
  then
    bash -c "$1"
  else
    su - "$USERNAME" -c "$1"
  fi
}

verifica() {
#  verifica se o simple rtsp está sendo executado
  dataok=`date`
  
  if pgrep "rtsp" > /dev/null
  then
    return 1
    dataok=`date`
    echo "$dataok = OK" >> $RSTPPATH/logs/reboot.log
  else
    return 0
    echo "$dataok = REBOOT" >> $RSTPPATH/logs/reboot.log
    $RSTPPATH/scripts/rtsp_start restart
fi
}

## Verificar se o servidor esta rodando e informar o ID do processo
verifica() {
  # Pegar data para registrar no log:
  DATENOW=`date`
  # Pegar o ID do processo "Screen":
  SCREENPID=""
  SCREENPID="$(ps -ef | grep -v grep | grep -i screen | grep $SCRNAME | awk '{print $2}')"

  if [ -z "$SCREENPID" ]
  then
   echo "$dataok = OK" >> $RSTPPATH/logs/reboot.log
   return 1
  fi

  JAVAPID="$(ps -f --ppid $SCREENPID | grep $SERVICE | awk '{print $2}')"

  if [ -z "$JAVAPID" ]
  then
    return 1
  fi

  return 0
}

rtsp_start() {
  if verifica
  then
    echo " * [ERRO] $SERVERNAME esta rodando com processo (pid $JAVAPID). Não iniciar!"
    exit 1
  else
    echo " * $SERVERNAME não está rodando. Iniciando..."
    echo " * Usuando mapa \"$WORLDNAME\"..."
    as_user "cd \"$RSTPPATH\" && screen -c /dev/null -dmS $SCRNAME $EXECUTAR"
    echo " * Verificando se $SERVERNAME está rodando..."

    # Checando se servidor esta rodando por 15 segundos
    COUNT=0
    while [ $COUNT -lt 15 ]; do
      if server_running
      then
        echo " * [OK] $SERVERNAME agora está rodando com ID: (pid $JAVAPID)."
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

mc_stop() {
  if server_running
  then
    echo " * $SERVERNAME está rodadndo com ID (pid $JAVAPID). Iniciando o desligamento..."
    echo " * Avisando usuarios que o servidor está fechando..."
    as_user "screen -p 0 -S $SCRNAME -X eval 'stuff \"broadcast SERVIDOR ESTÁ REINICIANDO\"\015'"
    as_user "screen -p 0 -S $SCRNAME -X eval 'itens \"save-all\"\015'"
    as_user "screen -p 0 -S $SCRNAME -X eval 'stuff \"broadcast SERVIDOR VOLTARA EM 1 MINUTO\"\015'"
    as_user "screen -p 0 -S $SCRNAME -X eval 'stuff \"broadcast MELHORANDO SERVIDOR PARA VOCÊS\"\015'"
    # começando contador de 20 segundos para verificar se o servidor fechou
    COUNT=0
    while [ $COUNT -lt 10 ]; do
      echo -n "."
      sleep 2
      if [ -f "$RSTPPATH/logs/latest.log" ]
      then
        if [[ "$(tail -n 20 $RSTPPATH/logs/latest.log | grep -E 'Save complete|Saved the world' | wc -l)" -gt 0 ]]; then
          COUNT=99
        fi
      fi
      let COUNT=COUNT+1
    done
    echo ""

    echo -n " * Parando $SERVERNAME"
    as_user "screen -p 0 -S $SCRNAME -X eval 'stuff \"stop\"\015'"

    # Checando se servidor esta rodando por 15 segundos
    COUNT=0
    while [ $COUNT -lt 15 ]; do
      if server_running
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
    echo " * [ERROR] $SERVERNAME ainda está rodando com ID: (pid $JAVAPID). Não foi possivel fechar!"
    exit 1
  else
    echo " * [OK] $SERVERNAME fechou corretamente."
  fi
}

rtsp_status() {
  if server_running
  then
    echo " * $SERVERNAME status: Rodando (pid $JAVAPID)."
  else
    echo " * $SERVERNAME status: Não está rodando."
    exit 1
  fi
}

## Conectar ao console do minecraft "Sessão do Screen", para desconectar use Ctrl+a então d
mc_console() {
  if server_running
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
 mc_start
 ;;
  verificar)
 verifica
 ;;
  stop)
 mc_stop
 ;;
  restart)
 mc_stop
 sleep 5
 mc_start
 mc_console
 ;;
  status)
 mc_status
 ;;
  console)
 mc_console
 ;;
 *)
 echo " * Uso: rtsp_start {start|stop|restart|status|console}"
 exit 1
 ;;
esac

exit 0
