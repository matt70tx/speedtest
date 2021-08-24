FROM arm32v7/debian:buster

# Install dependencies
RUN apt-get update && \
    apt-get -y install gnupg1 apt-transport-https dirmngr curl jq

# Install speedtest cli
RUN curl -s https://install.speedtest.net/app/cli/install.deb.sh | bash && \
    apt-get update && \
    apt-get -y install speedtest

COPY ./speedtest.sh .
CMD ["./speedtest.sh"]
