# pi-hole
pi-hole Docker image with additional block lists based on ubuntu:latest



```
docker run -d --name pi-hole -p 80:80 -p 53:53/udp dansailer/pi-hole
```

```
docker exec -it pi-hole /bin/bash
```
