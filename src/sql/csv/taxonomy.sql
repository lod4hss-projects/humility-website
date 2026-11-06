select distinct
    unnest(synset.hypernym_paths) as path
from
    word_ w
    join chunk_ c on w.string = c.text_id
    join has_synset on has_synset.lemma = w.lemma_id
    join synset on synset.id = has_synset.synset
where
    w.pos = 'noun'
order by
    path;
