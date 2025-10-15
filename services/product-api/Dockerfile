# ---------- Build stage ----------
FROM python:3.11-slim AS build
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
COPY requirements.txt ./
RUN pip install --upgrade pip && pip wheel --no-cache-dir --no-deps -r requirements.txt -w /wheels

# ---------- Runtime stage ----------
FROM python:3.11-slim AS runtime
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
COPY --from=build /wheels /wheels
COPY requirements.txt ./
RUN pip install --no-cache /wheels/* && rm -rf /wheels
COPY app.py ./
USER 10001
EXPOSE 5000
CMD ["python", "app.py"]