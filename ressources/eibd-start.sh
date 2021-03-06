#!/bin/sh
### BEGIN INIT INFO
# Provides:          eibd
# Required-Start:    $local_fs $remote_fs $network
# Required-Stop:     $local_fs $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: eibd initscript
# Description:       based on init-script from knx-user-forum.de and setup-eibd.sh from KNXlive-project
#                    Pending: check tpuarts, check KNXnet/IP-Response
### END INIT INFO

PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/local/bin
DESC="EIB/KNX daemon"
NAME=eibd
DAEMON=/usr/local/bin/$NAME
DAEMON_ARGS="-d -u --eibaddr=1.1.100 -c -DTS -R -i --pid-file=/var/run/$NAME.pid"
PIDFILE=/var/run/$NAME.pid
SCRIPTNAME=/etc/init.d/$NAME

# Default URL, config read from default later
# !!! DO NOT CHANGE DEFAULTS HERE - use /etc/default/eibd !!!
# AUTO scans and saves as default
EIBD_BACKEND="AUTO"

# Exit if the package is not installed
[ -x "$DAEMON" ] || exit 0

# Read configuration variable file if it is present
# Temp-fix! remove surrounding whitespaces from seperator '='
[ -r /etc/default/$NAME ] && cat /etc/default/$NAME | sed 's/ =/=/' | sed 's/= /=/' > /etc/default/$NAME.out
[ -r /etc/default/$NAME.out ] && . /etc/default/$NAME.out

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.0-6) to ensure that this file is present.
. /lib/lsb/init-functions


