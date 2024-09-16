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
# make restore-db-to-dev BACKUP_FILE=<marble_backup.dump>
restore-db-to-dev:
	docker-compose stop api cron app firebase_auth
	docker cp $(BACKUP_FILE) marble-postgres:/tmp/backup
	docker exec marble-postgres dropdb -U postgres marble
	docker exec marble-postgres createdb -U postgres marble
	docker exec marble-postgres pg_restore -U postgres -d marble -j 4 /tmp/backup
	docker-compose start api cron app firebase_auth

delete-table-in-dev:
	docker exec marble-postgres psql -U postgres -d marble -c "DROP TABLE IF EXISTS \"org-Xendit\".\"$(TABLE_NAME)\""
	docker exec marble-postgres psql -U postgres -d marble -c "DELETE FROM \"marble\".\"data_model_tables\" WHERE name='$(TABLE_NAME)'"

# Following targets require ~/.ssh/config to be set up
# Create SSH Config inside ~/.ssh/config
# ```
# Host marble
#     HostName 10.103.20.57
#     User ec2-user
#     IdentityFile ~/.ssh/tms-poc.pem
# ```	

# Prerequisite: Install git-archive-all
# ```
# brew install git-archive-all
# ```
# Run this goal like this
# make build-image-on-ec2
build-image-on-ec2:
	git-archive-all /tmp/xendit-marble.zip
	caffeinate -i rsync -avz --progress -e ssh /tmp/xendit-marble.zip marble:/tmp/
	ssh marble 'bash -c "\
		rm -rf /tmp/xendit-marble && \
		cd /tmp && \
		unzip xendit-marble.zip && \
		cd /tmp/xendit-marble && \
		docker build -t xendit-marble-frontend:latest --secret id=SENTRY_AUTH_TOKEN,src=front/mock_sentry_token.txt -f front/Dockerfile front/ && \
		docker build -t xendit-marble-backend:latest -f api/Dockerfile api/ \
	"'