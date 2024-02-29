# Шаг #1 | Building an image
FROM python:3.12-slim-bullseye as build-image

# Шаг #2 | Файлы, переменные и группы
# PYTHONUNBUFFERED - Буферизация логов в контейнере stdout и stderr - 0 отключить
# Добавление в группу docker, чтобы иметь возможность использовать команды docker без root в будущем

ENV APP_ROOT /src
ENV PYTHONUNBUFFERED 1
ENV PYTHONPATH "${PYTHONPATH}:${APP_ROOT}"
ENV APP_USER service_user

RUN groupadd -r docker \
    && useradd -r -m \
    --home-dir ${APP_ROOT} \
    -s /usr/sbin/nologin \
    -g docker ${APP_USER}
RUN usermod -aG sudo ${APP_USER}

# Шаг #3 Installing poetry
# Не создавайте venv при установке poetry, но загрузите зависимости в окружение python
FROM build-image as poetry-init

ARG APP_ROOT

WORKDIR ${APP_ROOT}

RUN pip install --no-cache-dir poetry==1.5.1

RUN poetry config virtualenvs.create false


# Шаг #4 | Installing dependencies
FROM poetry-init as poetry-install

COPY pyproject.toml .

COPY poetry.lock .

RUN poetry install

# Шаг #5 | Запуск приложения
FROM poetry-install as run-app

# . -> APP_ROOT /src
COPY . .

CMD ["alembic", "upgrade", "head"]

CMD ["uvicorn", "app.core.application:application", "--host", "0.0.0.0", "--port", "4000"]
