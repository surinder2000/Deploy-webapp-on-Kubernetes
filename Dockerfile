FROM centos
RUN yum install sudo -y
RUN yum install net-tools -y
RUN yum install wget -y
RUN yum install git -y
RUN yum install curl -y
RUN yum install openssh-clients -y

RUN wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
RUN rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
RUN yum install java-11-openjdk.x86_64 -y
RUN yum install jenkins -y
RUN echo -e "jenkins ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers 
CMD /etc/rc.d/init.d/jenkins start 

EXPOSE 8080
CMD ["java","-jar","/usr/lib/jenkins/jenkins.war"]


