#FROM node:6-alpine
#FROM node:14.8.0-alpine3.11
#FROM registry.redhat.io/rhscl/nodejs-10-rhel7
#FROM nodejs:10-SCL
#FROM nodejs
FROM image-registry.openshift-image-registry.svc:5000/openshift/nodejs:10-SCL

# Install Extra Packages
#RUN apk --update add git less openssh jq bash bc ca-certificates curl && \
#    rm -rf /var/lib/apt/lists/* && \
#    rm -rf /var/cache/apk/

# Set Environment Variables
ENV NPM_CONFIG_PREFIX=/home/blue/.npm-global
ENV PATH=$PATH:/home/blue/.npm-global/bin
ENV NODE_ENV production

# Create app directory
USER 0
ENV APP_HOME=/app
#RUN mkdir -p $APP_HOME/node_modules $APP_HOME/public/resources/bower_components
RUN mkdir -pv $APP_HOME/node_modules $APP_HOME/public/resources/bower_components
WORKDIR $APP_HOME

# Copy package.json, bower.json, and .bowerrc files
COPY StoreWebApp/package*.json StoreWebApp/bower.json StoreWebApp/.bowerrc ./

# Create user, chown, and chmod
#RUN adduser -u 2000 -G root -D blue \
#	&& chown -R 2000:0 $APP_HOME

RUN chown -R 2000:0 $APP_HOME &&\
  chgrp -R 0 $APP_HOME &&\
  chmod -R g=u $APP_HOME

# Install Dependencies
USER 2000
RUN npm install
USER 0

COPY startup.sh startup.sh
COPY StoreWebApp ./

# Chown
RUN chown -R 2000:0 $APP_HOME

RUN mkdir -pv /home/blue
RUN chown -R 2000:0 /home/blue &&\
  chgrp -R 0 /home/blue &&\
  chmod -R g=u /home/blue

# Cleanup packages
# RUN apk del git less openssh
#RUN apk del git less openssh jq bc curl

# Switch back to non-root
USER 2000

EXPOSE 8000 9000
ENTRYPOINT ["./startup.sh"]
