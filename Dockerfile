FROM python:3.10-slim

# ---------- System deps ----------
RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc build-essential libpq-dev curl \
        libxml2-dev libxslt1-dev antiword poppler-utils tesseract-ocr \
    && rm -rf /var/lib/apt/lists/*

# ---------- Env tweaks ----------
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# ---------- Workdir ----------
WORKDIR /app

# ---------- Copy & install requirements ----------
COPY backend/requirements.txt .

# -- 1/2: upgrade pip
RUN pip install --no-cache-dir --upgrade pip

# -- 2/2: pre-install PyTorch CPU wheels, then the rest
RUN pip install --no-cache-dir torch==1.13.1+cpu torchvision==0.14.1+cpu \
        -f https://download.pytorch.org/whl/torch_stable.html \
    && pip install --no-cache-dir -r requirements.txt

# ---------- Download spaCy model ----------
RUN python -m spacy download en_core_web_sm

# ---------- Copy source ----------
COPY backend/ .

# ---------- Create non-root user ----------
RUN groupadd -r tailingsiq && useradd -r -g tailingsiq tailingsiq \
    && mkdir -p /app/uploads /app/chroma_db /app/logs \
    && chown -R tailingsiq:tailingsiq /app
USER tailingsiq

# ---------- Healthcheck & ports ----------
HEALTHCHECK --interval=30s --timeout=10s CMD curl -f http://localhost:8000/health || exit 1
EXPOSE 8000

# ---------- Start ----------
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
