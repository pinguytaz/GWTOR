# GWTOR  (Un Gateway-Router con TOR)

[![license](https://www.pinguytaz.net/IMG_GITHUB/gplv3-with-text-84x42.png)] (https://github.com/pinguytaz/Arduino/blob/master/LICENSE)
<BR><BR><BR>

El proyecto es muy sencillo y es crear una pequeña maquina que nos permita servir de Gateway y cuando lo deseemos activar TOR de forma que todas las maquinas conectadas a ella envien el trafico por la red TOR.

La idea surge viendo WHONIX pero con la intención de generar la minima expresión el elemento que nos gusto, el GateWay, de forma que lo podamos poner facilmente en nuestro laboratorio de maquinas virtuales o llevarlo a una RaspBerryPi por ejemplo y crear nuestro router de casa de forma que todo pase por ejemplo por TOR, una VPN o tengamos una traza controlada a nuestro antojo de las comunicaciones de casa.

Esta maquina es muy sencilla y solo dispone de los servicios: DHCP (con dnsmasq), firewall (con iptables), un ssh para posible mantenimiento que normalmente estara desconectado y TOR.
La idea es que esta maquina nos permita crear nuestro laboratorio de analisis de malware por ejemplo y añadir algun otro componente (ejemplo VPN) pero siempre lo minimo.

<BR>

__Maquina Virtual__ 
    Nuestra maquina es una distribución ArchLinux con lo minimo aunque la idea es generar una Alpine tambien, asi como ir añadiendo reglas iptables de protección y acceso VPN
    Definir con ntui las interfaz de red.

**Instalación Archlinux para GWTROR.**   
   pacstrap -K /mnt base linux linux-firmware intel-ucode networkmanager vi man man-pages-es efibootmgr grub xdg-user-dirs usbutils dnsmasq iptables tor openssh
  
**ficheros de configuración y scripts**  
    Portal.sh    Arrancamos los servicios definidos, Dhcp, firewall, ssh (por regla general estara apagado) y tor.
                 tambien podremos desde este interfaz apagarlos y encenderlos.  
    /etc/dnsmasq.conf    Configuración de DHCP  
    /etc/ssh/ssh_config  Cambiamos puerto para que sea distinto de 22, lo normal es no dejar a root pero en nuestro caso es el unico usuario.
   /etc/tor/torrc        Configuración de tor, deberemos cambiar las IPs con respecto a nuestra configuración.



<br><br><br>

__Website__: <https://www.pinguytaz.net>

