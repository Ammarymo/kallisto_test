# Base image
FROM debian:bullseye-slim

LABEL image.author.name="Ammar Y. Mohamed" \
      image.author.email="amar.add655@gmail.com"

# Install all dependencies and clean up in a single RUN to reduce layers
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    wget \
    r-base-core \              
    r-cran-tidyverse \
    default-jdk-headless \     
    python3-pip && \
    # Install build dependencies for specific tools
    apt-get install -y --no-install-recommends \
    build-essential \
    zlib1g-dev \
    libncurses5-dev \
    libbz2-dev \
    liblzma-dev \
    libssl-dev \
    libreadline-dev \
    libsqlite3-dev \
    libcurl4-openssl-dev \
    libxml2-dev && \
    # Install Kallisto
    wget https://github.com/pachterlab/kallisto/releases/download/v0.46.2/kallisto_linux-v0.46.2.tar.gz -O /tmp/kallisto.tar.gz && \
    tar -xvzf /tmp/kallisto.tar.gz -C /usr/local/bin --strip-components=1 kallisto/kallisto && \
    rm /tmp/kallisto.tar.gz && \
    # Install FastQC
    wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.12.1.zip -O /tmp/fastqc.zip && \
    unzip /tmp/fastqc.zip -d /opt && \
    chmod +x /opt/FastQC/fastqc && \
    ln -s /opt/FastQC/fastqc /usr/local/bin/fastqc && \
    rm /tmp/fastqc.zip && \
    # Install MultiQC
    pip3 install --no-cache-dir multiqc && \
    # Remove build dependencies and cleanup
    apt-get remove --purge -y \
    build-essential \
    zlib1g-dev \
    libncurses5-dev \
    libbz2-dev \
    liblzma-dev \
    libssl-dev \
    libreadline-dev \
    libsqlite3-dev \
    libcurl4-openssl-dev \
    libxml2-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /opt/FastQC/Help # Remove help files in FastQC to save space

# Set the working directory
WORKDIR /kallisto_pipeline

# Copy current directory contents to the working directory
COPY . /kallisto_pipeline

# Set default command
CMD ["/bin/bash"]
