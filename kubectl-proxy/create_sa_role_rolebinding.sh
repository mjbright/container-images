kubectl create serviceaccount default-api
kubectl create role get-deploy --resource deployments --verb get,list,watch
kubectl create rolebinding get-deploy --serviceaccount default:default-api --role get-deploy
