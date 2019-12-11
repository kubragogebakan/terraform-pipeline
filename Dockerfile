FROM python:3-alpine
WORKDIR /usr/src/app
EXPOSE 8000
COPY requirements.txt .
RUN pip install -qr requirements.txt
RUN apk add --no-cache bash coreutils grep sed
COPY server.py .
CMD ["python3", "./server.py"]
