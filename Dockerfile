FROM ubuntu:16.04
ARG coin=rise
ARG NODE_VERSION=6.12.2
ARG NODE_URL=https://nodejs.org/download/release/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.gz

ARG PARALLEL_MAKE_JOBS=4

ARG READLINE_DIR=readline-master
ARG READLINE_URL=http://git.savannah.gnu.org/cgit/readline.git/snapshot/$READLINE_DIR.tar.gz

ARG POSTGRES_DIR=postgresql-9.6.6
ARG POSTGRES_URL=https://ftp.postgresql.org/pub/source/v9.6.6/$POSTGRES_DIR.tar.gz

ARG REDIS_DIR=redis-3.2.11
ARG REDIS_URL=http://download.redis.io/releases/$REDIS_DIR.tar.gz

ARG JQ_DIR=jq-1.5
ARG JQ_URL=https://github.com/stedolan/jq/releases/download/$JQ_DIR/$JQ_DIR.tar.gz

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8


# Install prerequisites to build and set locales to en_US utf8.

RUN apt-get update && \
    apt-get install -y -qq autoconf automake build-essential sudo curl chrpath git libncurses5-dev libsodium-dev libssl-dev libtool locales python libssl-dev&& \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8


# Setup user
WORKDIR /home/$coin
RUN groupadd -r $coin && \
    useradd --no-log-init -r -g $coin $coin && \
    chown $coin:$coin -R . && \
    usermod -aG sudo $coin && \
    echo "$coin ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$coin

USER $coin
SHELL ["/bin/bash", "-c"]


### BUILD NODE DEPS ###

# Build libreadline7 Needed by postgres (and statically linking it so that linuxes with diff libreadline will use this)

RUN curl -o readline.tar.gz -J -L $READLINE_URL && \
    tar -zxf readline.tar.gz && \
    rm readline.tar.gz && \
    mv $READLINE_DIR readline
RUN cd readline && \
    ./configure  && \
    make -j $PARALLEL_MAKE_JOBS  SHLIB_LIBS=-lcurses &&  sudo make install

# Build PostGres
RUN curl -o postgres.tar.gz $POSTGRES_URL && \
    tar -zxf postgres.tar.gz && \
    rm postgres.tar.gz

RUN cd $POSTGRES_DIR && \
    ./configure --prefix=/home/$coin/postgres --with-libs=/usr/local/lib --with-includes=/usr/local/include && \
    make -j $PARALLEL_MAKE_JOBS && \
    make install && \
    cd contrib/pgcrypto && \
    make && make install

# Build Redis
RUN curl -o redis.tar.gz $REDIS_URL && \
    tar -zxf redis.tar.gz && \
    rm redis.tar.gz && \
    mv $REDIS_DIR redis

RUN cd redis && \
    make -j $PARALLEL_MAKE_JOBS

# Build jq binary -> https://github.com/stedolan/jq/
RUN curl -o jq.tar.gz -J -L $JQ_URL && \
    tar -zxf jq.tar.gz && \
    rm jq.tar.gz && \
    mv $JQ_DIR jq
RUN cd jq && \
    ./configure  && \
    make -j $PARALLEL_MAKE_JOBS

# Build nodjes
RUN curl -o node.tar.gz -J -L $NODE_URL && \
    tar -zxf node.tar.gz && \
    rm node.tar.gz && \
    mv node-v${NODE_VERSION}-linux-x64 node;

#RUN cd node_src && \
#    ./configure --prefix=/home/$coin/node && \
#    make -j $PARALLEL_MAKE_JOBS && \
#    make install && \
#    cd .. && rm -rf node_src

# INSTALL PM2
COPY ./build.sh /home/$coin/build.sh

ARG CORE_URI=./build-assets/src
ADD $CORE_URI ./core
RUN sudo chown $coin:$coin -R .

RUN mkdir -p out/bin out/lib out/data/pg out/data/redis out/etc out/logs out/pids

COPY ./build-assets/etc out/etc/
COPY ./build-assets/scripts out/scripts/

#
#ARG COREPATH=./core
#ADD $COREPATH ./core/

CMD ["bash", "-c", "./build.sh"]