do_init()
{
    # Auto-Detection Backend-interface
    if [ "$EIBD_BACKEND" = "AUTO" -o "$EIBD_BACKEND" = "usb" ]; then
        [ "$VERBOSE" != no ] && log_daemon_msg "Autodetecting eibd-Backend"
        echo -ne "\t *** $NAME: Autodetecting Interface ."
        # try USB
        # old EIBD_USBPORT=$(findknxusb | sed -e '3 d' -e 's/device //' | cut -d':' -f1-2)
        EIBD_USBPORT=$(findknxusb | sed -e '1 d' -e 's/device //' | cut -d ' ' -f 2 | cut -d':' -f1-2); echo $EIBD_USBPORT
        if [ -n "$EIBD_USBPORT" ]
            then
            EIBD_BACKEND=usb
            EIBD_URL=$EIBD_BACKEND:$EIBD_USBPORT
            [ "$VERBOSE" != no ] && log_daemon_msg " success on $EIBD_URL"
            echo -e " success on $EIBD_URL"
        fi
    fi

    if [ "$EIBD_BACKEND" = "AUTO" -a -e /dev/ttyS0 ]; then
        # try FT1.2 on /dev/ttyS0
        echo -n " ."
        setserial /dev/ttyS0 autoconfig
        if bcuaddrtab -T 10 ft12:/dev/ttyS0 >/dev/null ;    then
            EIBD_BACKEND=ft12
            EIBD_URL=$EIBD_BACKEND:/dev/ttyS0
            [ "$VERBOSE" != no ] && log_daemon_msg " success on $EIBD_URL"
            echo -e " success on $EIBD_URL"
        fi
    fi

    if [ "$EIBD_BACKEND" = "AUTO" -a -e /dev/eib0 ]; then
        # try BCU1 Kernel-Driver on /dev/ttyS0
        echo -n " ."
        setserial /dev/ttyS0 uart none
        if bcuaddrtab -T 10 bcu1:/dev/eib0 >/dev/null ; then
            EIBD_BACKEND=bcu1
            EIBD_URL=$EIBD_BACKEND:/dev/eib0
            [ "$VERBOSE" != no ] && log_daemon_msg " success on $EIBD_URL"
            echo -e " success on $EIBD_URL"
        fi
    fi

    if [ "$EIBD_BACKEND" = "AUTO" ]; then
        # try KNXnet/IP Routing with default Multicast 224.0.23.12
        echo -n " ."
        EIBNETTMP=`mktemp`
        eibnetsearch - > $EIBNETTMP
        EIBD_NET_MCAST=`grep Multicast $EIBNETTMP | cut -d' ' -f2`
        EIBD_NET_HOST=`grep Answer $EIBNETTMP | cut -d' ' -f3`
        EIBD_NET_NAME=`grep Name $EIBNETTMP | cut -d' ' -f2`
        EIBD_MY_IP=`ifconfig eth0 | grep 'inet addr' | sed -e 's/:/ /' | awk '{print $3}'`
        rm $EIBNETTMP
        if [ "$EIBD_NET_MCAST" != "" -a "$EIBD_NET_HOST" != "$EIBD_MY_IP" ]; then
            EIBD_BACKEND=ip
            EIBD_URL=$EIBD_BACKEND:
            [ "$VERBOSE" != no ] && log_daemon_msg "Found KNXnet/IP Router $EIBD_NET_NAME on $EIBD_NET_HOST with $EIBD_NET_MCAST"
            echo -e "Found KNXnet/IP Router $EIBD_NET_NAME on $EIBD_NET_HOST with $EIBD_NET_MCAST"
        fi
    fi

    if [ "$EIBD_BACKEND" = "AUTO" -a -e /dev/ttyS1 ]; then
        # try FT1.2 on /dev/ttyS1
        echo -n " ."
        setserial /dev/ttyS1 autoconfig
        if bcuaddrtab -T 10 ft12:/dev/ttyS1 >/dev/null ; then
            EIBD_BACKEND=ft12
            EIBD_URL=$EIBD_BACKEND:/dev/ttyS1
            [ "$VERBOSE" != no ] && log_daemon_msg " success on $EIBD_URL"
            echo -e " success on $EIBD_URL"
        fi
    fi

    if [ "$EIBD_BACKEND" = "AUTO" -a -e /dev/eib1 ]; then
        # try BCU1 Kernel-Driver on /dev/ttyS1
        echo -n " ."
        setserial /dev/ttyS1 uart none
        if bcuaddrtab -T 10 bcu1:/dev/eib1 >/dev/null ; then
            EIBD_BACKEND=bcu1
            EIBD_URL=$EIBD_BACKEND:/dev/eib1
            [ "$VERBOSE" != no ] && log_daemon_msg " success on $EIBD_URL"
            echo -e " success on $EIBD_URL"
        fi
    fi

    if [ "$EIBD_BACKEND" = "AUTO" ]; then
        # Autodetect failed - bailout
        echo -e "\t *** $NAME: Autodetect failed - exiting !"
        exit 0
    fi

    # concat urls
    if [ "$EIBD_BACKEND" = "ip" -a -n "$EIBD_PORT_IP" ]; then
        EIBD_URL=$EIBD_BACKEND:$EIBD_PORT_IP
    fi
    if [ "$EIBD_BACKEND" = "ipt" -a -n "$EIBD_PORT_IPT" ]; then
        EIBD_URL=$EIBD_BACKEND:$EIBD_PORT_IPT
    fi
    # init serial port accordingly
    if [ "$EIBD_BACKEND" = "ft12" -a -n "$EIBD_PORT_SERIAL" ]; then
        setserial $EIBD_PORT_SERIAL autoconfig
        EIBD_URL=$EIBD_BACKEND:$EIBD_PORT_SERIAL
    fi
    if [ "$EIBD_BACKEND" = "bcu1" -a "$EIBD_PORT_SERIAL" = "/dev/eib0" ]; then
        setserial /dev/ttyS0 uart none
        EIBD_URL=$EIBD_BACKEND:$EIBD_PORT_SERIAL
    fi
    if [ "$EIBD_BACKEND" = "bcu1" -a "$EIBD_PORT_SERIAL" = "/dev/eib1" ]; then
        setserial /dev/ttyS1 uart none
        EIBD_URL=$EIBD_BACKEND:$EIBD_PORT_SERIAL
    fi
    if [ "$EIBD_BACKEND" = "tpuarts" -a -n "$EIBD_PORT_SERIAL" ]; then
        setserial $EIBD_PORT_SERIAL autoconfig
        EIBD_URL=$EIBD_BACKEND:$EIBD_PORT_SERIAL
    fi

    # concat EIBD_URL (obsolete!)
    if [ -z "$EIBD_URL" -a -n "$EIBD_PORT" ]; then
        EIBD_URL=$EIBD_BACKEND:$EIBD_PORT
    fi


    # check/write bcuaddrtab
    if [ "$EIBD_BACKEND" = "usb" -o "$EIBD_BACKEND" = "ft12" -o "$EIBD_BACKEND" = "bcu1" -a -n "$EIBD_URL" ]; then
        EIBD_BCUADDRTAB=`bcuaddrtab -T 10 $EIBD_URL | cut -d ' ' -f 2`
        if [ "$EIBD_BCUADDRTAB" = "expected" -o "$EIBD_BCUADDRTAB" = "failed" -o "$EIBD_BCUADDRTAB" = "timed" ]; then
            # retry 1
            echo -n "Unable to read BCU address table - retrying 1"
            sleep 2
            EIBD_BCUADDRTAB=`bcuaddrtab -T 10 $EIBD_URL | cut -d ' ' -f 2`
            if [ "$EIBD_BCUADDRTAB" = "expected" -o "$EIBD_BCUADDRTAB" = "failed" -o "$EIBD_BCUADDRTAB" = "timed" ]; then
                # retry 2
                echo -n " - retrying 2 .."
                sleep 2
                EIBD_BCUADDRTAB=`bcuaddrtab -T 10 $EIBD_URL | cut -d ' ' -f 2`
                if [ "$EIBD_BCUADDRTAB" = "expected" -o "$EIBD_BCUADDRTAB" = "failed" -o "$EIBD_BCUADDRTAB" = "timed" ]; then
                    echo -n " - FAILED on $EIBD_BACKEND (url $EIBD_URL) (size $EIBD_BCUADDRTAB) ! "
                    # only fail on usb/FT12 as bcu1 might still be ok
                    if [ "$EIBD_BACKEND" = "bcu1" ]; then
                        EIBD_BCUADDRTAB=0
                    else
                        log_end_msg 2
                        exit 2
                    fi
                fi
            fi
        fi
        if [ "$EIBD_BCUADDRTAB" -gt 0 ]; then
            echo "Resetting BCU address table length! Old value $EIBD_BCUADDRTAB"
            bcuaddrtab -T 30 -w 0 $EIBD_URL
        fi
        # fix for broken ABB/BJ USB-If
        USBNAME=`findknxusb | grep ^device | cut -d '(' -f 2,3`
        if [ "$EIBD_BACKEND" = "usb" -a "$USBNAME" = "ABB STOTZ-KONTAKT GmbH:KNX-USB Interface (MDRC))" ]; then
            echo "ABB-fix: Resetting BCU address table length! Old value $EIBD_BCUADDRTAB"
            bcuaddrtab -T 30 -w 0 $EIBD_URL
        fi
    fi

    # Concat ARGS
    if [ -n "$EIBD_R" ]; then
        DAEMON_ARGS=" -R $DAEMON_ARGS"
        EIBD_I=y
    fi
    if [ -n "$EIBD_T" ]; then
        DAEMON_ARGS=" -T $DAEMON_ARGS"
        EIBD_I=y
    fi
    if [ -n "$EIBD_I" ]; then
        DAEMON_ARGS=" -S -D -i $DAEMON_ARGS"
    fi
    if [ -n "$EIBD_C" ]; then
        DAEMON_ARGS=" -c $DAEMON_ARGS"
    fi
    # use -e option to set address
    if [ -n "$EIBD_BACKEND_ADDR" ]; then
        DAEMON_ARGS=" -e $EIBD_BACKEND_ADDR $DAEMON_ARGS"
    fi

    DAEMON_ARGS="$DAEMON_ARGS $EIBD_ADDTL_ARGS $EIBD_URL"
}

