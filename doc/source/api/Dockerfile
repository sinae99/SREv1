# Small production image for the Flask API.

FROM python:3.12-slim

# Run everything from /app inside the container.
WORKDIR /app

# Install dependencies before copying the app source.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the Flask application itself.
COPY app.py .

# The application listens on port 8000 inside the container.
EXPOSE 8000

# Start Gunicorn with one Flask app object named `app`.
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
