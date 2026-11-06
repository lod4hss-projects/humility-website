select
    json_array (
        select
            json_array (synset.id, synset.label, synset.definition, synset.lemmas, synset.examples, unnest(synset.hypernym_paths))
        from synset
        where
            'entity' @> hypernym_paths)
