select
    passage_uri,
    text_id as id,
    'text' as type,
    text
from
    chunk_
union
select
    passage_uri,
    concept_id as id,
    'idea' as type,
    concept as text
from
    chunk_;
