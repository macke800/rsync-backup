FROM ubuntu:18.04

WORKDIR /app

EXPOSE 22

ENV NAME RsyncTestEnv

# Add SSH server and add testuser
RUN apt-get update && apt-get install -y openssh-server
RUN adduser --disabled-password --gecos -q testuser
RUN echo "testuser:abc123" | chpasswd

# Generate SSH keys for testuser
RUN su - testuser -c "ssh-keygen -t rsa -f /home/testuser/.ssh/id_rsa -q -P \"\""
RUN su - testuser -c "cat /home/testuser/.ssh/id_rsa.pub >> /home/testuser/.ssh/authorized_keys"

# Install rsync
RUN apt-get install -y rsync

# Install BATS
RUN apt-get install -y git
RUN cd ~ && git clone https://github.com/bats-core/bats-core.git
RUN cd ~/bats-core && ./install.sh /usr/local
RUN git clone https://github.com/ztombol/bats-support /opt/bats/test_helper/bats-support
RUN git clone https://github.com/ztombol/bats-assert /opt/bats/test_helper/bats-assert

RUN mkdir -p ./test/test-data/subfolder
RUN dd if=/dev/zero of=./test/test-data/5MB-file.bin bs=1M count=10
RUN dd if=/dev/zero of=./test/test-data/subfolder/2MB-file.bin bs=1M count=2

RUN chown -R testuser:testuser /app
COPY --chown=testuser:testuser ./docker/testuser-ssh-config /home/testuser/.ssh/config
COPY --chown=testuser:testuser . /app

#CMD service ssh start && /usr/sbin/sshd -p 2222 && /bin/bash
CMD service ssh start && /usr/sbin/sshd -p 2222 && su - testuser -c "/usr/local/bin/bats -r -t /app/test"
#CMD ["/usr/sbin/sshd", "-D"]