#
# Function that starts the daemon/service
#
do_start()
{
    route add 224.0.23.12 dev eth0
    #echo "DEBUG args: $DAEMON_ARGS eibdi: $EIBD_I eibdt: $EIBD_T eibdr: $EIBD_R backend: $EIBD_BACKEND url: $EIBD_URL port: $EIBD_PORT addrtab: $EIBD_BCUADDRTAB"
    # Return
        #   0 if daemon has been started
        #   1 if daemon was already running
        #   2 if daemon could not be started
        start-stop-daemon --start --quiet --pidfile $PIDFILE --exec $DAEMON --test > /dev/null \
                || return 1
        do_init
    echo "*** Starting $DESC: $NAME using $EIBD_URL"
        start-stop-daemon --start --quiet --pidfile $PIDFILE --exec $DAEMON -- \
                $DAEMON_ARGS \
                || return 2
        # Add code here, if necessary, that waits for the process to be ready
        # to handle requests from services started subsequently which depend
        # on this one.  As a last resort, sleep for some time.
        sleep 2
		mkdir /tmp/eib
        chmod a+rw /tmp/eib
}
#
# Function that stops the daemon/service
#
do_stop()
{
        # Return
        #   0 if daemon has been stopped
        #   1 if daemon was already stopped
        #   2 if daemon could not be stopped
        #   other if a failure occurred
        start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile $PIDFILE --name $NAME
        RETVAL="$?"
        [ "$RETVAL" = 2 ] && return 2
        # Wait for children to finish too if this is a daemon that forks
        # and if the daemon is only ever run from this initscript.
        # If the above conditions are not satisfied then add some other code
        # that waits for the process to drop all resources that could be
        # needed by services started subsequently.  A last resort is to
        # sleep for some time.
        start-stop-daemon --stop --quiet --oknodo --retry=0/30/KILL/5 --exec $DAEMON
    [ "$?" = 2 ] && return 2
        # Many daemons don't delete their pidfiles when they exit.
        rm -f $PIDFILE
        route delete 224.0.23.12
        return "$RETVAL"
}

