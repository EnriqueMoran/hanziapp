FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# create directory for persistent database file
RUN mkdir -p /data

# set default database path
ENV DB_PATH=/data/hanzi.db

COPY . .
RUN python init_db.py

EXPOSE 5000
CMD ["python", "app.py"]
