with w1 as (
    select
        string,
        i,
        regexp_replace(s, '[<>&\\]', '', 'g') as s,
        case when pos in ('adj', 'noun', 'verb') then
            regexp_replace(lemma, '["<>&\\]', '')
        else
            null
        end as lemma,
        case when tspace = 1 then
            ' '
        else
            ''
        end as space
    from
        token_
),
w2 as (
    select
        string,
        i,
        case when lemma is null then
            concat(s, space)
        when lemma = s then
            format('<a>%s</a>%s', s, space)
        else
            format('<a data-lemma="%s">%s</a>%s', lemma, s, space)
        end as word
    from
        w1
),
s as (
    select
        string,
        string_agg(word, '' order by i) as tokens
from
    w2
group by
    string
)
select
    c.passage_uri,
    c.type,
    s1.tokens::xml::text as text,
    s2.tokens::xml::text as idea
from
    chunk_ c
    join s s1 on s1.string = c.text_id
    join s s2 on s2.string = c.idea_id
order by
    c.passage_uri;
