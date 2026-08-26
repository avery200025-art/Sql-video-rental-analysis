/*
================================================================================
SQL BUSINESS ANALYSIS PROJECT — Video Rental Revenue & Inventory Optimization
Database: Sakila / Maven Movies (MySQL)

OVERVIEW BUSINESS PROBLEM:
Which film categories and store locations should the company prioritize for
inventory investment and marketing to maximize rental revenue, and where are
we losing money on underused inventory or at-risk customers?

NOTE: This project uses the Sakila sample database (a fictional DVD rental
company) to demonstrate SQL and BI analysis skills. The business problem,
questions, and dataset are for portfolio purposes -- not live company data --
but the analytical approach (identifying revenue drivers, segmenting
customers, spotting underperforming assets, and translating findings into a
recommendation) mirrors real reporting and analysis work.
================================================================================
*/


/*
1. I want to understand our monthly rental revenue over time.
Please pull together the year, the month, and the total revenue collected
for each month, so I can see if revenue is growing or seasonal.
*/

SELECT
	YEAR(rental.rental_date) AS rental_year,
	MONTH(rental.rental_date) AS rental_month,
	SUM(payment.amount) AS total_revenue

FROM rental
	INNER JOIN payment
		ON payment.rental_id = rental.rental_id

GROUP BY
	YEAR(rental.rental_date),
	MONTH(rental.rental_date)

ORDER BY
	rental_year,
	rental_month
;

/*
FINDING: Revenue rose sharply from May through August 2005, peaking at
$28,369 in July, then drops off sharply after that point.

SO WHAT: The dataset appears to end in early 2006, so this isn't a real
decline -- it's limited because of the sample. In a live business
setting, this  month-over-month swing would be worth investigating
for seasonality (summer demand,etc) before drawing conclusions.
*/


/*
2. I'd like to know how our two store locations compare.
Please pull together each store's ID, along with the total number of rentals
and total revenue generated at that store.
*/

SELECT
	inventory.store_id,
	COUNT(rental.rental_id) AS count_of_rentals,
	SUM(payment.amount) AS payment_total

FROM rental
	INNER JOIN payment
		ON rental.rental_id = payment.rental_id
	INNER JOIN inventory
		ON inventory.inventory_id = rental.inventory_id

GROUP BY
	inventory.store_id

ORDER BY
	payment_total DESC
;

/*
FINDING: The two stores perform almost identically -- Store 2 had 8,121
rentals and $33,726.77 in revenue, while Store 1 had 7,923 rentals and
$33,679.79 in revenue, a gap of less than 3%.

SO WHAT: Neither location is underperforming enough to justify shifting
investment or attention away from it. In a real business setting, I'd
want to layer in cost and staffing data before calling the two locations
equally efficient -- matching revenue doesn't necessarily mean matching
profitability.
*/


/*
3. I want to understand which of our customers are most valuable,
and which ones haven't rented from us in a while.
Please pull together each customer's ID, name, total amount spent,
their most recent rental date, and a label showing whether they're
"Active" or "At Risk" based on that most recent rental date.
*/

SELECT
	customer.customer_id,
	customer.first_name,
	customer.last_name,
	SUM(payment.amount) AS total_amount_spent,
	MAX(rental.rental_date) AS latest_rental_date,
	CASE
		WHEN MAX(rental.rental_date) < '2005-11-01' THEN 'At Risk'
		ELSE 'Active'
	END AS customer_status

FROM customer
	INNER JOIN payment
		ON payment.customer_id = customer.customer_id
	INNER JOIN rental
		ON rental.rental_id = payment.rental_id

GROUP BY
	customer.customer_id,
	customer.first_name,
	customer.last_name

ORDER BY
	total_amount_spent DESC,
	latest_rental_date DESC
;

