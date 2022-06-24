<!-- omit in toc -->
# Sample Maven repository for IBM Automation Decision Services

This project provides material and documentation to install a Maven repository on RedHat OpenShift clusters for evaluation and sample scenarios of IBM Automation Decision Services.

The repository is providing a Maven artifact repository (Nexus)

The installation procedure is followed by post-installation steps to connect your Automation Decision Services instance to the Maven repository.

Your Maven repository must be reachable from the Automation Decision Services instance.  Typically, if you installed Automation Decision Services on a cloud cluster or an enterprise cluster, you probably won't be able to install the Maven repository
on your personal computer.  

##### Table of Contents
- [Limitations](#limitations)
- [Prerequisites](#prerequisites)
- [Installation on OpenShift/OKD](#installation-on-openshiftokd)
- [Post-installation steps](#post-installation-steps)
- [Usage](#usage)
- [License](#license)

## Limitations

* Security level is low:
  * Self signed certificate
  * Basic default user accounts with trivial users
  * Some container images run as root

* No automated backups of user data

## Prerequisites

* A Kubernetes cluster; see below for installation instructions on OpenShift 4.8.
* Docker command line
* Helm v3
* Python 3.6 or above

## Installation on OpenShift/OKD

Prerequisites:
- OpenShift cluster 4.8
- `oc` OpenShift command line
- Docker command line
- Helm v3

The following procedure creates a new project in OpenShift and installs the three components of the service.
Helm is used to generate the Kubernetes resource files from the Helm templates but the Tiller server is not required.

Procedure:

1. Install the Maven repository (it may take a few minutes to complete).

    1. Connect to the OpenShift server.
        ```
        oc login $SERVER -u $USER -p $PASSWORD
        ```
    
    1. Create a new project.
    
        Choose the project (`PROJECT`) where to deploy the sample Maven repository and add the security context constraint `anyuid` to this namespace. 
        
        ```
        oc new-project "$PROJECT" --description="Sample Maven repository - Nexus" --display-name="DevOps Maven Repository"
        oc --as=system:admin adm policy add-scc-to-user anyuid system:serviceaccount:$PROJECT:default
        ```
    
    1. Build and push Nexus images to the OpenShift registry.
    
        Build the Nexus image locally and then push them to the OpenShift registry with the public image registry name (`PUBLIC_IMAGE_REGISTRY`).
        
        ```
        docker build -t "$PUBLIC_IMAGE_REGISTRY/$PROJECT/nexus:0.2.1" ./images/nexus
        docker login -u $(oc whoami) -p $(oc whoami -t) $PUBLIC_IMAGE_REGISTRY
        docker push "$PUBLIC_IMAGE_REGISTRY/$PROJECT/nexus:0.2.1"
        ```
    
    1. Customize the Helm values files.
        
        Customize the `configs/openshift-values.yaml` file with the required values.
        The host Nexus (`NEXUS_HOST`) need to be set.
        The image names need to be set with a registry name that is visible inside the OpenShift cluster (`IMAGES_REGISTRY`).
        You can use the script `scripts/customize_openshift_values.sh` to perform this action.
        
        ```
        ./scripts/customize_openshift_values.sh $IMAGES_REGISTRY $PROJECT $NEXUS_HOST > /tmp/customized_openshift_values.yaml
        ```
    
    1. Deploy the sample Maven repository.
        
        Generate a certificate for the Nexus Route. `NAMESPACE_SUFFIX` is the suffix shared for the current namespace. 
        Example: suffix for namespace "nexusrepo" will be nexusrepo.mycluster.com
    
        ```
        openssl req -x509 -new -nodes -newkey rsa:4096 -keyout ca.key -out ca.crt -days 30 -subj "/CN=*.$NAMESPACE_SUFFIX"
        ```
    
        Create a secret containing the certificate information
    
        ```
        kubectl create secret tls cicd-tls \
            --key ca.key \
            --cert ca.crt
        ```
    
        Use Helm to generate the Kubernetes resource files from the Helm templates and to deploy the sample Maven repository.
        
        ```
        helm template helm-charts --name-template maven-repository --namespace $PROJECT --values /tmp/customized_openshift_values.yaml  > /tmp/openshift-rendered.yaml
        oc create -f /tmp/openshift-rendered.yaml
        ```
        
    Wait for all components to be available.

    * Nexus is now available with user `nexusdemo` and password `nexusdemo`.

1. You can now continue with the post-installation steps to connect your Automation Decision Services instance to this Maven repository.

<!-- omit in toc -->
#### Uninstallation

You can either delete the whole project:

   ```
   oc delete project ci-cd
   ```
   
or delete the elements that are deployed in the project but keep the project:

   ```
   oc delete -n ci-cd -f tmp/openshift-rendered.yaml
   ```
   
The `tmp/openshift-rendered.yaml` file is created at installation time.

## Post-installation steps

Post-installation steps to configure the Maven repository for use with Automation Decision Services.

1. Run the script `install-maven-plugin.sh` to download the Automation Decision Services Maven plug-in and
other artifacts from your Automation Decision Services installation and to upload them to your Nexus server.

    You must use a Zen Api Key from a Zen user to be able to run the script. 
        
    ```
    ./scripts/install-maven-plugin.sh <ADS_DESIGNER_URL> <NEXUS_URL> $(printf "<ZEN_USERNAME>:<ZEN_APIKEY>" | base64)
    ```

1. Check that artifacts have been uploaded into nexus:

  1. Sign in to <NEXUS_URL> with user `nexusdemo` and password `nexusdemo` and finalize configuration wizard if needed by having anonymous access enabled. Then Sign out.
  
  2. Anonymously search for maven `com.ibm.decision` groupId to verify you are able to access them.

2. Configure the Decision Designer instance to use the Nexus server of the Maven repository

   - Create or update the ConfigMap containing trusted certificates of the product by adding Nexus certificate. See sample "ads-other-certs" below. In this example, the ConfigMap name is `ads-other-certs` and is configured inside Custom Resource using parameter `decision_designer.other_trusted_certs`

    ```
    metadata:
      name: ads-other-certs
    data:
        nexus.crt: |
        -----BEGIN CERTIFICATE-----
        MIIFYjCCA0qgAwIBAgIUNRLW3YJfw
        *****************************
        *****************************
        etc
        -----BEGIN CERTIFICATE----- 
    ```  
   
    - Ensure that pods mounting this certificates are restarted. The operator is handling such change and pods are expected to restart automatically.

## Usage

You can now go to the section _Building and deploying decision services_  of the Automation Decision Services documentation (installguide.pdf)
for instructions.

## License

Copyright 2020, 2021 IBM Corporation
```
   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
```
