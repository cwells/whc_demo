FROM python:3.12.7-slim

USER root

COPY requirements.txt /app/

RUN pip install --upgrade pip --root-user-action ignore && \
    pip install -r /app/requirements.txt --root-user-action ignore

COPY assets/ /app/assets/
COPY data/ /app/data/
COPY app.py requirements.txt /app/

EXPOSE 8000
WORKDIR /app

CMD ["gunicorn", "-b", "0.0.0.0:8000", "app:server"]