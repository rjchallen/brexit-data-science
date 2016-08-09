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

if ! [ -f EU-referendum-result-data.csv ]
    then
    echo "Getting referendum result"
    curl 'http://www.electoralcommission.org.uk/__data/assets/file/0014/212135/EU-referendum-result-data.csv' -o EU-referendum-result-data.csv
    else 
    echo "Using cached referendum result data"
fi

if ! [ -f 2015-election-result.csv ]
    then
    echo "Getting cached election result data"
    cd tmp
    curl 'http://www.electoralcommission.org.uk/__data/assets/file/0004/191650/2015-UK-general-election-data-results-WEB.zip' -o 2015-UK-general-election-data-results-WEB.zip
    unzip -o 2015-UK-general-election-data-results-WEB.zip
    cp RESULTS.csv ../2015-election-result.csv
    cd ..
    else
    echo "Using cached election result data"
fi

if ! [ -f 2015-population-estimates.csv ]
    then
    echo "Getting population estimate data"
    cd tmp
    curl 'https://www.ons.gov.uk/file?uri=/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/populationestimatesforukenglandandwalesscotlandandnorthernireland/mid2015/ukmye2015.zip' -o ukmye2015.zip
    unzip -o ukmye2015.zip
    cp 'MYEB1_detailed_population_estimates_series_UK_(0115).csv' ../2015-population-estimates.csv
    cd ..
    else
    echo "Using cached population estimate data"
fi

if ! [ -f 2011-oac-clusters-and-names.csv ]
    then
    echo "Getting geographical data"
    cd tmp
    curl 'http://www.ons.gov.uk/ons/guide-method/geography/products/area-classifications/ns-area-classifications/ns-2011-area-classifications/datasets/2011-oac-clusters-and-names-csv.zip' -o 2011-oac-clusters-and-names-csv.zip
    unzip -o 2011-oac-clusters-and-names-csv.zip
    cp '2011 OAC Clusters and Names.csv' ../2011-oac-clusters-and-names.csv
    cd ..
    else
    echo "Using cached geographical data"
fi

if ! [ -f 2014-wards-to-lad-lookup.csv ]
    then
    echo "Getting electoral wards data"
    curl 'http://opengeography.ons.opendata.arcgis.com/datasets/68e5324bd26a4cacba349b4e8e4bc80b_0.csv' -o 2014-wards-to-lad-lookup.csv
    else
    echo "Using cached electoral wards data"
fi


mysql -u$1 -p$2 --local-infile < ../sql/buildDb.sql

# mysql -u$1 -p$2 --local-infile < ../sql/views.sql
