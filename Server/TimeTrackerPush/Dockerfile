FROM python:3.13-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --index-url https://pypi.tuna.tsinghua.edu.cn/simple -r requirements.txt
COPY app.py apns.py event_store.py manage.py ./
USER 10001:10001
ENV PYTHONDONTWRITEBYTECODE=1
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1", "--no-access-log"]
