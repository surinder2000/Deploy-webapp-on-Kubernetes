# Deploy Web app on top of Kubernetes
Deploying web app on top of Kubernetes by integrating it with Git, Github, Docker, and Jenkins.


## Let's see step by step process
### 1. Create Dockerfile for creating jenkins docker image
* This is the Dockerfile code for creating jenkins docker image

![Dockerfile code](https://github.com/surinder2000/automation_through_containerized_jenkins/blob/master/Dockerfilecode.png)

* Run the following command in the same directory to create jenkins docker image

      docker build -t jenkins:latest .
      
### 2. Launch the jenkins container using the following command

    docker container run -it --name jenkin -v jen:/root/ -p 8888:8080 jenkins:latest
    
   Here **jen** is the volume, attached to the root folder of the jenkins container for keeping  the data persistant. To create the volume for docker container use the following command 
  
    docker volume create volume_name (in my case volume_name is jen)
    
   After this setup jenkins, install required plugins like Git, Email notification and Build pipeline.
   
### 3. Let's create the jobs in the jenkins for automation
#### Job 1: Pull the code from github repository as soon as developer commit 
* In Source Control Management section put the Github repository url and branch name

![Git configuration](https://github.com/surinder2000/automation_through_containerized_jenkins/blob/master/job11.jpg)

* In Build trigger section select Poll SCM for checking the github repository every minute

![Build trigger](https://github.com/surinder2000/automation_through_containerized_jenkins/blob/master/job12.jpg)

* In the Build section from Add build step select Execute shell and put the following code in the command box

![Execute shell](https://github.com/surinder2000/automation_through_containerized_jenkins/blob/master/job13.jpg)

* Click on Apply and Save

#### Job 2: By looking at the file name launch the respective webserver container for testing
* In Build trigger section select Build after other projects are built and put Job 1 in the Project to watch box and check Trigger only if build is stable

![Build trigger](https://github.com/surinder2000/automation_through_containerized_jenkins/blob/master/job21.jpg)

* In the Build section from Add build step select Execute shell and put the following code in the command box

![Execute shell](https://github.com/surinder2000/automation_through_containerized_jenkins/blob/master/job22.jpg)

* Click on Apply and Save

#### Job 3: Check whether the site is working or not
* In Build trigger section select Build after other projects are built and put Job 2 in the Project to watch box and check Trigger only if build is stable

![Build trigger](https://github.com/surinder2000/automation_through_containerized_jenkins/blob/master/job31.jpg)

* In the Build section from Add build step select Execute shell and put the following code in the command box

![Execute shell](https://github.com/surinder2000/automation_through_containerized_jenkins/blob/master/job32.jpg)

* Click on Apply and Save

#### Job 4: If app is working fine merge the code from developer branch to master branch
* In Source Control Management section put the Github repository url and branch name, from Additional Behaviour select Merge before build and put Name of repository as **origin**, Branch to merge to as **master** and leave the other boxes as it is

![Git configuration](https://github.com/surinder2000/automation_through_containerized_jenkins/blob/master/job41.jpg)

* In Build trigger section select Build after other projects are built and put Job 3 in the Project to watch box and check Trigger only if build is stable

![Build trigger](https://github.com/surinder2000/automation_through_containerized_jenkins/blob/master/job42.jpg)

* In the Post-build Actions section select Git publisher and check Push Only if Build Succeeds, Merge Results and click on Add Branch put **master** in Branch to push and **origin** in Target remote name

![Post-build Action](https://github.com/surinder2000/automation_through_containerized_jenkins/blob/master/job43.jpg)

* Click on Apply and Save

#### Job 5: After merging into master branch pull the code from github repository from master branch and deploy it in production environment
*  In Source Control Management section put the Github repository url and branch name

![Git configuration](https://github.com/surinder2000/automation_through_containerized_jenkins/blob/master/job51.jpg)

* In Build trigger section select Build after other projects are built and put Job 4 in the Project to watch box and check Trigger only if build is stable

![Build trigger](https://github.com/surinder2000/automation_through_containerized_jenkins/blob/master/job52.jpg)

* In the Build section from Add build step select Execute shell and put the following code in the command box

![Execute shell](https://github.com/surinder2000/automation_through_containerized_jenkins/blob/master/job53.jpg)

* Click on Apply and Save

#### Job 6: Send email notification to developer if site will not work
* In Build trigger section select Build after other projects are built and put Job 3 in the Project to watch box and check Trigger even if the build fails

![Build trigger](https://github.com/surinder2000/automation_through_containerized_jenkins/blob/master/job61.jpg)

* In the Post-build Actions section select Editable Email notification and put the email address of developer, subject and message content (Note: We need to configure SMTP server for sending mail. For this go to Manage jenkins -> Configure -> Extended Email notification and put the details there) 

![Post-build Action](https://github.com/surinder2000/automation_through_containerized_jenkins/blob/master/job62.jpg)

* Click on Apply and Save

#### Job 7: Monitoring the Production environment container if it fails it will launch another one
* In Build trigger section select Build periodically for continuously monitoring the Production environment container 

![Build trigger](https://github.com/surinder2000/automation_through_containerized_jenkins/blob/master/job71.jpg)

* In the Build section from Add build step select Execute shell and put the following code in the command box

![Execute shell](https://github.com/surinder2000/automation_through_containerized_jenkins/blob/master/job72.jpg)

* Click on Apply and Save

That's all our setup is ready

Now as soon as the developer commit new code in the repository it will get automatically tested if it will work fine then it will get automatically deployed in the production environment and if it will not work then developer will get informed through an email notification.

Following is the Build pipeline view of the Jobs in Jenkins

![Build trigger](https://github.com/surinder2000/automation_through_containerized_jenkins/blob/master/buildpipelineview.jpg)








   



