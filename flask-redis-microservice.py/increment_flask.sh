
FLASK_IP=$( kubectl get svc flask-app -o custom-columns=EXT:.status.loadBalancer.ingress[0].ip --no-headers )

curl -s http://${FLASK_IP}:5000


