FROM ubuntu:18.04

WORKDIR /app

ADD ./src /app

EXPOSE 22

ENV NAME RsyncTestEnv

RUN apt-get update && apt-get install -y openssh-server
RUN service ssh start
RUN service ssh stop
RUN adduser --disabled-password --gecos -q testuser
RUN echo "testuser:abc123" | chpasswd
CMD ["/usr/sbin/sshd", "-D"]
