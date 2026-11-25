
REDIS_IP=$( kubectl get svc redis -o custom-columns=EXT:.status.loadBalancer.ingress[0].ip --no-headers )

if [ "$1" = "get" ]; then
    printf "GET count\r\nQUIT\r\n"  | curl -s telnet://${REDIS_IP}:6379
else
    printf "INCR count\r\nQUIT\r\n" | curl -s telnet://${REDIS_IP}:6379
fi


