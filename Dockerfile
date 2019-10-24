FROM python:3.7-alpine3.10

WORKDIR /

COPY Pipfile.lock /
COPY pipenv-install.py /

RUN /pipenv-install.py && \
    rm -fr /usr/local/lib/python3.7/site-packages/pip && \
    rm -fr /usr/local/lib/python3.7/site-packages/setuptools

# install kubectl ; should only be needed for testing as I think the script hits the apiserver directly.
RUN apk update && apk add curl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.15.1/bin/linux/amd64/kubectl
RUN chmod u+x kubectl && mv kubectl /bin/kubectl

RUN apk update && apk add cron

FROM python:3.7-alpine3.10

WORKDIR /

COPY --from=0 /usr/local/lib/python3.7/site-packages /usr/local/lib/python3.7/site-packages

COPY kube_resource_report /kube_resource_report
COPY resources/crontab /etc/cron.d/krr-cron
RUN chmod 0644 /etc/cron.d/krr-cron

ARG VERSION=dev
RUN sed -i "s/__version__ = .*/__version__ = '${VERSION}'/" /kube_resource_report/__init__.py

RUN addgroup -g 314 krr && adduser -s /bin/sh -D -G krr -g krr -u 314 krr
RUN mkdir /output
RUN chown -R krr:krr /kube_resource_report /output
## leaving this commented out; I think cron itself has to run as root.
#USER krr:krr

#ENTRYPOINT ["python3", "-m", "kube_resource_report", "/output"]

## this is just here to prevent container from exiting
#CMD tail -f /dev/null

# run cron in the foreground so container doesn't exit; see if this works
CMD ["cron", "-f"]
