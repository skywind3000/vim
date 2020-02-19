#! /bin/sh

# create forward rule by source interface
# http://serverfault.com/questions/532569/how-to-do-port-forwarding-redirecting-on-debian
PortForward1() {
    local IN_IF=$1
    local IN_PORT=$2
    local OUT_IP=$3
    local OUT_PORT=$4
    local IPTBL="/sbin/iptables"
    echo "1" > /proc/sys/net/ipv4/ip_forward
    $IPTBL -A PREROUTING -t nat -i $IN_IF -p tcp --dport $IN_PORT -j DNAT --to-destination ${OUT_IP}:${OUT_PORT}
    $IPTBL -A FORWARD -p tcp -d $OUT_IP --dport $OUT_PORT -j ACCEPT
    $IPTBL -A POSTROUTING -t nat -j MASQUERADE
}

# create forward rule by source ip
# http://blog.csdn.net/zzhongcy/article/details/42738285
ForwardPort2() {
    local IN_IP=$1
    local IN_PORT=$2
    local OUT_IP=$3
    local OUT_PORT=$4
    local IPTBL="/sbin/iptables"
    echo "1" > /proc/sys/net/ipv4/ip_forward
    $IPTBL -t nat -A PREROUTING --dst $IN_IP -p tcp --dport $IN_PORT -j DNAT --to-destination ${OUT_IP}:${OUT_PORT}
    $IPTBL -t nat -A POSTROUTING --dst $OUT_IP -p tcp --dport $OUT_PORT -j SNAT --to-source $IN_IP
}

#PortForward1 eth3 8765 106.185.43.192 8765
#PortForward1 eth3 32201 106.185.43.192 32200
#PortForward1 eth3 32202 106.185.43.192 32200
#PortForward1 eth3 6443 106.185.43.192 443

