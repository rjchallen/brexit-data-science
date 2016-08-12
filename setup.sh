#!/bin/bash
# mysql db username and password supplied on command line
uname="$1"
pass="$2"

# https://ig.ft.com/sites/brexit-polling/
# http://www.bbc.co.uk/news/uk-politics-eu-referendum-36271589

cd data
if ! [ -d tmp ]; then
    mkdir tmp
fi

if ! [ -f download/EU-referendum-result-data.csv ]
    then
    echo "Getting referendum result"
    curl 'http://www.electoralcommission.org.uk/__data/assets/file/0014/212135/EU-referendum-result-data.csv' -o download/EU-referendum-result-data.csv
    else 
    echo "Using cached referendum result data"
fi

if ! [ -f download/2015-election-result.csv ]
    then
    echo "Getting cached election result data"
    cd tmp
    curl 'http://www.electoralcommission.org.uk/__data/assets/file/0004/191650/2015-UK-general-election-data-results-WEB.zip' -o 2015-UK-general-election-data-results-WEB.zip
    unzip -o 2015-UK-general-election-data-results-WEB.zip
    cp RESULTS.csv ../download/2015-election-result.csv
    cd ..
    else
    echo "Using cached election result data"
fi

if ! [ -f download/2015-population-estimates.csv ]
    then
    echo "Getting population estimate data"
    cd tmp
    curl 'https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/populationestimatesforukenglandandwalesscotlandandnorthernireland/mid2015/ukmye2015.zip' -o ukmye2015.zip
    unzip -o ukmye2015.zip
    cp 'MYEB1_detailed_population_estimates_series_UK_(0115).csv' ../download/2015-population-estimates.csv
    cd ..
    else
    echo "Using cached population estimate data"
fi

if ! [ -f download/2011-oac-clusters-and-names.csv ]
    then
    echo "Getting geographical data"
    cd tmp
    curl 'http://www.ons.gov.uk/ons/guide-method/geography/products/area-classifications/ns-area-classifications/ns-2011-area-classifications/datasets/2011-oac-clusters-and-names-csv.zip' -o 2011-oac-clusters-and-names-csv.zip
    unzip -o 2011-oac-clusters-and-names-csv.zip
    cp '2011 OAC Clusters and Names.csv' ../download/2011-oac-clusters-and-names.csv
    cd ..
    else
    echo "Using cached geographical data"
fi

if ! [ -f download/2014-wards-to-lad-lookup.csv ]
    then
    echo "Getting electoral wards data"
    curl 'http://opengeography.ons.opendata.arcgis.com/datasets/68e5324bd26a4cacba349b4e8e4bc80b_0.csv' -o download/2014-wards-to-lad-lookup.csv
    else
    echo "Using cached electoral wards data"
fi


mysql -u$1 -p$2 --local-infile < ../sql/buildDb.sql
mysql -u$1 -p$2 --local-infile < ../sql/views.sql
mysql -u$1 -p$2 --local-infile < ../sql/weighting.sql
mysql -u$1 -p$2 --local-infile < ../sql/output.sql

if ! [ -d ../html/data ]; then
	mkdir ../html/data
fi

mysql -u$1 -p$2 -e "SELECT * FROM brexit_data_science.weighted_yougov_poll" > ../html/data/poll.tsv
mysql -u$1 -p$2 -e "SELECT * FROM brexit_data_science.question1_by_politics" > ../html/data/question1_by_politics.tsv

cd ..
if ! [ -d node_modules/harp/bin/ ]; then
	npm install harpjs
fi
# node node_modules/http-server/bin/http-server &
node node_modules/harp/bin/harp server html &

cutycapt --url=http://localhost:9000/question1.html --out=html/images/question1.png --delay=100 --min-height=0
cutycapt --url=http://localhost:9000/question1weighted.html --out=html/images/question1weighted.png --delay=100 --min-height=0
cutycapt --url=http://localhost:9000/question1byPolitics.html --out=html/images/question1byPolitics.png --delay=100 --min-height=0

