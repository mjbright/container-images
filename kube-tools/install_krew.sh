#!/usr/bin/env bash

exec > /app/krew_install.log 2>&1

(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)

echo 'PATH="$HOME/.krew/bin:$PATH"' >> ~/.bashrc
export PATH="$HOME/.krew/bin:$PATH"
ls -altr ~/.bashrc
source ~/.bashrc

set -x
kubectl krew install example explore lineage tree

#/root/.krew/bin/kubectl-krew install example explore lineage tree

#/root/.krew/store/krew/v0.5.0/krew install tree lineage

#ls -al /root/.krew/bin/kubectl-krew

echo PATH=$PATH
which git
ls -al /root/.krew/bin/

exit 0
set +x

