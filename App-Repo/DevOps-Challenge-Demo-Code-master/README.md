# DevOps Challenge Demo Code

This application will be used as a demo for DevOps Challenges.

You should fork/clone this repository to use as a basis for the challenge.

Link of the repo to copy in deplyment script (ready with docker file for image and yaml file for deployments on kubernates)

<https://github.com/SNOWxZERO/DevOps-Challenge-Demo-Code-With-Docker-Ready.git>

## Demo application

### Requirements

#### System

- GNU/Linux
- `python` >= 3.7
- `pip` >= 9.0
- `redis` >= 5.0

`>=` means any version of the package, above or equal to the specified version.

#### Application

- `redis-py`
- `tornado`

You can find them in the `requirements.txt` file and their required version number.
You can install them by using:

```bash
pip install -r requirements.txt
```

### :rocket: Starting the Application

The application uses several environment variables.
You can find them all and their default values in the `.env` file. They need to be avaiable at runtime. Here is an overview about the environment variables:

- `ENVIRONMENT` the environment in which the application is run. Likely `PROD` for production or `DEV` for development context.
- `HOST` the hostname on which the application is running. Locally it is `localhost`.
- `PORT` is the port on which the application is running.
- `REDIS_HOST` is the hostname on which redis is running. Locally it is `localhost`.
- `REDIS_PORT` is the port on which to communicate with redis. Normally it is `6379`.
- `REDIS_DB` which redis db should be used. Normally it is `0`.

Application can be found in `hello.py` file. You can start the application by using:

```bash
export $(cat .env | xargs) && python hello.py
```

Although you don't have to export the environment variables that way. :wink:

### Docker

You can run this application in Docker. There are two recommended ways:

- Use docker-compose (recommended) — this will start a Redis service and the app together.
- Use plain docker (you must run a Redis container or point the app at an external Redis).

Examples:

- Start with docker-compose (recommended):

```bash
# build images and start services (app + redis)
docker-compose up --build

# run in background
docker-compose up -d --build

# stop and remove containers
docker-compose down
```

- Using docker only (manual Redis) — creates a user network, starts Redis, builds and runs the app:

```bash
# create a network for the containers
docker network create demo-net

# start a Redis container on that network
docker run -d --name demo_redis --network demo-net redis:7-alpine

# build the app image
docker build -t devops-challenge-demo .

# run the app container on the same network and publish the port (Dockerfile defaults to PORT=8888)
docker run --rm --name demo_app --network demo-net -p 8888:8888 devops-challenge-demo
```

- Quick one-container run (if you have an external Redis and/or an `.env` file):

```bash
# use an env file (if present) to provide HOST/PORT/REDIS_* values
docker build -t devops-challenge-demo .
docker run --rm -p 8888:8888 --env-file .env devops-challenge-demo

# or pass env values directly
docker run --rm -p 8888:8888 -e PORT=8888 -e HOST=0.0.0.0 \
 -e REDIS_HOST=redis -e REDIS_PORT=6379 -e REDIS_DB=0 devops-challenge-demo
```

Notes:

- The `Dockerfile` sets sensible defaults (PORT=8888, HOST=0.0.0.0, REDIS_HOST=redis). If you use `docker-compose` the app will be able to reach the Redis service using the hostname `redis`.
- If you run the app container alone, ensure a Redis service is reachable and set `REDIS_HOST`/`REDIS_PORT` appropriately.

### Static files

- Static files are located in `static/` folder.
- Templates are located in `template/` folder.

### Executing Tests

Tests can be found in `tests/test.py` file.
You can run the tests by using:

```bash
python tests/test.py
```

## License

Copyright (c) 2019 by the Tradebyte Software GmbH.
`DevOps-Challenge` is free software, and may be redistributed under the terms specified in the [LICENSE] file.

[license]: /LICENSE
