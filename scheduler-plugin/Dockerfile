FROM golang:1.19 AS build

WORKDIR /go/src/kube-scheduler
COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o kube-scheduler .

FROM alpine:3.14

COPY --from=build /go/src/kube-scheduler/kube-scheduler /usr/bin/kube-scheduler

CMD ["/usr/bin/kube-scheduler"]
