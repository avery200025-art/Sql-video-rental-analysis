/*
===============================================================================
  POWER BI SOURCE TABLE EXPORTS
  Sakila / Maven Movies database

  These four queries produce the raw tables behind the Power BI star schema.
  Run each one, then export the RESULT GRID to CSV (the export button above the
  results panel -- not File > Save As, which saves the query text instead).

  IMPORTANT: MySQL Workbench limits results to 1,000 rows by default, which
  silently truncates fact_rentals to 6% of its real size. Either raise the limit
  under Edit > Preferences > SQL Execution, or rely on the LIMIT clause below.
===============================================================================
*/


/* -----------------------------------------------------------------------------
   1. fact_rentals  -- the fact table (16,044 rows)

   One row per rental. Carries the foreign keys out to each dimension plus the
   single additive measure, amount.

   inventory is joined in only to reach film_id and store_id -- a rental points
   at a physical copy, and the copy is what knows which film it is and which
   store holds it.

   payment is a LEFT JOIN so that rentals with no matching payment still appear
   as rows rather than being dropped from the fact table.
----------------------------------------------------------------------------- */
SELECT
    rental.rental_id,
    rental.rental_date,
    rental.return_date,
    rental.customer_id,
    inventory.film_id,
    inventory.store_id,
    payment.amount
FROM rental
    INNER JOIN inventory ON inventory.inventory_id = rental.inventory_id
    LEFT  JOIN payment   ON payment.rental_id      = rental.rental_id
LIMIT 100000;


/* -----------------------------------------------------------------------------
   2. dim_film  -- film dimension (1,000 rows)

   Category is denormalized into this table rather than kept as its own
   dimension. Sakila stores it across film_category and category, which would
   make the model a snowflake; flattening it here keeps a clean star.
----------------------------------------------------------------------------- */
SELECT
    film.film_id,
    film.title,
    category.name AS category,
    film.rental_duration,
    film.rental_rate,
    film.length,
    film.rating,
    film.replacement_cost
FROM film
    INNER JOIN film_category ON film_category.film_id     = film.film_id
    INNER JOIN category      ON category.category_id      = film_category.category_id;


/* -----------------------------------------------------------------------------
   3. dim_customer  -- customer dimension (599 rows)
----------------------------------------------------------------------------- */
SELECT
    customer_id,
    first_name,
    last_name,
    store_id,
    active
FROM customer;


/* -----------------------------------------------------------------------------
   4. dim_store  -- store dimension (2 rows)

   Location lives three tables away from store in Sakila
   (store > address > city > country), so all three are joined to produce a
   single flat row per store.
----------------------------------------------------------------------------- */
SELECT
    store.store_id,
    city.city,
    country.country
FROM store
    INNER JOIN address ON address.address_id = store.address_id
    INNER JOIN city    ON city.city_id       = address.city_id
    INNER JOIN country ON country.country_id = city.country_id;


/*
===============================================================================
  AFTER LOADING INTO POWER BI

  Relationships -- all one-to-many, dimension to fact, single cross-filter
  direction:

      dim_customer[customer_id]  ->  fact_rentals[customer_id]
      dim_film[film_id]          ->  fact_rentals[film_id]
      dim_store[store_id]        ->  fact_rentals[store_id]
      dim_date[Date]             ->  fact_rentals[Rental Date]

  dim_date is a calculated table created in DAX, not exported here:

      dim_date =
      ADDCOLUMNS(
          CALENDAR(DATE(2005,1,1), DATE(2006,12,31)),
          "Year",            YEAR([Date]),
          "Month Number",    MONTH([Date]),
          "Month Name",      FORMAT([Date], "MMM"),
          "Month Year",      FORMAT([Date], "MMM YYYY"),
          "Month Year Sort", YEAR([Date]) * 100 + MONTH([Date])
      )

  fact_rentals[rental_date] includes a time component, so a date-only
  calculated column is added for the relationship:

      Rental Date =
      DATE(
          YEAR(fact_rentals[rental_date]),
          MONTH(fact_rentals[rental_date]),
          DAY(fact_rentals[rental_date])
      )
===============================================================================
*/
