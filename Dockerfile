FROM python:3.7-alpine3.10

WORKDIR /

COPY Pipfile.lock /
COPY pipenv-install.py /

RUN /pipenv-install.py && \
    rm -fr /usr/local/lib/python3.7/site-packages/pip && \
    rm -fr /usr/local/lib/python3.7/site-packages/setuptools

FROM python:3.7-alpine3.10

WORKDIR /

COPY --from=0 /usr/local/lib/python3.7/site-packages /usr/local/lib/python3.7/site-packages

COPY kube_resource_report /root/kube_resource_report
COPY resources/crontab /etc/cron.d/root

ARG VERSION=dev
RUN sed -i "s/__version__ = .*/__version__ = '${VERSION}'/" /root/kube_resource_report/__init__.py

ENTRYPOINT ["/usr/sbin/crond", "-f", "-d", "0", "-c", "/etc/cron.d"]
