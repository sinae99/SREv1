import json
import os
import urllib.error
import urllib.request

import psycopg
from flask import Flask, Response, jsonify, request
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Gauge, generate_latest

# Prometheus counter for total API calls to /iploc.
REQUESTS = Counter(
    "iploc_requests_total",
    "Total /iploc requests",
)

# Prometheus gauge for the number of cached IP rows in Postgres.
CACHED_IPS = Gauge(
    "iploc_cached_ips",
    "Number of IPs stored in Postgres cache",
)

# Flask application object used by Gunicorn and the tests.
app = Flask(__name__)

# Guard so the schema creation runs only once per process.
_ready = False


def get_conn():
    # Read DATABASE_URL from the environment and open a Postgres connection.
    return psycopg.connect(os.environ["DATABASE_URL"])


def ensure_schema():
    # Create the cache table lazily so the app can start even if the DB is fresh.
    global _ready
    if _ready:
        return
    with get_conn() as conn:
        conn.execute(
            "CREATE TABLE IF NOT EXISTS ip_cache ("
            "ip TEXT PRIMARY KEY, "
            "country TEXT NOT NULL)"
        )
        conn.commit()
    _ready = True


def refresh_cached_ips():
    # Count cache rows and expose that number to Prometheus.
    with get_conn() as conn:
        row = conn.execute("SELECT COUNT(*) FROM ip_cache").fetchone()
    CACHED_IPS.set(row[0] if row else 0)


def lookup_cache(ip: str):
    # Fetch a cached country for the supplied IP address, if it exists.
    with get_conn() as conn:
        row = conn.execute(
            "SELECT country FROM ip_cache WHERE ip = %s", (ip,)
        ).fetchone()
    return row[0] if row else None


def store_cache(ip: str, country: str):
    # Insert a cache row and ignore duplicates when the IP already exists.
    with get_conn() as conn:
        conn.execute(
            "INSERT INTO ip_cache (ip, country) VALUES (%s, %s) "
            "ON CONFLICT (ip) DO NOTHING",
            (ip, country),
        )
        conn.commit()


def fetch_country(ip: str) -> str:
    # Ask the public geo service for the country that matches the IP address.
    url = f"http://ip-api.com/json/{ip}?fields=status,country,message"
    with urllib.request.urlopen(url, timeout=5) as resp:
        data = json.loads(resp.read().decode())
    if data.get("status") != "success":
        raise ValueError(data.get("message", "geo lookup failed"))
    return data["country"]


@app.get("/health")
def health():
    # Simple liveness/readiness endpoint.
    return jsonify(status="ok")


@app.get("/metrics")
def metrics():
    # Return Prometheus exposition text for scraping.
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


@app.get("/iploc")
def iploc():
    # Count the request before any validation so failures are still visible.
    REQUESTS.inc()

    # Read and trim the query parameter.
    ip = request.args.get("ip", "").strip()
    if not ip:
        return jsonify(error="missing ip"), 400

    try:
        # Make sure the cache table exists before touching the database.
        ensure_schema()

        # First try the Postgres cache.
        cached = lookup_cache(ip)
        if cached:
            refresh_cached_ips()
            return jsonify(ip=ip, country=cached)

        # On cache miss, call the upstream IP geolocation service.
        country = fetch_country(ip)

        # Persist the fresh answer for future requests.
        store_cache(ip, country)
        refresh_cached_ips()
        return jsonify(ip=ip, country=country)
    except (psycopg.Error, urllib.error.URLError, TimeoutError, ValueError, KeyError) as exc:
        # Convert storage/network/parse failures into a consistent gateway error.
        return jsonify(error=str(exc)), 502
