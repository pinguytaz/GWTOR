#!/usr/bin/sh
#
#    GWTOR: Portal ejecucion servicios y actualizacion reglas iptables
#           1.- FW  (Reglas para ponerel sisema como router)
#           2.- DHCP (dnsmasq)
#           3.- SSH normalmente apagado para gestion remota de reglas,etc
#           4.- TOR Habilita el sistema como un router por TOR.
#    
#   conf/     Ficheros de configuracion
###################################################################

# Variables entorno
# Servicios a arrancar
  SERVICIOS="FW DHCP #SSH #TOR"

#interfaz_EXT
INT_EXT="enp1s0"
RED_EXT=$(ip addr | grep "inet " | grep $INT_EXT | awk '{print $2}')

#Interfaces_INTs
REDES_INT="enp2s0 enp3s0"
declare -a INT_INTERNO
declare -A RED_INT

num=0
for interfaz in $REDES_INT
do
   INT_INTERNO[$num]=$interfaz
   RED_INT[$interfaz]=$(ip addr | grep "inet " | grep $interfaz | awk '{print $2}')
   num=$(($num + 1))
done

main()
{
    init
    while [ 1 ]
    do
       panel
    done
}

estados()
{
   # Recoge estados
   S_dhcp=$(systemctl is-active dnsmasq.service)
   S_fw=$(systemctl is-active iptables.service)
   S_ssh=$(systemctl is-active sshd.service)
   S_tor=$(systemctl is-active tor.service)
}

init()
{
   estados #Recogemos estados de los servicios que nos interesan

   # Iniciamos los servicios configurados
   for i in $SERVICIOS
   do
      case $i in 
         "DHCP")
            if [ "$S_dhcp" = "inactive" ]; then
               a_dhcp
            fi
            ;;   
         "FW")
            if [ "$S_fw" = "inactive" ]; then
               a_fw
            fi
            ;;   
         "SSH")
            if [ "$S_ssh" = "inactive" ]; then
               a_ssh
            fi
            ;;   
         "TOR")
            if [ "$S_tor" = "inactive" ]; then
               a_tor
            fi
      esac
   done 
}

panel()
{
   estados #Recogemos estados de los servicios 

   clear
   echo "*****************************************"
   echo "*         Panel de control GWTOR        *     ****************   REDES  *****************"
   echo "*                                       *        EXTERIOR $INT_EXT: $RED_EXT"
   echo "* github: pinguytaz                     *        INTERNA1 ${INT_INTERNO[0]}: ${RED_INT[${INT_INTERNO[0]}]}"
   echo "* https://www.pinguytaz.net             *        INTERNA2 ${INT_INTERNO[1]}: ${RED_INT[${INT_INTERNO[1]}]}"
   echo "*                                       *" 
   echo "*****************************************"
   echo ""
   echo "*****   Estado de los servicios   *****"
   echo "          DHCP:          $S_dhcp"
   echo "          Firewall:      $S_fw"
   echo "          SSH:           $S_ssh"
   echo "          TOR:           $S_tor"
   echo ""
   echo ""
   echo "************************ MENU ***********************"
   echo "     0) Apagar                 1) Shell"
   echo "     2) Apaga Firewall         3) Arranca Firewall"
   echo "     4) Apaga DHCP             5) Arranca DHCP"
   echo "     6) Apaga SSH              7) Arranca SSH"
   echo "     8) Apaga TOR              9) Arranca TOR"
   echo ""

   read -p"Opcion: " -r opt
   case $opt in
      "0")
         echo "poweroff"
         ;;
      1)
         sh
         ;;
      2)
         p_fw
         ;;
      3)
         a_fw
         ;;
      4)
         p_dhcp
         ;;
      5)
         a_dhcp
         ;;
      6)
         p_ssh
         ;;
      7)
         a_ssh
         ;;
      8)
         p_tor
         ;;
      9)
         a_tor
         ;;
   esac
}

