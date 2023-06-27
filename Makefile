DB=epa.db
SITES=data/aqs_sites.csv
MONITORS=data/aqs_monitors.csv

# data
data:
	mkdir -p data

data/aqs_sites.zip: data
	curl -o $@ https://aqs.epa.gov/aqsweb/airdata/aqs_sites.zip
	@touch $@

data/aqs_monitors.zip: data
	curl -o $@ https://aqs.epa.gov/aqsweb/airdata/aqs_monitors.zip
	@touch $@

data/%.csv: data/%.zip
	unzip -d data $^

# workflow

$(DB):
	pipenv run sqlite-utils create-database $@ --enable-wal --init-spatialite

sites: $(DB) $(SITES)
	pipenv run sqlite-utils insert $(DB) $@ $(SITES) --csv --detect-types

monitors: $(DB) $(MONITORS)
	pipenv run sqlite-utils insert $(DB) $@ $(MONITORS) --csv --detect-types

indexes: $(DB)
	pipenv run sqlite-utils create-index --if-not-exists $(DB) sites 'County Name'
	pipenv run sqlite-utils create-index --if-not-exists $(DB) sites 'City Name'
	pipenv run sqlite-utils create-index --if-not-exists $(DB) sites 'State Name'
	pipenv run sqlite-utils create-index --if-not-exists $(DB) sites 'Zip Code'
	pipenv run sqlite-utils create-index --if-not-exists $(DB) sites 'CBSA Name'
	pipenv run sqlite-utils create-index --if-not-exists $(DB) sites 'Site Closed Date'
	pipenv run sqlite-utils create-index --if-not-exists $(DB) sites 'Location Setting'
	pipenv run sqlite-utils create-index --if-not-exists $(DB) monitors 'Parameter Name'
	pipenv run sqlite-utils create-index --if-not-exists $(DB) monitors 'Last Sample Date'

install:
	pipenv sync

run:
	# https://docs.datasette.io/en/stable/settings.html#configuration-directory-mode
	pipenv run datasette serve . --load-extension spatialite
