-- Define the years as variables
DECLARE @previous_year INT = 2020;
DECLARE @current_year INT = 2021;

-- This query inserts actor data into the actors table.
-- It merges actors' data from the previous year with the current year's data.
-- The query combines film details, updates the quality class, and marks active actors based on the current year's film data.

INSERT INTO actors
-- Actors from the last year
WITH previous_year_actors AS (
  SELECT * FROM actors
  WHERE current_year = @previous_year
),
-- Actors from the current year
current_year_actors AS (
  SELECT 
    actor,
    actor_id,
    ARRAY_AGG(
      ROW(
        film,
        votes,
        rating,
        film_id
      )
    ) AS films,
    -- Calculate quality_class
    CASE 
      WHEN AVG(rating) > 8 THEN 'star'
      WHEN AVG(rating) > 7 AND AVG(rating) <= 8 THEN 'good'
      WHEN AVG(rating) > 6 AND AVG(rating) <= 7 THEN 'average'
      WHEN AVG(rating) <= 6 THEN 'bad'
    END AS quality_class,
    max(year) as year
  FROM actor_films 
  WHERE year = @current_year
  GROUP BY actor, actor_id
)
SELECT 
  COALESCE(pya.actor, cya.actor) AS actor,
  COALESCE(pya.actor_id, cya.actor_id) AS actor_id,
  CASE
    WHEN cya.films IS NULL THEN pya.films
    WHEN cya.films IS NOT NULL AND pya.films IS NULL THEN cya.films
    WHEN cya.films IS NOT NULL AND pya.films IS NOT NULL THEN pya.films || cya.films
  END AS films,
  CASE 
    WHEN cya.quality_class IS NULL THEN pya.quality_class 
    ELSE cya.quality_class
  END AS quality_class,
  CASE 
    WHEN cya.year IS NOT NULL THEN TRUE 
    ELSE FALSE 
  END AS is_active,
  COALESCE(cya.year, pya.current_year + 1) AS current_year
FROM previous_year_actors pya 
-- FULL JOIN to catch all the details from the past and current year using COALESCE
FULL OUTER JOIN current_year_actors cya
ON pya.actor_id = cya.actor_id
