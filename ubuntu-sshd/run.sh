
student@proxmox-azure ~/labs/lab3c.1> #docker run -d -p 4444:22 -e SSH_USERNAME=mike -e SSH_ADMIN=yes -e PASSWORD=mypass -e AUTHORIZED_KEYS="$(cat ~/.ssh/id_rsa.pub )" mjbright/ubuntu-sshd:0.1

ssh -p 4444 mike@127.0.0.1 sudo ls -al /etc/

