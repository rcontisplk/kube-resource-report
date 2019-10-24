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

FROM python:3.7-alpine3.10

WORKDIR /

COPY --from=0 /usr/local/lib/python3.7/site-packages /usr/local/lib/python3.7/site-packages

COPY kube_resource_report /root/kube_resource_report
COPY resources/crontab /etc/cron.d/root

ARG VERSION=dev
RUN sed -i "s/__version__ = .*/__version__ = '${VERSION}'/" /root/kube_resource_report/__init__.py

#ENTRYPOINT ["python3", "-m", "kube_resource_report", "/output"]

## this is just here to prevent container from exiting
#CMD tail -f /dev/null

# run cron in the foreground so container doesn't exit; see if this works
ENTRYPOINT ["/usr/sbin/crond", "-f", "-d", "0", "-c", "/etc/cron.d"]