/*
FINDING: Among the highest-spending customers, the large majority are
flagged "At Risk" rather than "Active" -- top spenders like Karl Seal
($221.55) and Eleanor Hunt ($216.54) haven't rented since August 2005.
Nearly all customers labeled "Active" share the exact same rental
timestamp, 2006-02-14 15:16:03 -- the very last date in the dataset --
with almost no activity recorded in the months before it.

SO WHAT: The real takeaway here is that a lot of our best customers have
gone quiet. It's worth a win-back push since they've already shown they'll spend.
 Worth flagging though: that cluster of "Active" customers all landing on the exact same day is probably just
this being a sample dataset, not an actual trend.
*/


/*
4. I'd like to see how long customers typically keep their rentals,
and how often they return items late.
Please pull together each rental's ID, the customer ID, the rental date,
the return date, and a label showing whether the rental was "Late" or "On Time."
*/

SELECT
	rental_duration,
	return_status,
	COUNT(*) AS total_rentals
FROM (
	SELECT
		film.rental_duration,
		CASE
			WHEN DATEDIFF(rental.return_date, rental.rental_date) > film.rental_duration THEN 'Late'
			ELSE 'On Time'
		END AS return_status
	FROM rental
		INNER JOIN inventory ON inventory.inventory_id = rental.inventory_id
		INNER JOIN film ON film.film_id = inventory.film_id
) AS sub
GROUP BY rental_duration, return_status
ORDER BY rental_duration, return_status;

/*
FINDING: Late-return rates fall steadily as the allowed rental duration
increases -- roughly 66% of 3-day rentals come back late, dropping to
about 56% for 4-day, 44% for 5-day, 34% for 6-day, and just 23% for
7-day rentals.

SO WHAT: Shorter rental windows are contributing to  customers 
being late. Worth reconsidering whether 3-day rentals make sense as a
default for certain titles, since two-thirds of them end up late
anyway -- extending the standard window or adding a grace period could
cut down on late fees and friction without losing much turnover.
*/


/*
5. I want to find inventory we're paying to store but that has never
generated any revenue.
Please pull together a list of film titles in our inventory that have
never been rented.
*/

SELECT
	film.title,
	COUNT(rental.rental_id) AS total_rentals

FROM film
	INNER JOIN inventory
		ON film.film_id = inventory.film_id
	LEFT JOIN rental
		ON inventory.inventory_id = rental.inventory_id

GROUP BY film.title

HAVING COUNT(rental.rental_id) = 0
;

/*
FINDING: Every single film title in the catalog has been rented at
least once -- when checking total rentals across all copies of each
title (not just individual copies), zero titles come back with a
rental count of 0.

SO WHAT: Dead inventory isn't really an issue here -- nothing needs to
be pulled or discontinued at the title level. 
*/


/*
6. I'd like to understand which film categories we've dedicated the most
inventory to, and how many rentals each category is generating.
Please pull together each category name, the count of inventory items in
that category, and the count of rentals for that category.
*/

SELECT
	category.name AS category_name,
	COUNT(DISTINCT inventory.inventory_id) AS inventory_count,
	COUNT(rental.rental_id) AS rental_count

FROM category
	INNER JOIN film_category
		ON film_category.category_id = category.category_id
	INNER JOIN film
		ON film.film_id = film_category.film_id
	INNER JOIN inventory
		ON inventory.film_id = film.film_id
	INNER JOIN rental
		ON rental.inventory_id = inventory.inventory_id

GROUP BY
	category.name
;

/*
FINDING: Rental activity scales roughly proportionally with inventory
across categories -- most sit in a fairly tight range of about 3 to 3.6
rentals per inventory item. Music stands out with the highest ratio
(3.58) despite having one of the smallest inventory footprints, while
Sports and Animation lead in raw volume with similarly solid ratios
around 3.4-3.5.

SO WHAT: Nothing here points to a category being drastically over- or
under-stocked relative to demand -- current inventory allocation looks
broadly sensible. If there's a small opportunity, then Music. It's
existing copies are working harder than most, so increasing some inventory
could be worth testing rather than any category needing
a cutback.
*/


