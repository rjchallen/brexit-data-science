#!/bin/bash
# mysql db username and password supplied on command line
uname="$1"
pass="$2"
mysql -u$1 -p$2 --local-infile < sql/output.sql

if ! [ -d html/data ]; then
	mkdir html/data
fi

echo "Exporting data for visualisations"

mysql -u$1 -p$2 -e "SELECT * FROM brexit_data_science.weighted_yougov_poll" > html/data/poll.tsv
mysql -u$1 -p$2 -e "SELECT * FROM brexit_data_science.question1_by_politics" > html/data/question1_by_politics.tsv
mysql -u$1 -p$2 -e "SELECT * FROM brexit_data_science.question2_by_politics" > html/data/question2_by_politics.tsv
mysql -u$1 -p$2 -e "SELECT * FROM brexit_data_science.question2_by_referendum_vote" > html/data/question2_by_referendum_vote.tsv


if ! [ -d node_modules/harp/bin/ ]; then
	echo "Setting up harpjs server"
	npm install harpjs
fi

echo "Starting harpjs server on http://localhost:9000"
node node_modules/harp/bin/harp server html &
bg_pid=$!


while true
do 
sleep 5

	echo "Capturing visualisations"

	cutycapt --url=http://localhost:9000/question1.html --out=html/images/question1.png --delay=100 --min-height=0
	cutycapt --url=http://localhost:9000/question1weighted.html --out=html/images/question1weighted.png --delay=100 --min-height=0
	cutycapt --url=http://localhost:9000/question1byPolitics.html --out=html/images/question1byPolitics.png --delay=100 --min-height=0


	cutycapt --url=http://localhost:9000/question2.html --out=html/images/question2.png --delay=100 --min-height=0
	cutycapt --url=http://localhost:9000/question2weighted.html --out=html/images/question2weighted.png --delay=100 --min-height=0
	cutycapt --url=http://localhost:9000/question2byPolitics.html --out=html/images/question2byPolitics.png --delay=100 --min-height=0
	cutycapt --url=http://localhost:9000/question2byReferendumVote.html --out=html/images/question2byReferendumVote.png --delay=100 --min-height=0
	
done

wait $bg_pid