############################## Firewall #############################################
a_fw()     # Arranca el FW
{
   # Iniciamos servicios Firewall y reglas si esta apagado"
   if [ "$S_fw" = "inactive" ]; then
      systemctl start iptables
      resetReglas
      ReglasIniciales

      #Reglas de servicios comunes activos
      accion="A"
      if [ "$S_dhcp" = "active" ]; then
         r_dhcp
      fi
      if [ "$S_ssh" = "active" ]; then
         r_ssh
      fi


      #Definir reglas extras: nat entrada....

   fi
}

p_fw()     # Para el FW
{
   if [ "$S_fw" = "active" ]; then
      systemctl stop iptables
      resetReglas
   fi
}

resetReglas()
{
   # Reseteo de la reglas    iptables -nvL
   iptables -F
   iptables -X
   iptables -t nat -F
   iptables -t nat -X
   iptables -t mangle -F
   iptables -t mangle -X
   iptables -t raw -F
   iptables -t raw -X
   iptables -t security -F
   iptables -t security -X
}

ReglasIniciales()
{
   # Politica de reglas por defecto
   iptables -P INPUT DROP          # Por defecto toda entrada se tira
   iptables -P FORWARD DROP        # Por defecto todo redireccionamiento se tira
   #iptables -P OUTPUT ACCEPT
   iptables -P OUTPUT DROP

   # LOGs para depuracion journalctl -kj | grep IN=.*OUT=.*
   #iptables -A INPUT -j LOG --log-prefix "LOG para ver ENtradas " --log-ip-options --log-tcp-options
   #iptables -A OUTPUT -j LOG --log-prefix "LOG para ver Salidas " --log-ip-options --log-tcp-options
   #iptables -A FORWARD -j LOG --log-prefix "LOG para ver redireccion " --log-ip-options --log-tcp-options

   # ************ ENTRADA
   #Reglas por defecto de proteccion ataques 
   #Rechazamos paquetes Invalidos
   #iptables -A INPUT -m state --state INVALID -j LOG --log-prefix "DROP Entrada-INVALIDA " --log-ip-options --log-tcp-options
   iptables -A INPUT -m state --state INVALID -j DROP

   # Entradas permitidas, tambien ponerlas al abrir servicios.
   iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
   iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT   #Permitimos recibir ping
   iptables -A INPUT -i lo -j ACCEPT

   # ************************************** SALIDA
   iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
   iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT   
   iptables -A OUTPUT -i lo -j ACCEPT

   iptables -A OUTPUT -p tcp -j ACCEPT  # Todo TCP
   iptables -A OUTPUT -p udp -j ACCEPT  # Todo UDP



   # ************************************** REDIRECCION
   #iptables -A FORWARD -m state --state INVALID -j LOG --log-prefix "DROP Forwrard-INVALIDO " --log-ip-options --log-tcp-options
   iptables -A FORWARD -m state --state INVALID -j DROP
   iptables -A FORWARD -p icmp --icmp-type echo-request -j ACCEPT   
 
   # Realizamos NAT el trafico origen de red interna1 y saliente por EXT
   iptables -A FORWARD -i $INT_EXT -j ACCEPT 
   iptables -A FORWARD -i ${INT_INTERNO[0]} -j ACCEPT 
   iptables -t nat -A POSTROUTING -s ${RED_INT[${INT_INTERNO[0]}]} -o $INT_EXT -j MASQUERADE
}

############################## DHCP #############################################
a_dhcp()
{
   if [ "$S_dhcp" = "inactive" ]; then
      systemctl start dnsmasq
      accion="A"
      r_dhcp
   fi
}

p_dhcp()
{
   if [ "$S_dhcp" = "active" ]; then
      systemctl stop dnsmasq
      accion="D"
      r_dhcp
   fi
}
r_dhcp()
{
   iptables -$accion INPUT -i ${INT_INTERNO[0]} -p udp --dport 67 -j ACCEPT

   # DHCP para el segundo interfaz, recordar activarlo en dnsmasq
   iptables -$accion INPUT -i ${INT_INTERNO[1]} -p udp --dport 67 -j ACCEPT
}

