# The version number tag for the base container
FROM openjdk:17-slim-buster

# Default the server port if not specified
ARG SERVER_PORT
ENV SERVER_PORT=${SERVER_PORT:-8080}
EXPOSE ${SERVER_PORT}

ARG install_dir=/opt/app
ARG username=github

# Install curl
RUN apt update && apt install -y curl

# Create a user and directory to install and run the application
RUN useradd -m -d ${install_dir} -u 1000 ${username}
USER ${username}
WORKDIR ${install_dir}

# Copy the self contained jar file to the container
COPY target/spring-petclinic-3.0.0-SNAPSHOT.jar spring-petclinic.jar

ENTRYPOINT ["/usr/local/openjdk-17/bin/java", "-jar", "spring-petclinic.jar"]