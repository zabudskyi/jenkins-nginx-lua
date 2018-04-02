pipeline {
  agent any
  environment {
    dockerhub_account="coul"
    app_name="nginx-lua"
  }

  stages {
    stage('Build and Dockerize'){
      steps {
        sh "docker build -t ${dockerhub_account}/$app_name:$BUILD_NUMBER ."
      }
    }

    stage('Push image to dockerhub'){
      steps {
        /* Workaround to address issue with credentials stored in Jenkins not
        * being passed correctly to the docker registry
        * - ref https://issues.jenkins-ci.org/browse/JENKINS-38018 */
        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'docker-hub-credentials',
        usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD']]) {
          sh 'docker login -u $USERNAME -p $PASSWORD https://index.docker.io/v1/'}

        withDockerRegistry([credentialsId: 'docker-hub-credentials', url: 'https://registry.hub.docker.com']) {
          sh "docker push ${dockerhub_account}/$app_name:$BUILD_NUMBER"
        }
      }
    }

    stage('Deploy'){
      steps {
      withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'aws-creds',
          accessKeyVariable: 'AWS_ACCESS_KEY_ID',
          secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
      ]]) {
          sh '''
             docker-machine create --driver amazonec2 \
             --amazonec2-access-key ${AWS_ACCESS_KEY_ID} \
             --amazonec2-secret-key ${AWS_SECRET_ACCESS_KEY} \
             --amazonec2-region eu-west-2 \
             --amazonec2-ssh-user ubuntu \
             --amazonec2-instance-type "t2.micro" \
             --amazonec2-open-port 80 \
             ${app_name}-${BUILD_NUMBER}

             docker-machine scp -r -d ${WORKSPACE}/nginx/ ${app_name}-${BUILD_NUMBER}:/tmp/nginx

             eval $(docker-machine env ${app_name}-${BUILD_NUMBER})
             docker run -d -p 80:80 \
             --volume /tmp/nginx/conf/nginx.conf:/etc/nginx/conf/nginx.conf \
             --volume /tmp/nginx/html/index.html:/etc/nginx/html/index.html \
             ${dockerhub_account}/${app_name}:${BUILD_NUMBER}
          '''
          }
      }
    }
  }
}