############################## SSH #############################################
a_ssh()
{
   if [ "$S_ssh" = "inactive" ]; then
      systemctl start sshd
      accion="A"
      r_ssh
   fi
}

p_ssh()
{
   if [ "$S_ssh" = "active" ]; then
      systemctl stop sshd
      accion="D"
      r_ssh
   fi
}
r_ssh()
{
   iptables -$accion INPUT -i ${INT_INTERNO[0]} -p tcp --dport 2222 -j ACCEPT
}

############################## TOR #############################################
a_tor()
{
   if [ "$S_tor" = "inactive" ]; then
      systemctl start tor
      accion="A"
      r_tor
   fi
}

p_tor()
{
   if [ "$S_tor" = "active" ]; then
      systemctl stop tor
      accion="D"
      r_tor
   fi
}
r_tor()
{
   #Variables especificad de TOR
   uid_tor=`id -u tor`
   trans_port="9040"
   dns_port="5353"
   # Tor's VirtualAddrNetworkIPv4
   virt_addr="10.192.0.0/10"
   no_tor="127.0.0.0/8"


   # *nat PREROUTING (For middlebox)
   iptables -t nat -$accion PREROUTING -d $virt_addr -i ${INT_INTERNO[0]} -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -j REDIRECT --to-ports $trans_port
   iptables -t nat -$accion PREROUTING -i ${INT_INTERNO[0]} -p udp --dport 53 -j REDIRECT --to-ports $dns_port

   #No redirije por TOR local, e ip de red externa e interna
   for _lan in $no_tor $RED_EXT ${RED_INT[${INT_INTERNO[0]}]} ; do
      iptables -t nat -$accion PREROUTING -i ${INT_INTERNO[0]} -d $_lan -j RETURN
   done

   iptables -t nat -$accion PREROUTING -i ${INT_INTERNO[0]} -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -j REDIRECT --to-ports $trans_port

   ### *nat OUTPUT (For local redirection) direcciones .onion
   iptables -t nat -$accion OUTPUT -d $virt_addr -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -j REDIRECT --to-ports $trans_port
   iptables -t nat -$accion OUTPUT -d 127.0.0.1/32 -p udp -m udp --dport 53 -j REDIRECT --to-ports $dns_port

   # No procesamos  salida locales
   iptables -t nat -$accion OUTPUT -m owner --uid-owner $uid_tor -j RETURN
   iptables -t nat -$accion OUTPUT -o lo -j RETURN
   for _lan in $no_tor $RED_EXT ${RED_INT[${INT_INTERNO[0]}]} ; do
     iptables -t nat -$accion OUTPUT -d $_lan -j RETURN
   done

   iptables -t nat -$accion OUTPUT -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -j REDIRECT --to-ports $trans_port

   # Redireccion del prerouting y salida a TransPort
   iptables -$accion INPUT -d ${RED_INT[${INT_INTERNO[0]}]} -i ${INT_INTERNO[0]} -p udp -m udp --dport $dns_port -j ACCEPT
   iptables -$accion INPUT -d ${RED_INT[${INT_INTERNO[0]}]} -i ${INT_INTERNO[0]} -p tcp -m tcp --dport $trans_port --tcp-flags FIN,SYN,RST,ACK SYN -j ACCEPT

   # Procesa salida TOR
   iptables -$accion OUTPUT -o $INT_EXT -m owner --uid-owner $uid_tor -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -m state --state NEW -j ACCEPT

   # Permite Salida Loopback
   # Tor transproxy magic
   iptables -$accion OUTPUT -d 127.0.0.1/32 -p tcp -m tcp --dport $trans_port --tcp-flags FIN,SYN,RST,ACK SYN -j ACCEPT
}



main
