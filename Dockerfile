# Use Ubuntu 24.04 as the base image
FROM ubuntu:24.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
# Set environment variable for the timezone
ENV TZ=Asia/Kolkata
# Create log directory
RUN mkdir -p /opt/log
RUN mkdir -p /home/truecopy

# Update the package list and install required packages
RUN apt-get update && \
    apt-get install -y wget gnupg2 lsb-release ca-certificates supervisor postgresql-client unzip openjdk-8-jre-headless vim net-tools cron tzdata && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    apt-get clean

USER root
RUN mkdir -p /opt/pfxwebsigner
RUN ln -s /opt/pfxwebsigner /home/truecopy/pfxsigner

# Copy the entry point script and set permissions
COPY initsupervisord.sh /usr/local/bin/initsupervisord.sh
RUN chmod +x /usr/local/bin/initsupervisord.sh
COPY initapps.sh /usr/local/bin/initapps.sh
RUN chmod +x /usr/local/bin/initapps.sh

# Copy application file
COPY pfxwebsigner-2.0.0.zip /

# Configure Supervisor to manage SSHD and PostgreSQL
RUN mkdir -p /opt/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose ports for SSH and Application
EXPOSE 8084 

# Start supervisor to manage services
CMD ["/bin/bash", "/usr/local/bin/initsupervisord.sh"]

