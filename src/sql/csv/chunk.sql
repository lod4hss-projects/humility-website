select
    passage_uri,
    text_id as id,
    'text' as property,
    type,
    text
from
    chunk_
union
select
    passage_uri,
    idea_id as id,
    'idea' as property,
    type,
    idea as text
from
    chunk_;
