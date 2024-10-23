FROM debian:bullseye-slim

LABEL image.author.name="Ammar Y. Mohamed"
LABEL image.author.email="amar.add655@gmail.com"

RUN apt-get update && apt-get install -y \
    wget \
    build-essential \
    zlib1g-dev \
    libncurses5-dev \
    libbz2-dev \
    liblzma-dev \
    libssl-dev \
    libreadline-dev \
    libsqlite3-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libssl-dev \
    r-base \
    && rm -rf /var/lib/apt/lists/*

# Install Miniconda
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p /opt/conda && \
    rm /tmp/miniconda.sh && \
    /opt/conda/bin/conda clean -a -y && \
    ln -s /opt/conda/bin/conda /usr/local/bin/conda

# Create the Conda environment
RUN conda create -n nf-pipeline -y \
    -c bioconda \
    -c conda-forge \
    kallisto \
    fastqc \
    multiqc \
    r-base \
    r-tidyverse

# Ensure Conda is initialized for non-interactive shells
RUN echo "source /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc

# Set the default command to activate the environment and keep the shell open
CMD ["/bin/bash", "-c", "source /opt/conda/etc/profile.d/conda.sh && conda activate nf-pipeline && exec /bin/bash"]

WORKDIR /workspace

COPY . /workspace