#
# Function that sends a SIGHUP to the daemon/service
#
do_reload() {
        #
        # If the daemon can reload its configuration without
        # restarting (for example, when it is sent a SIGHUP),
        # then implement that here.
        #
        start-stop-daemon --stop --signal 1 --quiet --pidfile $PIDFILE --name $NAME
        return 0
}

case "$1" in
  start)
        [ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC using $EIBD_URL" "$NAME"
        do_start
        case "$?" in
                0|1) log_end_msg 0 ;;
                2) [ log_end_msg 1 ;;
        esac
        ;;
  stop)
        [ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$NAME"
    echo "*** Stopping $DESC" "$NAME"
        do_stop
        case "$?" in
                0|1) log_end_msg 0 ;;
                2) [ log_end_msg 1 ;;
        esac
        ;;
  #reload|force-reload)
        #
        # If do_reload() is not implemented then leave this commented out
        # and leave 'force-reload' as an alias for 'restart'.
        #
        #log_daemon_msg "Reloading $DESC" "$NAME"
        #do_reload
        #log_end_msg $?
        #;;
  restart|force-reload)
        #
        # If the "reload" option is implemented then remove the
        # 'force-reload' alias
        #
        echo "*** Restarting $DESC" "$NAME"
        do_stop
        case "$?" in
          0|1)
        sleep 2
                do_start
                case "$?" in
                        0) log_end_msg 0 ;;
                        1) log_end_msg 1 ;; # Old process is still running
                        *) log_end_msg 1 ;; # Failed to start
                esac
                ;;
          *)

                # Failed to stop
                log_end_msg 1
                ;;
        esac
        ;;
  *)
        #echo "Usage: $SCRIPTNAME {start|stop|restart|reload|force-reload}" >&2
        echo "Usage: $SCRIPTNAME {start|stop|restart|force-reload}" >&2
        exit 3
        ;;
esac