# From: https://github.com/luksa/kubernetes-in-action/blob/master/Chapter08/kubectl-proxy/Dockerfile

FROM alpine

RUN apk update && apk add jq && apk add curl && curl -L -O https://dl.k8s.io/v1.30.3/kubernetes-client-linux-amd64.tar.gz && tar zvxf kubernetes-client-linux-amd64.tar.gz kubernetes/client/bin/kubectl && mv kubernetes/client/bin/kubectl / && rm -rf kubernetes && rm -f kubernetes-client-linux-amd64.tar.gz
#RUN apk update && apk add jq && apk add curl && apk add jq && curl -L -O https://dl.k8s.io/v1.30.3/kubernetes-client-linux-arm64.tar.gz && tar zvxf kubernetes-client-linux-arm64.tar.gz kubernetes/client/bin/kubectl && mv kubernetes/client/bin/kubectl / && rm -rf kubernetes && rm -f kubernetes-client-linux-arm64.tar.gz

ADD kubectl-proxy.sh /kubectl-proxy.sh
ADD wget-api.sh      /wget-api.sh
#RUN chmod +x /kubectl-proxy.sh
RUN ls -al   /*.sh

ENTRYPOINT /kubectl-proxy.sh

