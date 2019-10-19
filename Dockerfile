FROM python:3.7-alpine3.10

WORKDIR /

COPY Pipfile.lock /
COPY pipenv-install.py /

RUN /pipenv-install.py && \
    rm -fr /usr/local/lib/python3.7/site-packages/pip && \
    rm -fr /usr/local/lib/python3.7/site-packages/setuptools

# install kubectl -rconti
RUN apk update && apk add curl git

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.15.1/bin/linux/amd64/kubectl
RUN chmod u+x kubectl && mv kubectl /bin/kubectl
#

FROM python:3.7-alpine3.10

WORKDIR /

COPY --from=0 /usr/local/lib/python3.7/site-packages /usr/local/lib/python3.7/site-packages

COPY kube_resource_report /kube_resource_report

ARG VERSION=dev
RUN sed -i "s/__version__ = .*/__version__ = '${VERSION}'/" /kube_resource_report/__init__.py

#ENTRYPOINT ["python3", "-m", "kube_resource_report", "/output"]

## this is just here to prevent container from exiting
CMD tail -f /dev/null
