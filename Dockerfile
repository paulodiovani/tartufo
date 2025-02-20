FROM python:3-alpine3.14 as base

WORKDIR /app

FROM base as builder

ENV PIP_DEFAULT_TIMEOUT=100 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    POETRY_VERSION=1.1.12

RUN apk update && \
    apk upgrade && \
    apk add --no-cache cargo gcc libffi-dev musl-dev openssl-dev rust libgit2-dev
RUN pip --no-cache-dir install "poetry==$POETRY_VERSION"
RUN python -m venv /venv

COPY pyproject.toml poetry.lock ./
RUN poetry export -f requirements.txt | /venv/bin/pip install -r /dev/stdin

COPY . .
RUN poetry build && /venv/bin/pip install dist/*.whl

FROM base as final

RUN apk add --no-cache git libgit2 openssh-client
COPY --from=builder /venv /venv
COPY scripts/docker/gitconfig /root/.gitconfig

WORKDIR /git

ENTRYPOINT [ "/venv/bin/tartufo" ]
CMD [ "-h" ]
