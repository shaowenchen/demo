## Usage

- create docker

```bash
docker run -it --rm shaowenchen/toolbox:latest bash
```

- create pod

```bash
kubectl run toolbox --image-pull-policy=Always --image=shaowenchen/toolbox:latest
```

- create deploy

```bash
kubectl create deploy toolbox --image=shaowenchen/toolbox:latest
```
