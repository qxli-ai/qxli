# Use an official lightweight base image with minimal packages
FROM homebrew/brew:latest

# Set environment variables for non-interactive installs
ENV DEBIAN_FRONTEND=noninteractive

# Install the software using Homebrew
RUN brew install i-am-bee/beeai/beeai

# Start the service
# Note: This is better handled in an entrypoint script or command
CMD ["beeai", "serve"]

# Set up beeai environment
RUN beeai env add LLM_MODEL=llama3.1:8b && \
    beeai env add LLM_API_BASE=http://ollama:11434/v1 && \
    beeai env add LLM_API_KEY=ollama

RUN beeai ui

# Optionally, expose any required ports
EXPOSE 8333

