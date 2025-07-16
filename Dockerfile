FROM ubuntu:22.04

# Set non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Install just bash (optional: nano if you like)
RUN apt-get update && apt-get install -y bash nano && rm -rf /var/lib/apt/lists/*

# Set working dir
WORKDIR /root

# Drop into bash by default
CMD ["/bin/bash"]
