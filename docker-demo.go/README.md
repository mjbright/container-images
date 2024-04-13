
# Docker Demo Application

Small docker image written in Go, based upon ehazlett/docker-demo, extended for use demonstrating Docker/Kubernetes.

Will serve up coloured docker png image to web-browser, or coloured ascii text image to wget/curl.

Ascii text images were created using http://www.text-image.com.

Used to create 4 images
    docker-demo:1 -> shows normal blue whale
    docker-demo:2 -> shows        red  whale
    k8s-demo:1    -> shows normal blue kubernetes logo
    k8s-demo:2    -> shows        red  kubernetes logo

... and more, up to :6 ...



## Environment Variables

- `TITLE`: sets title in demo app

## Build
Note: you must have Docker to build

```./build.sh```

## Run

```
docker run -p 8081:80 --rm docker-demo:1
curl localhost:8081
```
