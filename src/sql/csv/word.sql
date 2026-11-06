select
    sent.string as chunk,
    word.idx,
    word.len,
    dep.name as dep,
    lexeme.lemma,
    has_synset.synset
from
    word
    join dep on dep.id = word.dep
    join lexeme on lexeme.id = word.lexeme
    join sent on word.sent = sent.id
    join string on string.id = sent.string
    join lemma on lemma.id = lexeme.lemma
    join pos on pos.id = lemma.pos
    left join has_synset on has_synset.lemma = lemma.id
where
    pos.name in ('adj', 'verb', 'noun')
