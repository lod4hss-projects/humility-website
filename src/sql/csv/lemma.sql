select
    lemma.id,
    lemma.lemma,
    pos.name as pos,
    synset.id as synset,
    unnest(synset.hypernym_paths) as hypernym_path
from
    lemma
    join pos on pos.id = lemma.pos
    left join has_synset on has_synset.lemma = lemma.id
    left join synset on synset.id = has_synset.synset
where
    pos.name in ('adj', 'verb', 'noun')
