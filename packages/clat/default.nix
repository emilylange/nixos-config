{ interface
, ipv6
, nat64
, pkgs
, ...
}:

pkgs.writeShellApplication {
  name = "clat.sh";
  runtimeInputs = with pkgs; [
    iproute2
    jool-cli
    sysctl
  ];
  text = ''
    set -o xtrace
    ns_name=joolns

    start() {
      ip netns add "$ns_name"
      ip link add name to_jool type veth peer name to_world
      ip link set up dev to_jool
      ip link set dev to_world netns "$ns_name"
      ip netns exec "$ns_name" ip link set up dev to_world

      to_jool_linklocal=$(ip -6 address show scope link dev to_jool | grep -Po "inet6 \K[0-9a-f:]+")
      to_world_linklocal=$(ip netns exec joolns ip -6 address show scope link dev to_world | grep -Po "inet6 \K[0-9a-f:]+")
      ip netns exec "$ns_name" ip -6 route add default via "$to_jool_linklocal" dev to_world
      ip netns exec "$ns_name" ip -4 address add 192.168.0.2/24 dev to_world

      ip netns exec joolns jool_siit instance add --netfilter --pool6 "${nat64}"
      ip netns exec joolns jool_siit eamt add 192.168.0.1 "${ipv6}"

      ip netns exec joolns sysctl -w net.ipv6.conf.all.forwarding=1
      ip -6 neigh add proxy "${ipv6}" dev "${interface}"
      ip -6 route add "${ipv6}" via "$to_world_linklocal" dev to_jool

      ip -4 address add 192.168.0.1/24 dev to_jool
      ip -4 route add default via 192.168.0.2 dev to_jool
    }

    stop() {
      ip netns del "$ns_name"
    }

    case "$1" in
      start)
        start
        ;;
      stop)
        stop
        ;;
      "")
        echo "Specify start or stop"
        exit 1
        ;;
    esac
  '';
}
