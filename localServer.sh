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
mysql -u$1 -p$2 -e "SELECT * FROM brexit_data_science.question1_summary" > html/data/question1_summary.tsv
mysql -u$1 -p$2 -e "SELECT * FROM brexit_data_science.question1_by_politics" > html/data/question1_by_politics.tsv
mysql -u$1 -p$2 -e "SELECT * FROM brexit_data_science.question2_summary" > html/data/question2_summary.tsv
mysql -u$1 -p$2 -e "SELECT * FROM brexit_data_science.question2_by_politics" > html/data/question2_by_politics.tsv
mysql -u$1 -p$2 -e "SELECT * FROM brexit_data_science.question2_by_referendum_vote" > html/data/question2_by_referendum_vote.tsv

mysql -u$1 -p$2 -e "SELECT * FROM brexit_data_science.change_2015_2016" > html/data/change_2015_2016.tsv
mysql -u$1 -p$2 -e "SELECT * FROM brexit_data_science.predicted_2016_seats" > html/data/predicted_2016_seats.tsv
mysql -u$1 -p$2 -e "SELECT * FROM brexit_data_science.brexit_candidates_predicted_to_lose" > html/data/brexit_candidates_predicted_to_lose.tsv
mysql -u$1 -p$2 -e "SELECT * FROM brexit_data_science.top_20_brexit_candidates_predicted_to_lose" > html/data/top_20_brexit_candidates_predicted_to_lose.tsv



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

	cutycapt --url=http://localhost:9000/question1summary.html --out=html/images/question1summary.png --delay=100 --min-height=0
	cutycapt --url=http://localhost:9000/question1weighted.html --out=html/images/question1weighted.png --delay=100 --min-height=0
	cutycapt --url=http://localhost:9000/question1byPolitics.html --out=html/images/question1byPolitics.png --delay=100 --min-height=0


	cutycapt --url=http://localhost:9000/question2summary.html --out=html/images/question2summary.png --delay=100 --min-height=0
	cutycapt --url=http://localhost:9000/question2weighted.html --out=html/images/question2weighted.png --delay=100 --min-height=0
	cutycapt --url=http://localhost:9000/question2byPolitics.html --out=html/images/question2byPolitics.png --delay=100 --min-height=0
	cutycapt --url=http://localhost:9000/question2byReferendumVote.html --out=html/images/question2byReferendumVote.png --delay=100 --min-height=0
	
	cutycapt --url=http://localhost:9000/detail.html --out=html/images/EUReferendumDataAnalysis.pdf --out-format=pdf --delay=100 --min-height=0
	
	cutycapt --url=http://localhost:9000/changeInAbsoluteVote2016.html --out=html/images/changeInAbsoluteVote2016.png --delay=100 --min-height=0
	cutycapt --url=http://localhost:9000/impactOnParliament2016.html --out=html/images/impactOnParliament2016.png --delay=100 --min-height=0
	cutycapt --url=http://localhost:9000/predictedToLose.html --out=html/images/predictedToLose.png --delay=100 --min-height=0
	
done

wait $bg_pid