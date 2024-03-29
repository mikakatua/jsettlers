# JSettlers
This repository contains a dockerized version of the JSettlers Server.

JSettlers is a Java version of the board game Settlers of Catan. The project is hosted at https://github.com/jdmonin/JSettlers2/

## How to play?
Follow the instructions to deploy the JSettlers Server and launch the client. For example:

`java -jar jsettlers-2.4.00/JSettlers-2.4.00.jar`

Alternatively, you can download and run the [JSettlers JAR file](https://nand.net/jsettlers/JSettlers.jar).

You can also play the game online at https://nand.net/jsettlers/

## Local deployment
This setup uses Docker compose.

Requirements:
- [Java JRE](https://www.oracle.com/java/technologies/javase-jre8-downloads.html) version 1.8 or higher
- [Docker engine](https://docs.docker.com/engine/install/) 
- [Docker compose](https://docs.docker.com/compose/install/)

Instructions:
1. Rename or copy `sample.env` to `.env`
1. Edit and set config variables in `.env`
1. Run the deployment script `./setup.sh`

## Kubernetes deployment
Use the manifest provided in the [k8s](k8s) directory.

## Cloud deployment
This setup uses the Kubernetes service in Azure (AKS).

Requirements:
- [Java JRE](https://www.oracle.com/java/technologies/javase-jre8-downloads.html) version 1.8 or higher
- An [Azure subscription](https://azure.microsoft.com/en-us/free/)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Tool for building images as [Docker](https://docs.docker.com/engine/install/)  or [Podman](https://podman.io/getting-started/installation)

Instructions:
1. Edit `azure.env` if you want to use existing Azure resources
1. Rename or copy `sample.env` to `.env`
1. Edit and set config variables in `.env`
1. Run the deployment script `./setup.sh aks`
