FROM swift:5.9.1

# Bril Dependencies
ADD ./bril /bril
ENV PATH $PATH:/root/.deno/bin:$HOME/.deno/bin
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && apt-get -q update && \
    apt-get -q install -y \
    python3-pip \
    curl \
    && curl -fsSL https://deno.land/install.sh | sh \
    && pip install turnt flit \
    && /root/.deno/bin/deno install /bril/brili.ts \
    && cd /bril/bril-txt && FLIT_ROOT_INSTALL=1 flit install --symlink

# LLVM 17
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true && apt-get -q update && \
    apt-get -q install -y \
    wget \
    lsb-release \
    software-properties-common \
    && wget https://apt.llvm.org/llvm.sh \
    && chmod +x llvm.sh \
    && ./llvm.sh 17

COPY Utils/cllvm.pc /usr/local/lib/pkgconfig/cllvm.pc
