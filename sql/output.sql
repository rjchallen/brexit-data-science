USE brexit_data_science;

/*
DROP FUNCTION IF EXISTS percent;

CREATE FUNCTION percent(sample INTEGER, size INTEGER)
RETURNS FLOAT DETERMINISTIC
RETURN sample/size*100;

DROP FUNCTION IF EXISTS confidence;

CREATE FUNCTION confidence(sample INTEGER, size INTEGER)
RETURNS FLOAT DETERMINISTIC
RETURN 1.96*(POW((sample/size)*(1-sample/size)/size,0.5)+0.5/size)*100;


Select 
	'q2Answer',
	'unweighted',
	'unweighted_percent',
	'confidence_unweighted_percent',
	'demographic_weighted_percent',
	'confidence_demographic_weighted_percent',
	'combined_weighted_percent',
	'confidence_combined_weighted_percent' 
union
Select 
	p.q2_label,
	COUNT(*) as unweighted,
	percent(COUNT(*),q.total) as unweighted_percent,
	confidence(COUNT(*),q.total) as confidence_unweighted_percent,
	percent(SUM(p.demographic_weight),q.demographic_total) as demographic_weighted_percent,
	confidence(SUM(p.demographic_weight),q.demographic_total) as confidence_demographic_weighted_percent,
	percent(SUM(p.combined_weight),q.combined_total) as combined_weighted_percent,
	confidence(SUM(p.combined_weight),q.combined_total) as confidence_combined_weighted_percent
From 
	weighted_yougov_poll p,
	( SELECT COUNT(*) as total, SUM(r.demographic_weight) as demographic_total, SUM(r.combined_weight) as combined_total FROM weighted_yougov_poll r) q
GROUP BY p.q2
/*INTO OUTFILE '/tmp/question2.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
;

Select 'referendum','q2Answer','unweighted','unweighted_percent','demographic_weighted_percent','combined_weighted_percent' union
Select 
	p.pastvote_euref_label,
	p.q2_label,
	COUNT(*) as unweighted,
	COUNT(*)/q.total*100 as unweighted_percent,
	SUM(p.demographic_weight)/q.demographic_total*100 as demographic_weighted_percent,
	SUM(p.combined_weight)/q.combined_total*100 as combined_weighted_percent
From 
	weighted_yougov_poll p,
	( SELECT r.pastvote_euref, COUNT(*) as total, SUM(r.demographic_weight) as demographic_total, SUM(r.combined_weight) as combined_total FROM weighted_yougov_poll r group BY r.pastvote_euref) q
where
	p.pastvote_euref=q.pastvote_euref
GROUP BY p.pastvote_euref, p.q2
INTO OUTFILE '/tmp/question2byEUref.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
;

Select 'vote2015r_label','q2Answer','unweighted','unweighted_percent','demographic_weighted_percent','combined_weighted_percent' union
Select 
	p.vote2015r_label,
	p.q2_label,
	COUNT(*) as unweighted,
	COUNT(*)/q.total*100 as unweighted_percent,
	SUM(p.demographic_weight)/q.demographic_total*100 as demographic_weighted_percent,
	SUM(p.combined_weight)/q.combined_total*100 as combined_weighted_percent
From 
	weighted_yougov_poll p,
	( SELECT r.vote2015r, COUNT(*) as total, SUM(r.demographic_weight) as demographic_total, SUM(r.combined_weight) as combined_total FROM weighted_yougov_poll r group BY r.vote2015r) q
where
	p.vote2015r=q.vote2015r
GROUP BY p.vote2015r, p.q2
INTO OUTFILE '/tmp/question2byVote2015.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
;

Select 'q1Answer','unweighted','unweighted_percent','demographic_weighted_percent','combined_weighted_percent' union
Select 
	p.q1_label,
	COUNT(*) as unweighted,
	COUNT(*)/q.total*100 as unweighted_percent,
	SUM(p.demographic_weight)/q.demographic_total*100 as demographic_weighted_percent,
	SUM(p.combined_weight)/q.combined_total*100 as combined_weighted_percent
From 
	weighted_yougov_poll p,
	( SELECT COUNT(*) as total, SUM(r.demographic_weight) as demographic_total, SUM(r.combined_weight) as combined_total FROM weighted_yougov_poll r) q
GROUP BY p.q1
INTO OUTFILE '/tmp/question1.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';
;*/

DROP VIEW IF EXISTS weight_totals_by_politics;

CREATE VIEW weight_totals_by_politics AS
SELECT r.vote2015r, COUNT(*) as total, SUM(r.demographic_weight) as demographic_total, SUM(r.combined_weight) as combined_total FROM weighted_yougov_poll r group BY r.vote2015r;

DROP VIEW IF EXISTS question1_by_politics;

CREATE VIEW question1_by_politics as
Select 
	p.vote2015r_label,
	p.q1_label,
	COUNT(*) as unweighted,
	percent(SUM(p.combined_weight),q.combined_total) as weighted_percent,
	confidence(SUM(p.combined_weight),q.combined_total) as weighted_confidence
From 
	weighted_yougov_poll p,
	weight_totals_by_politics q
where
	p.vote2015r=q.vote2015r
GROUP BY p.vote2015r, p.q1
;