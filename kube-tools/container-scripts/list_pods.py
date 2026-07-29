#!/opt/venv/bin/python3

#!/usr/bin/env python3

from kubernetes import client, config
import sys

def exception_exit(e):
    #logging.error(str(e)) 
    print()
    print()
    sys.stderr.write(str(e) + '\n') 
    exit(1)

def main():
    # Note: On config.load_kube_config() error, the ConfigException is not catchable
    # - see: https://github.com/kubernetes-client/python/issues/2219
    sys.stdout.write("\nAuthenticating to cluster ... ")
    sys.stdout.flush()
    try:
        config.load_kube_config()
    except Exception as e: 
        try:
            config.load_incluster_config()
        except Exception as e: 
            exception_exit(e)
    print("OK")

    sys.stdout.write("Opening connection to Core V1 API ... ")
    sys.stdout.flush()
    try:
        v1 = client.CoreV1Api()
    except Exception as e: 
        exception_exit(e)
    print("OK")

    sys.stdout.write("Retrieving list of pods from all namespaces ... ")
    sys.stdout.flush()
    try:
        ret = v1.list_pod_for_all_namespaces(watch=False)
    except Exception as e: 
        exception_exit(e)
    print("OK")

    print("\nListing pods with their IPs ... ")
    for i in ret.items:
        #print(f'{i.status.pod_ip:20} {i.metadata.namespace:20} {i.metadata.name:20}')
        object=f'{i.metadata.namespace}/{i.metadata.name}'
        print(f'{object:50} {i.status.pod_ip}')


if __name__ == '__main__':
    main()

