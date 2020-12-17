# Sample CI/CD stack for IBM Automation Decision Services

This project provides material and documentation to install a complete CI/CD stack on Minikube or other Kubernetes
clusters for evaluation and sample scenarios of IBM Automation Decision Services.

The stack is composed of:
   - A Git server (Gitea)
   - A Maven artifact repository (Nexus)
   - A continuous integration server (Jenkins)

The installation procedure is followed by post-installation steps to connect your Automation Decision Services instance to this CI/CD stack.

Your CI/CD stack must be reachable from the Automation Decision Services instance.  Typically, if you installed  Automation Decision Services on a cloud cluster or an enterprise cluster, you probably won't be able to install the CI/CD stack
on your personal computer.  If you installed Automation Decision Services on Minikube or Minishift on your personal
computer, you can install the CI/CD stack in the same Minikube or Minishift instance.

##### Table of Contents
* [Limitations](#limitations)
* [Prerequisites](#pre-requisites)
* [Installation](#installation)
  * [on Minikube](#installation-on-minikube)
  * [on Minishift](#installation-on-minishift)
  * [on OpenShift/OKD](#installation-on-openshiftokd)
* [Post-installation steps](#post-installation-procedure-configuration-with-ibm-dba-ads)
* [Usage](#usage)
* [License](#license)

## Limitations

* Security level is low:
  * No TLS
  * Basic default user accounts with trivial users
  * Some container images run as root

* No automated backups of user data

## Prerequisites

* A Kubernetes cluster; see below for installation instructions on Minikube, Minishift, or OpenShift 3.11.
* Docker command line
* Helm 2.14.3 or above
* Python 3.6 or above

## Installation

### Installation on Minikube

Prerequisites:
* Minikube 1.1.1 or above, with addons `ingress` and `storage-provisioner` enabled (see `minikube addons list`).                  If you use version 1.4 or above, use the start option `--kubernetes-version=1.15.0`.
* Docker command line
* Helm 2.14.3 or above

Procedure:

1. Start Minikube and enable the required addons.

     ```
     minikube start --memory=4g --cpus=4

     # or add any other relevant minikube option for your platform, for instance
     # on MacOs with minikube 1.4:
     # minikube start --memory=4g --cpus=4 --vm-driver=hyperkit --kubernetes-version=1.15.0
     
     minikube addons enable ingress
     minikube addons enable storage-provisioner
     ```

1. Install the CI/CD stack (it may take a few minutes to complete).

     ```
     ./scripts/minikube_install.sh
     ```

1. Confirm that all pods have a `Running` status and are `Ready`.

    ```
    $ kubectl get pods
    NAME                                          READY   STATUS    RESTARTS   AGE
    ci-cd-demo-devops-gitea-d756ff49c-m944s       3/3     Running   0          101s
    ci-cd-demo-devops-nexus-89cf4bfd6-4wfr6       2/2     Running   0          101s
    ci-cd-demo-jenkins-6dd459bdfd-jcgcw           1/1     Running   0          101s
    ```
    (Ready !)

    * Gitea server is now available at `http://git.<minikube_ip>.nip.io` with user `demo` and password `demo`  (*adapt to the IP address of your Minikube as reported by `minikube ip`* )
    * Nexus is now available at `http://nexus.<minikube_ip>.nip.io` with user `nexusdemo` and password `nexusdemo`
    * Jenkins is now available at `http://jenkins.<minikube_ip>.nip.io` with user `admin` and password `admin`

      In Jenkins, the new Maven jobs have a `settings.xml` preconfiguration that points to the Nexus repositories.

1. You can now continue with the post-installation steps to connect your Automation Decision Services instance to this CI/CD stack.

#### Uninstallation

1. Uninstall the Helm release.

    ```
    helm delete ci-cd-demo --purge
    ```

1. Delete the persistent volume claims that are left by Helm  (their names are given by the previous `helm delete` output).

    ```
    kubectl delete pvc ci-cd-demo-devops-gitea ci-cd-demo-postgres
    ```

### Installation on Minishift

Prerequisites:
- Minishift 1.34 or above
- `oc` OpenShift command line (delivered with Minishift)
- Docker command line
- Helm 2.14.3 or above

The following procedure creates a new project in OpenShift (default name is `ci-cd`) and installs
the three components of the CI/CD stack.  Helm is used to generated the
Kubernetes resource files from the Helm templates, but the Tiller server is not required.

Procedure:

1. Start Minishift.

     ```
     minishift start --memory=4g --cpus=4

     # or add any other relevant minishift option for your platform, for instance
     # on MacOs:
     minishift start --memory=4g --cpus=4 --vm-driver=kyperkit
     ```

1. Install the CI/CD stack (it may take a few minutes to complete).

     ```
     ./scripts/minishift_install.sh -n local-ci-cd   # default  is `ci-cd`
     ```

   The script waits for all components to be available.

    * Gitea server is now available at `http://git.<minishift_ip>.nip.io` with user `demo` and password `demo`  (*adapt to the IP address of your Minishift as reported by `minishift ip`* )
    * Nexus is now available at `http://nexus.<minishift_ip>.nip.io` with user `nexusdemo` and password `nexusdemo`
    * Jenkins is now available at `http://jenkins.<minishift_ip>.nip.io` with user `admin` and password `admin`

      In Jenkins, the new Maven jobs have a `settings.xml` preconfiguration that points to the Nexus repositories.

1. You can now continue with the post-installation steps to connect your Automation Decision Services instance to this CI/CD stack.

#### Uninstallation

You can either delete the whole project:

   ```
   oc delete project local-ci-cd
   ```
   
or delete the elements that are deployed in the project but keep the project:

   ```
   oc delete -n local-ci-cd -f tmp/minishift-rendered.yaml
   ```
   
The `tmp/minishift-rendered.yaml` file is created at installation time.
    
### Installation on OpenShift/OKD

Prerequisites:
- OpenShift cluster 3.11 or 4.2
- `oc` OpenShift command line
- Docker command line
- Helm 2.14.3 or above

The following procedure creates a new project in OpenShift and installs the three components of the CI/CD stack.
Helm is used to generate the Kubernetes resource files from the Helm templates but the Tiller server is not required.

Procedure:

1. Install the CI/CD stack (it may take a few minutes to complete).

    1. Connect to the OpenShift server.
        ```
        oc login $SERVER -u $USER -p $PASSWORD
        ```
    
    1. Create a new project.
    
        Choose the project (`PROJECT`) where to deploy the sample CI/CD stack and add the security context constraint `anyuid` to this namespace. 
        
        ```
        oc new-project "$PROJECT" --description="Sample CICD stack tools - Gitea, Nexus and Jenkins" --display-name="DevOps Stack"
        oc --as=system:admin adm policy add-scc-to-user anyuid system:serviceaccount:$PROJECT:default
        ```
    
    1. Build and push Gitea and Nexus images to the OpenShift registry.
    
        Build the Gitea and Nexus images locally and then push them to the OpenShift registry with the public image registry name (`PUBLIC_IMAGE_REGISTRY`).
        
        ```
        docker build -t "$PUBLIC_IMAGE_REGISTRY/$PROJECT/gitea:0.1.0" ./images/gitea
        docker build -t "$PUBLIC_IMAGE_REGISTRY/$PROJECT/nexus:0.2.1" ./images/nexus
        docker login -u $(oc whoami) -p $(oc whoami -t) $PUBLIC_IMAGE_REGISTRY
        docker push "$PUBLIC_IMAGE_REGISTRY/$PROJECT/gitea:0.1.0"
        docker push "$PUBLIC_IMAGE_REGISTRY/$PROJECT/nexus:0.2.1"
        ```
    
    1. Customize the Helm values files.
        
        Customize the `configs/openshift-values.yaml` file with the required values.
        The host for Gitea (`GIT_HOST`), Nexus (`NEXUS_HOST`), and Jenkins (`JENKINS_HOST`) need to be set.
        The image names need to be set with a registry name that is visible inside the OpenShift cluster (`IMAGES_REGISTRY`).
        You can use the script `scripts/customize_openshift_values.sh` to perform this action.
        
        ```
        ./scripts/customize_openshift_values.sh $IMAGES_REGISTRY $PROJECT $GIT_HOST $NEXUS_HOST $JENKINS_HOST > /tmp/customized_openshift_values.yaml
        ```
    
    1. Deploy the sample CI/CD stack.
    
        Use Helm to generate the Kubernetes resource files from the Helm templates and to deploy the sample CI/CD stack.
        
        ```
        helm template helm-charts --name devops-stack --namespace $PROJECT --values /tmp/customized_openshift_values.yaml  > /tmp/openshift-rendered.yaml
        oc create -f /tmp/openshift-rendered.yaml
        ```
        
    Wait for all components to be available.
    
    * Gitea server is now available with user `demo` and password `demo`
    * Nexus is now available with user `nexusdemo` and password `nexusdemo`.
    * Jenkins is now available with user `admin` and password `admin`

    In Jenkins, the new Maven jobs have a `settings.xml` preconfiguration that points to the Nexus repositories.

1. You can now continue with the post-installation steps to connect your Automation Decision Services instance to this CI/CD stack.

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

## Post-installation steps to configure the CI/CD stack for use with Automation Decision Services

1. Run the script `install-ads-maven-plugin.sh` to download the Automation Decision Services Maven plug-in and
other artifacts from your Automation Decision Services installation and to upload them to your Nexus server.

    You must be authenticated using UMS to access to these resources.
    
    You will need to get an access token using the OIDC `client_credentials` authentication flow with UMS. The steps are the same as the `password` flow described in the [UMS Password crendential flow](https://www.ibm.com/support/knowledgecenter/SSYHZ8_19.0.x/com.ibm.dba.offerings/topics/con_ums_sso_cmdline.html) by replacing the grant type by `client_credentials` and by removing the parameters `username` and `password` from the access token request.
    
    ```
    ./scripts/install-maven-plugin.sh <ADS_DESIGNER_URL> <NEXUS_URL> <ACCESS_TOKEN>
    ```

    For example, if you installed Automation Decision Services and the CI/CD stack locally on Minishift and the IP address is `192.168.64.10` and you obtained the access token `sCBa88JWCXu9tK6Zcjn4sOt3Ow5NYgNai3AF5wiO`, run the script:

    ```
    ./scripts/install-maven-plugin.sh 'https://ads.192.168.64.10.nip.io/' 'http://nexus.192.168.64.10.nip.io/' 'sCBa88JWCXu9tK6Zcjn4sOt3Ow5NYgNai3AF5wiO'
    ```
1. Check that artifacts have been uploaded into nexus:

  1. Sign in to <NEXUS_URL> with user `nexusdemo` and password `nexusdemo` and finalize configuration wizard if needed by having anonymous access enabled. Then Sign out.
  
  1. Anonymously search for maven `com.ibm.decision` groupId to verify you are able to access them.

1. Configure the Decision Designer instance to register the Gitea server of the CI/CD stack:
   - Edit the `gitCredentials` attribute of the secret admin secret referenced in the Decision Designer configuration property `decisionDesigner.adminSecretName` and add an entry for the Gitea server.

    For example, if you installed the CI/CD stack on Minishift, and the command `minishift ip` returns `192.168.64.10`,
    the entry to add in the `gitCredentials` JSON value is :
    ```
     "git.192.168.64.10.nip.io": {
       "user": "demo",
       "password": "demo"
     }
    ```

    Because this CI/CD stack does not use TLS, you don't need to register any new TLS certificate in
    the list of trusted certificates of Automation Decision Services.

    - After you edited the admin secret, you need to restart all the `gitservice` pods of the ADS instance :

    ```bash
    kubectl patch "$(kubectl get deploy -l "app.kubernetes.io/component=gitservice,app.kubernetes.io/name=ibm-automation-decision-services" -o name)" -p "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"force_restart_date\":\"`date +'%s'`\"}}}}}"
    ```

1. Configure the decision runtime to fetch the decision service archives from the Nexus repository:

   - Edit the `values.yaml` file of your Automation Decision Services installation to inject the URL of your Nexus repository into key `decisionRuntimeService.archiveRepository.urlPrefix`: 

     ```yaml
     decisionRuntime:
         archiveRepository:
             urlPrefix: http://nexus.192.168.64.10.nip.io/maven-snapshots
     ```

   - Edit the secret of the decision runtime referenced in the runtime configuration (key `decisionRuntime.adminSecretName` in the `values.yaml` file) and set the `archiveRepositoryUser` and `archiveRepositoryPassword` with credentials of the Nexus server: `nexusdemo` and `nexusdemo`.

   - Force a restart all the `runtime` pods of the ADS instance :

    ```bash
    kubectl patch "$(kubectl get deploy -l "app.kubernetes.io/component=decisionRuntimeService,app.kubernetes.io/name=ibm-automation-decision-services" -o name)" -p "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"force_restart_date\":\"`date +'%s'`\"}}}}}"
    ```

## Usage

You can now go to the section _Building and deploying decision services_  of the Automation Decision Services documentation (installguide.pdf)
for instructions on how to create a build plan in Jenkins to build a decision service project published in
your Git server.

## License

Copyright 2020 IBM Corporation
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