/*
7. I want to know which categories are performing above our average
revenue-per-rental across all categories.
Please pull together each category name and its revenue per rental,
limited to only the categories performing above the overall average.
*/

SELECT
	category.name AS category_name,
	COUNT(rental.rental_id) AS total_rentals,
	SUM(payment.amount) AS total_revenue,
	SUM(payment.amount) / COUNT(rental.rental_id) AS revenue_per_rental

FROM category
	INNER JOIN film_category
		ON film_category.category_id = category.category_id
	INNER JOIN film
		ON film.film_id = film_category.film_id
	INNER JOIN inventory
		ON inventory.film_id = film.film_id
	INNER JOIN rental
		ON rental.inventory_id = inventory.inventory_id
	INNER JOIN payment
		ON payment.rental_id = rental.rental_id

GROUP BY
	category.name

HAVING
	SUM(payment.amount) / COUNT(rental.rental_id) > 4.20

ORDER BY
	revenue_per_rental DESC
;

/*
FINDING: Eight of our sixteen categories are pulling in more than the
average $4.20 per rental. Comedy leads at $4.66, followed by New
Releases at $4.63 and Games at $4.42. Meanwhile a couple of our
highest-volume categories, like Action and Family, actually fall
below average once you look at revenue per rental instead of just
total rentals.

SO WHAT: Just because a category rents a lot doesn't mean it's making
the most money per transaction. Comedy and New Releases are making top revenue.
Action might be worth a second look too, since it's popular but
underperforming on a per-rental basis -- could be a pricing thing
worth testing.
*/


/*
8. I want a quick list of our top 10 most-rented films overall,
along with which category each one belongs to.
Please pull together the film title, category name, and total rental count.
*/

SELECT
	film.title,
	category.name AS category_name,
	COUNT(rental.rental_id) AS total_rentals

FROM film
	INNER JOIN film_category
		ON film_category.film_id = film.film_id
	INNER JOIN category
		ON category.category_id = film_category.category_id
	INNER JOIN inventory
		ON inventory.film_id = film.film_id
	INNER JOIN rental
		ON rental.inventory_id = inventory.inventory_id

GROUP BY
	film.title,
	category.name

ORDER BY
	total_rentals DESC

LIMIT 10
;

/*
FINDING: Bucket Brotherhood (Travel) is the single most-rented film at
34 rentals, but the full top 10 list is spread across 9 different
categories, all clustered tightly between 31 and 34 rentals -- no one
title or category dominates rental activity.

SO WHAT: Individual film popularity doesn't line up neatly with the
highest-earning categories from question 7 (Comedy, New, Games). Category attention 
matters more here than any one blockbuster title, which
backs up focusing marketing and inventory decisions on category
performance rather than individual hits.
*/
/*

CONCLUSION — Answering the Overview Business Problem

Which film categories and store locations should the company prioritize for
inventory investment and marketing, and where is money being lost on
underused inventory or at-risk customers?

- Invest in Comedy, New Releases, and Games: these categories earn above-
  average revenue per rental ($4.20+), making them more profitable per
  transaction than high-volume categories like Action, which underperforms
  on a per-rental basis despite strong rental counts.
- Store 1 and Store 2 perform almost identically, so there's no location-
  based case for shifting investment between them based on revenue alone.
- Dead inventory isn't a real issue -- every title in the catalog has been
  rented at least once. The bigger opportunity is a targeted win-back
  campaign: a large share of the highest-spending customers have gone
  quiet, and they've already proven willingness to spend.
- Shorter rental windows (3-4 days) show meaningfully higher late-return
  rates than longer ones, suggesting rental duration policy is worth
  revisiting alongside any inventory or marketing changes.

Bottom line: the clearest wins are prioritizing Comedy/New/Games in
marketing spend and launching a win-back campaign for lapsed high-value
customers.

*/
