USE brexit_data_science;

DROP FUNCTION IF EXISTS percent;

CREATE FUNCTION percent(sample INTEGER, size INTEGER)
RETURNS FLOAT DETERMINISTIC
RETURN sample/size*100;

DROP FUNCTION IF EXISTS confidence;

CREATE FUNCTION confidence(sample INTEGER, size INTEGER)
RETURNS FLOAT DETERMINISTIC
RETURN 1.96*(POW((sample/size)*(1-sample/size)/size,0.5)+0.5/size)*100;

-- Roll up counts

DROP VIEW IF EXISTS sample;
CREATE VIEW sample AS
SELECT 
	COUNT(*) as total,
	SUM(r.demographic_weight) as demographic_total, 
	SUM(r.combined_weight) as combined_total, 
	SUM(r.yougov_weight) as yougov_total  
from weighted_yougov_poll r;

DROP VIEW IF EXISTS weight_totals_by_politics;
CREATE VIEW weight_totals_by_politics AS
SELECT 
	r.vote2015r, 
	COUNT(*) as total, 
	SUM(r.demographic_weight) as demographic_total, 
	SUM(r.combined_weight) as combined_total, 
	SUM(r.yougov_weight) as yougov_total 
FROM weighted_yougov_poll r 
group BY r.vote2015r;

DROP VIEW IF EXISTS weight_totals_by_referendum_vote;
CREATE VIEW weight_totals_by_referendum_vote AS
SELECT 
	r.pastvote_euref, 
	COUNT(*) as total, 
	SUM(r.demographic_weight) as demographic_total, 
	SUM(r.combined_weight) as combined_total, 
	SUM(r.yougov_weight) as yougov_total 
FROM weighted_yougov_poll r 
group BY r.pastvote_euref;

-- Export views

DROP VIEW IF EXISTS question1_summary;
CREATE VIEW question1_summary as
Select 
	p.q1,
	p.q1_label,
	COUNT(*) as unweighted,
	percent(COUNT(*),q.total) as percent,
	confidence(COUNT(*),q.total) as confidence,
	percent(SUM(p.combined_weight),q.combined_total) as combined_percent,
	confidence(SUM(p.combined_weight),q.combined_total) as combined_confidence,
	percent(SUM(p.yougov_weight),q.yougov_total) as weighted_percent,
	confidence(SUM(p.yougov_weight),q.yougov_total) as weighted_confidence
From 
	weighted_yougov_poll p,
	sample q
GROUP BY p.q1
;

DROP VIEW IF EXISTS question1_by_politics;
CREATE VIEW question1_by_politics as
Select 
	p.vote2015r_label,
	p.q1,
	p.q1_label,
	COUNT(*) as unweighted,
	percent(SUM(p.yougov_weight),q.yougov_total) as weighted_percent,
	confidence(SUM(p.yougov_weight),q.yougov_total) as weighted_confidence
--	percent(SUM(p.combined_weight),q.combined_total) as weighted_percent,
--	confidence(SUM(p.combined_weight),q.combined_total) as weighted_confidence
From 
	weighted_yougov_poll p,
	weight_totals_by_politics q
where
	p.vote2015r=q.vote2015r
GROUP BY p.vote2015r, p.q1
;

DROP VIEW IF EXISTS question2_summary;
CREATE VIEW question2_summary as
Select 
	p.q2,
	p.q2_label,
	COUNT(*) as unweighted,
	percent(COUNT(*),q.total) as percent,
	confidence(COUNT(*),q.total) as confidence,
	percent(SUM(p.combined_weight),q.combined_total) as combined_percent,
	confidence(SUM(p.combined_weight),q.combined_total) as combined_confidence,
	percent(SUM(p.yougov_weight),q.yougov_total) as weighted_percent,
	confidence(SUM(p.yougov_weight),q.yougov_total) as weighted_confidence
From 
	weighted_yougov_poll p,
	sample q
GROUP BY p.q2
;

DROP VIEW IF EXISTS question2_by_politics;
CREATE VIEW question2_by_politics as
Select 
	p.vote2015r_label,
	p.q2,
	p.q2_label,
	COUNT(*) as unweighted,
	percent(SUM(p.combined_weight),q.combined_total) as weighted_percent,
	confidence(SUM(p.combined_weight),q.combined_total) as weighted_confidence
From 
	weighted_yougov_poll p,
	weight_totals_by_politics q
where
	p.vote2015r=q.vote2015r
GROUP BY p.vote2015r, p.q2
;

DROP VIEW IF EXISTS question2_by_referendum_vote;
CREATE VIEW question2_by_referendum_vote as
Select 
	p.pastvote_euref_label,
	p.q2,
	p.q2_label,
	COUNT(*) as unweighted,
	percent(SUM(p.combined_weight),q.combined_total) as weighted_percent,
	confidence(SUM(p.combined_weight),q.combined_total) as weighted_confidence
From 
	weighted_yougov_poll p,
	weight_totals_by_referendum_vote q
where
	p.pastvote_euref=q.pastvote_euref
GROUP BY p.pastvote_euref, p.q2
;

DROP VIEW IF EXISTS top_20_brexit_candidates_predicted_to_lose;
CREATE VIEW top_20_brexit_candidates_predicted_to_lose AS
SELECT * FROM brexit_candidates_predicted_to_lose LIMIT 20;