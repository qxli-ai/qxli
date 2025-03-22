# Use an official lightweight base image with minimal packages
FROM ubuntu:latest

# Set environment variables for non-interactive installs
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies for Homebrew and the basics
RUN apt-get update && \
    apt-get install -y build-essential curl file git && \
    rm -rf /var/lib/apt/lists/*

# Install Homebrew
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Update path
ENV PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"

# Install the software using Homebrew
RUN brew install i-am-bee/beeai/beeai

RUN brew services start beeai

# Set up beeai environment
RUN beeai env add LLM_MODEL=llama3.1:8b && \
    beeai env add LLM_API_BASE=http://ollama:11434/v1 && \
    beeai env add LLM_API_KEY=ollama

# Start the service
# Note: This is better handled in an entrypoint script or command
CMD ["beeai", "ui"]

# Optionally, expose any required ports
EXPOSE 8333

