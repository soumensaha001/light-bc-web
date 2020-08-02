export DOCKER_USERNAME='your docker-hub user here'
export DOCKER_PASSWORD='your docker-hub password here'
export DOCKER_EMAIL='your email here'
export GIT_USERNAME='your git user here'

# Login to Sonar Server, make a project and generate a token for it.
export SONARQUBE_URL='http://sonarqube-sonarqube.tools.svc.cluster.local:9000'
export SONARQUBE_PROJECT='<project here>'
export SONARQUBE_LOGIN='<login here>'

export BC_PROJECT="bc-light"

./setup-bc-fundament.sh
