# Assignment 2: Dockerize a small Flask app with a basic CI check

A tiny Flask app (`/` and `/health`) packaged with Docker and built by GitHub Actions on every push.

## Files
| File | Purpose |
|---|---|
| `app.py`, `requirements.txt` | The provided app |
| `Dockerfile` | Image definition (python:3.12-slim, non-root user) |
| `.dockerignore` | Keeps git data, caches and docs out of the image |
| `.github/workflows/build.yml` | CI: builds the image, runs the container, calls `/health` |

## Build and run locally

```bash
docker build -t myapp .
docker run -d --name myapp -p 5000:5000 myapp
curl localhost:5000/health
```

### Output
```
$ curl localhost:5000/health
{"status":"ok"}
```
<!-- Replace/confirm with your own terminal output or a screenshot from your Docker run -->

Stop and clean up: `docker rm -f myapp`

## Task 4: Bugs in the teammate's Dockerfile

Original:
```dockerfile
FORM python:3.12-slim
WORKDIR /app
COPY . .
RUN pip install -r requirement.txt
CMD ["python", "app.py"]
```
Run with: `docker run -p 5000:8080 myapp`

| # | Problem | Why it breaks | Fix |
|---|---|---|---|
| 1 | `FORM` is a typo | Docker fails with "unknown instruction: FORM", so the image never builds | `FROM python:3.12-slim` |
| 2 | `requirement.txt` | The file is named `requirements.txt` (plural), so `pip install` fails with "No such file" | `RUN pip install -r requirements.txt` |
| 3 | `-p 5000:8080` | Port mapping is `HOST:CONTAINER`. Flask listens on **5000** inside the container, but nothing listens on 8080, so the app cannot be reached | `docker run -p 5000:5000 myapp` |

Improvements made beyond the bug fixes:
- Copy `requirements.txt` first and install, then copy the code, so dependency layers are cached.
- `pip install --no-cache-dir` keeps the image smaller.
- `EXPOSE 5000` documents the port (informational only).
- Runs as a non-root user (`appuser`).
- `.dockerignore` keeps the build context small and avoids leaking `.git` or `.env`.
- `app.py` already binds to `0.0.0.0`, which is required for the port to be reachable from outside the container.

## CI (GitHub Actions)
`.github/workflows/build.yml` runs on every push and pull request:
1. Checks out the code
2. Builds the Docker image
3. (Bonus) Starts the container and retries `curl http://localhost:5000/health` for up to 15 seconds
4. Stops the container, even on failure

No registry push is performed.
