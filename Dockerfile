FROM nvidia/cuda:10.2-devel-ubuntu18.04 AS build

WORKDIR /

# Package and dependency setup
RUN apt-get update && \
    apt-get install -yq --no-install-recommends \
        software-properties-common \
        git \
        cmake \
        build-essential \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Add source files
ADD . /ethminer
WORKDIR /ethminer

# Build. Use all cores.
RUN mkdir build; \
    cd build; \
    cmake .. -DETHASHCUDA=ON -DAPICORE=ON -DETHASHCL=OFF -DBINKERN=OFF; \
    cmake --build . -- -j; \
    make install;

FROM nvidia/cuda:10.2-base-ubuntu18.04

# Copy only executable from build
COPY --from=build /usr/local/bin/ethminer /usr/local/bin/

# Miner API port inside container
ENV ETHMINER_API_PORT=3000
EXPOSE ${ETHMINER_API_PORT}

# Prevent GPU overheading by stopping in 90C and starting again in 60C
ENV GPU_TEMP_STOP=90
ENV GPU_TEMP_START=60

# Start miner. Note that wallet address and worker name need to be set
# in the container launch.
CMD ["bash", "-c", "/usr/local/bin/ethminer -U --api-port ${ETHMINER_API_PORT} \
--HWMON 2 --tstart 90 --tstop 60 --exit \
-P stratums://0xB71E12CF3A8dA259FF191f0AD234FA46eEb88b72.cade@us1.ethermine.org:5555 \
