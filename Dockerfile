# FROM public.ecr.aws/lambda/python:3.12
FROM python:3.12-slim

USER root
WORKDIR /app
ADD . /app

# COPY app.py requirements.txt ${LAMBDA_TASK_ROOT}
# COPY assets/ {LAMBDA_TASK_ROOT}/assets/
# COPY data/ ${LAMBDA_TASK_ROOT}/data/

RUN pip install --upgrade pip --root-user-action ignore && \
    pip install -r requirements.txt --root-user-action ignore

CMD ["python", "app.py"]