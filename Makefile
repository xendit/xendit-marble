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

# Run this goal like this
# pg_dump -h <marble-postgres.rds.amazonaws.com> -p 5432 -U postgres -d marble -F d -v -j 4 --no-owner --no-privileges -f <marble_backup.dump>
# make copy-db BACKUP_FILE=<marble_backup.dump>
copy-db:
	docker-compose stop api cron app firebase_auth
	docker cp $(BACKUP_FILE) marble-postgres:/tmp/backup
	docker exec marble-postgres dropdb -U postgres marble
	docker exec marble-postgres createdb -U postgres marble
	docker exec marble-postgres pg_restore -U postgres -d marble -j 4 /tmp/backup
	docker-compose start api cron app firebase_auth