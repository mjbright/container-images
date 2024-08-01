
# kubectl-proxy

TODO: rebuild this as a multi-arch image
TODO: pickup architecture in Dockerfile to pull appropriate kubectl binary

Container image which includes ``kubectl```.

``kubectl proxy``` is used by the wget_api.sh script to access the Kubernetes API

You will need to create appropriate Service Account, Role and RoleBindings, see setting of ServiceAccount in wget-ambassador.yaml

- create_sa_role_rolebinding.sh
- kubectl-proxy.sh
- testkube_shell.sh
- wget-ambassador.yaml
- wget-api.sh

