# Basis-Image
FROM python:3.9-slim

# Arbeitsverzeichnis im Container
WORKDIR /app

# Systemabhängigkeiten
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    && rm -rf /var/lib/apt/lists/*

# Kopieren der Projektdateien
COPY requirements.txt .
COPY main.py .

# Standard config.json erstellen
RUN echo '[\n\
  {\n\
    "name": "Database1",\n\
    "supabase_url": "SUPABASE_URL",\n\
    "supabase_key": "SUPABASE_KEY",\n\
    "table_name": "keep-alive"\n\
  }\n\
]' > config.json

# Installation der Python-Abhängigkeiten
RUN pip install --no-cache-dir -r requirements.txt

# Zeitzone setzen (optional, falls benötigt)
ENV TZ=UTC

# Cron installieren und konfigurieren
RUN apt-get update && apt-get install -y cron

# Cron-Job einrichten (läuft jeden Montag und Donnerstag um Mitternacht)
RUN echo "0 0 * * 1,4 cd /app && python /app/main.py >> /app/logfile.log 2>&1" > /etc/cron.d/supabase-job
RUN chmod 0644 /etc/cron.d/supabase-job
RUN crontab /etc/cron.d/supabase-job

# Startskript erstellen
RUN echo '#!/bin/sh\n\
# Replace placeholders with environment variables\n\
sed -i "s|SUPABASE_URL|$SUPABASE_URL|g" /app/config.json\n\
sed -i "s|SUPABASE_KEY|$SUPABASE_KEY|g" /app/config.json\n\
\n\
# Start cron\n\
cron -f' > /app/start.sh

RUN chmod +x /app/start.sh

# Container starten
CMD ["/app/start.sh"] 