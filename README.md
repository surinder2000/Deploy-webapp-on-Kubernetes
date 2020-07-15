# Deploy Web app on top of Kubernetes
Deploying web app on top of Kubernetes by integrating it with Git, Github, Docker, and Jenkins.

## Pre-requisites
* Must have minikube installed
* Must have kubectl configured

## Let's see step by step process
### 1. Create Dockerfile for creating jenkins docker image
* This is the Dockerfile code for creating jenkins docker image

![Dockerfile code](https://github.com/surinder2000/Deploy-webapp-on-Kubernetes/blob/master/Dockerfilecode.png)

* Run the following command in the same directory to create jenkins docker image

      docker build -t image_name:tag .
      
### 2. Launch the jenkins container using the following command

    docker container run -it --name jenkin -v jen:/var/lib/jenkins -p 8888:8080 image_name:tag
    
   Here **jen** is the volume, attached to the working folder of the jenkins container for keeping  the data persistant. To create the volume for docker container use the following command 
  
    docker volume create volume_name (in my case volume_name is jen)
    
   After this, setup jenkins, install required plugins like Git, Email notification and Build pipeline.
### 3. Create a post-commit hook in the git repository for pushing the code automatically after commit
* Go to ./git/hooks from git repository and create one file named post-commit and add the following lines in it

      #!/bin/bash
      git push

### 4. Create one file for html web server deployment with PVC 
To create html web server deployment put the following code in yaml file

      apiVersion: v1
      kind: Service
      metadata:
          name: html-webserver
          labels:
              server: apache-httpd
      spec:
          ports:
           -  port: 80
          selector:
              server: apache-httpd
          type: NodePort
      ---

      apiVersion: v1 
      kind: PersistentVolumeClaim
      metadata:
          name: html-pvc 
          labels:
              server: apache-httpd 
      spec:
          accessModes:
           -  ReadWriteOnce
          resources:
              requests:
                  storage: 10Gi

      ---

      apiVersion: apps/v1 
      kind: Deployment
      metadata:
          name: html-webserver 
          labels:
              server: apache-httpd 
      spec:
          selector:
              matchLabels:
                  server: apache-httpd 
          strategy:
              type: Recreate
          template:
              metadata:
                  labels:
                      server: apache-httpd 
              spec:
                  containers:
                   -  name: html 
                      image: httpd 
                      ports:
                       -  containerPort: 80
                          name: html 
                      volumeMounts:
                       -  name: html-persistent-storage 
                          mountPath: /usr/local/apache2/htdocs/
                  volumes:
                   -  name: html-persistent-storage 
                      persistentVolumeClaim:
                          claimName: html-pvc  
    
      
### 5. Create one file for php web server deployment with PVC
To create php web server deployment put the following code in yaml file

      apiVersion: v1
      kind: Service
      metadata:
          name: php-webserver
          labels:
              server: apache-httpd-php 
      spec:
          ports:
           -  port: 80
          selector:
              server: apache-httpd-php 
          type: NodePort
      ---

      apiVersion: v1 
      kind: PersistentVolumeClaim
      metadata:
          name: php-pvc 
          labels:
              server: apache-httpd-php 
      spec:
          accessModes:
           -  ReadWriteOnce
          resources:
              requests:
                  storage: 10Gi

      ---

      apiVersion: apps/v1 
      kind: Deployment
      metadata:
          name: php-webserver 
          labels:
              server: apache-httpd-php 
      spec:
          selector:
              matchLabels:
                  server: apache-httpd-php 
          strategy:
              type: Recreate
          template:
              metadata:
                  labels:
                      server: apache-httpd-php 
              spec:
                  containers:
                   -  name: php 
                      image: vimal13/apache-webserver-php 
                      ports:
                       -  containerPort: 80
                          name: php
                      volumeMounts:
                       -  name: php-persistent-storage 
                          mountPath: /var/www/html/
                  volumes:
                   -  name: php-persistent-storage 
                      persistentVolumeClaim:
                          claimName: php-pvc  
    

### 6. Let's create the jobs in the jenkins for automation of deployment
#### Job 1: Pull the code from github repository as soon as developer commit 
* In Source Control Management section put the Github repository url and branch name

![Git configuration](https://github.com/surinder2000/Deploy-webapp-on-Kubernetes/blob/master/job11.png)

* In Build trigger section select Poll SCM for checking the github repository every minute

![Build trigger](https://github.com/surinder2000/Deploy-webapp-on-Kubernetes/blob/master/job12.png)

* In the Build section from Add build step select Execute shell and put the following code in the command box

      sudo cp -r * /root/Webdata
      sudo scp -r /root/Webdata/* surinder@192.168.29.101:/home/surinder/Webdata/

![Execute shell](https://github.com/surinder2000/Deploy-webapp-on-Kubernetes/blob/master/job13.png)

* Click on Apply and Save

#### Job 2: By looking at the code file name launch the deployment of respective webserver  
* In Build trigger section select Build after other projects are built and put the name of Job 1 in the Project to watch box and check Trigger only if build is stable

![Build trigger](https://github.com/surinder2000/Deploy-webapp-on-Kubernetes/blob/master/job21.png)

* In the Build section from Add build step select Execute shell and put the following code in the command box

      data=$(sudo ls /root/Webdata)
      if sudo ls /root/Webdata/ | grep html
      then
      if sudo ssh surinder@192.168.29.101 kubectl get deploy/html-webserver
      then
      echo "Already running"
      POD=$(sudo ssh surinder@192.168.29.101 kubectl get pod -l server=apache-httpd -o jsonpath="{.items[0].metadata.name}")
      for file in $data
      do
      sudo ssh surinder@192.168.29.101 kubectl cp /home/surinder/Webdata/$file $POD:/usr/local/apache2/htdocs/
      done
      else
      sudo ssh surinder@192.168.29.101 kubectl create -f /home/surinder/Webdata/htmlweb.yml
      POD=$(sudo ssh surinder@192.168.29.101 kubectl get pod -l server=apache-httpd -o jsonpath="{.items[0].metadata.name}")
      sleep 30
      for file in $data
      do
      sudo ssh surinder@192.168.29.101 kubectl cp /home/surinder/Webdata/$file $POD:/usr/local/apache2/htdocs/
      done
      fi
      elif sudo ls /root/Webdata/ | grep php
      then
      if sudo ssh surinder@192.168.29.101 kubectl get deploy/php-webserver
      then
      echo "Already running"
      POD=$(sudo ssh surinder@192.168.29.101 kubectl get pod -l server=apache-httpd-php -o jsonpath="{.items[0].metadata.name}")
      for file in $data
      do
      sudo ssh surinder@192.168.29.101 kubectl cp /home/surinder/Webdata/$file $POD:/var/www/html/
      done
      else
      sudo ssh surinder@192.168.29.101 kubectl create -f /home/surinder/Webdata/phpweb.yml
      POD=$(sudo ssh surinder@192.168.29.101 kubectl get pod -l server=apache-httpd -o jsonpath="{.items[0].metadata.name}")
      sleep 30
      for file in $data
      do
      sudo ssh surinder@192.168.29.101 kubectl cp /home/surinder/Webdata/$file $POD:/var/www/html/
      done
      fi
      else
      echo "No server found"
      exit 1
      fi
      

![Execute shell](https://github.com/surinder2000/Deploy-webapp-on-Kubernetes/blob/master/job22.png)

* Click on Apply and Save

#### Job 3: Check whether the site is working or not
* In Build trigger section select Build after other projects are built and put the name fo Job 2 in the Project to watch box and check Trigger only if build is stable

![Build trigger](https://github.com/surinder2000/Deploy-webapp-on-Kubernetes/blob/master/job31.png)

* In the Build section from Add build step select Execute shell and put the following code in the command box

      if sudo ls /root/Webdata | grep html
      then
      url=$(sudo ssh surinder@192.168.29.101 minikube service html-webserver --url)
      status=$(sudo ssh surinder@192.168.29.101 curl -o /dev/null -s -w "%{http_code}" $url)
      elif sudo ls /root/Webdata | grep php
      then
      url=$(sudo ssh surinder@192.168.29.101 minikube service php-webserver --url)
      status=$(sudo ssh surinder@192.168.29.101 curl -o /dev/null -s -w "%{http_code}" $url)
      fi
      if [[ status -ne 200 ]]
      then 
      if sudo ls /root/Webdata/ | grep html
      then
      sudo ssh surinder@192.168.43.101 kubectl delete -f /home/surinder/Webdata/htmlweb.yml
      exit 1
      elif sudo ls /root/Webdata/ | grep php
      then
      sudo ssh surinder@192.168.43.101 kubectl delete -f /home/surinder/Webdata/phpweb.yml
      exit 1
      fi
      else
      exit 0
      fi

![Execute shell](https://github.com/surinder2000/Deploy-webapp-on-Kubernetes/blob/master/job32.png)

* In the Post-build Actions section select Editable Email notification and put the email address of developer, subject and message content (Note: We need to configure SMTP server for sending mail. For this go to Manage jenkins -> Configure -> Extended Email notification and put the details there) 

This Post-build action trigger only if this job fails, if there is an issue in the site and not working properly and on failure it will send email to developer

![Post-build Action](https://github.com/surinder2000/Deploy-webapp-on-Kubernetes/blob/master/job33.png)

* Click on Apply and Save

#### Job 4: Send email notification to developer if site is working fine
* In Build trigger section select Build after other projects are built and put the name of Job 3 in the Project to watch box and check Trigger only if the build is stable

![Build trigger](https://github.com/surinder2000/Deploy-webapp-on-Kubernetes/blob/master/job41.png)

* In the Post-build Actions section select Editable Email notification and put the email address of developer, subject and message content (Note: We need to configure SMTP server for sending mail. For this go to Manage jenkins -> Configure -> Extended Email notification and put the details there) 

![Post-build Action](https://github.com/surinder2000/Deploy-webapp-on-Kubernetes/blob/master/job42.png)

* Click on Apply and Save

That's all our setup is ready

Now as soon as the developer commit new code in the repository it will get automatically deployed in the production environment and if it will not work then developer will get informed through an email notification.

Email notification

![Email notification](https://github.com/surinder2000/Deploy-webapp-on-Kubernetes/blob/master/Email.png)

Following is the Build pipeline view of the Jobs in Jenkins

![Build trigger](https://github.com/surinder2000/Deploy-webapp-on-Kubernetes/blob/master/pipeline.png)


## Thank you








   



