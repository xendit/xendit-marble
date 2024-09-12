.PHONY: all front api firebase-emulator

all: front api firebase-emulator

front:
	docker build -t xendit-marble-frontend:latest --secret id=SENTRY_AUTH_TOKEN,src=front/mock_sentry_token.txt -f front/Dockerfile front/

api:
	docker build -t xendit-marble-backend:latest -f api/Dockerfile api/

firebase-emulator:
	docker build -t xendit-firebase-emulator:latest -f firebase-emulator-docker/Dockerfile.firebase_emulator firebase-emulator-docker

clean:
	docker rmi xendit-marble-frontend:latest xendit-marble-backend:latest xendit-firebase-emulator:latest
