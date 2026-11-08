# Build the static website using Astro (https://docs.astro.build/).
#
# Generated CSV/JSON files from SQL files and SPARQL files.
# SQL files tries to generate CSV/JSON files using a local PostgreSQL database.
#   - SQL files inside `src/sql/csv` generate CSV files.
#   - SQL files inside `src/sql/json` generate JSON files.
#   - SPARQL files (`*.rq`) inside `src/sparql` generate CSV files.
# Missing files will be generated before building the website.
sql2csv     := $(wildcard src/sql/csv/*.sql)
sql2json    := $(wildcard src/sql/json/*.sql)
sparql      := $(wildcard src/sparql/*.rq)
csv_sql     := $(patsubst src/sql/csv/%.sql, public/data/%.csv, $(sql2csv))
csv_sparql  := $(patsubst src/sparql/%.rq, public/data/%.csv, $(sparql))
csv         := $(csv_sql) $(csv_sparql)
json        := $(patsubst src/sql/json/%.sql, public/data/%.json, $(sql2json))
objs        := $(csv) $(json)

# `taxonomy.json` is a bit more complex: we first fetch the CSV then produce the tree.
# (See the rule below.)
objs += public/data/taxonomy.json

endpoint := https://humility.lod4hss.cloud/wisski/endpoint/default

# TODO: database creation with `nlpg` from the sparql endpoint
dbname   := humility

sed_remove_base_uri := sed -r 's|https?://humility\.lod4hss\.cloud/resource/||g'

all: build

build: $(objs)
	npx astro build

install:
	npm install

dev: $(objs)
	npx astro dev

public/data/%.csv: src/sparql/%.rq
	@mkdir -p $(@D)
	roqet -q $< -r csv -p $(endpoint) | $(sed_remove_base_uri) > $@

public/data/%.csv: src/sql/csv/%.sql
	@mkdir -p $(@D)
	psql -d $(dbname) -Xq --csv -f $< > $@

public/data/%.json: src/sql/json/%.sql
	@mkdir -p $(@D)
	psql -d $(dbname) -Xqt -f $< | jq . -c > $@

public/data/taxonomy.json: src/util/make_taxonomy.cjs public/data/taxonomy.csv
	@mkdir -p $(@D)
	node $^ | jq . -c > $@

humility.sql:
	pg_dump -d $(dbname) --no-owner --format plain --no-comments > $@

clean:
	rm -f $(objs)

.PHONY: build all clean install dev
