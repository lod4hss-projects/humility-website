--
-- PostgreSQL database dump
--

\restrict mWhDgkpy5gmUXigSobONjPu9BlCDmJBEl0OoogBrLf6fQ4pS5O1YCq5nHoJw3GH

-- Dumped from database version 17.11 (Debian 17.11-0+deb13u1)
-- Dumped by pg_dump version 17.11 (Debian 17.11-0+deb13u1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: hum; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA hum;


--
-- Name: nlpg; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA nlpg;


--
-- Name: ltree; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS ltree WITH SCHEMA nlpg;


--
-- Name: _get_config(text); Type: FUNCTION; Schema: nlpg; Owner: -
--

CREATE FUNCTION nlpg._get_config(key text) RETURNS text
    LANGUAGE sql
    AS $_$
    select
        value
    from
        nlpg._config
    where
        key = $1;
$_$;


--
-- Name: _set_config(text, text); Type: FUNCTION; Schema: nlpg; Owner: -
--

CREATE FUNCTION nlpg._set_config(key text, value text) RETURNS void
    LANGUAGE sql
    AS $_$
    delete from nlpg._config
    where key = $1;
    insert into nlpg._config (
        key,
        value)
    select
        $1,
        $2;
$_$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: dep; Type: TABLE; Schema: nlpg; Owner: -
--

CREATE TABLE nlpg.dep (
    id smallint NOT NULL,
    name text NOT NULL,
    definition text
);


--
-- Name: lemma; Type: TABLE; Schema: nlpg; Owner: -
--

CREATE TABLE nlpg.lemma (
    id integer NOT NULL,
    lemma text NOT NULL,
    pos smallint NOT NULL,
    stem text
);


--
-- Name: lexeme; Type: TABLE; Schema: nlpg; Owner: -
--

CREATE TABLE nlpg.lexeme (
    id integer NOT NULL,
    lemma integer NOT NULL,
    morph smallint NOT NULL,
    norm text NOT NULL
);


--
-- Name: morph; Type: TABLE; Schema: nlpg; Owner: -
--

CREATE TABLE nlpg.morph (
    id smallint NOT NULL,
    feats text,
    j jsonb,
    numtype text,
    number text,
    person text,
    prontype text,
    mood text,
    tense text,
    definite text,
    verbform text,
    voice text,
    reflex text,
    polarity text,
    number_psor text,
    poss text
);


--
-- Name: pos; Type: TABLE; Schema: nlpg; Owner: -
--

CREATE TABLE nlpg.pos (
    id smallint NOT NULL,
    name text NOT NULL,
    definition text
);


--
-- Name: sent; Type: TABLE; Schema: nlpg; Owner: -
--

CREATE TABLE nlpg.sent (
    string bigint NOT NULL,
    i integer NOT NULL,
    id integer NOT NULL
);


--
-- Name: token; Type: TABLE; Schema: nlpg; Owner: -
--

CREATE TABLE nlpg.token (
    sent integer NOT NULL,
    i integer NOT NULL,
    idx integer NOT NULL,
    len smallint NOT NULL,
    s text NOT NULL,
    tspace smallint NOT NULL
);


--
-- Name: word; Type: TABLE; Schema: nlpg; Owner: -
--

CREATE TABLE nlpg.word (
    dep smallint NOT NULL,
    lexeme integer NOT NULL,
    head integer NOT NULL
)
INHERITS (nlpg.token);


--
-- Name: word_; Type: VIEW; Schema: nlpg; Owner: -
--

CREATE VIEW nlpg.word_ AS
 SELECT sent.string,
    sent.id AS sent,
    word.i,
    word.s,
    word.tspace,
    word.idx,
    word.len,
    lexeme.norm,
    lemma.lemma,
    lemma.stem,
    pos.name AS pos,
    word.head,
    dep.name AS dep,
    lemma.id AS lemma_id,
    morph.tense,
    morph.polarity,
    morph.verbform,
    morph.mood,
    morph.definite,
    morph.poss,
    morph.numtype,
    morph.number_psor,
    morph.prontype,
    morph.voice,
    morph.number,
    morph.person,
    morph.reflex
   FROM ((((((nlpg.word
     JOIN nlpg.sent ON ((sent.id = word.sent)))
     JOIN nlpg.lexeme ON ((lexeme.id = word.lexeme)))
     JOIN nlpg.lemma ON ((lemma.id = lexeme.lemma)))
     JOIN nlpg.pos ON ((pos.id = lemma.pos)))
     JOIN nlpg.dep ON ((dep.id = word.dep)))
     JOIN nlpg.morph ON ((morph.id = lexeme.morph)));


--
-- Name: align_concordance(nlpg.word_, integer, integer); Type: FUNCTION; Schema: nlpg; Owner: -
--

CREATE FUNCTION nlpg.align_concordance(nlpg.word_, integer DEFAULT 100, integer DEFAULT 50) RETURNS text
    LANGUAGE sql
    AS $_$
SELECT
    substring(regexp_replace(
        CASE WHEN $1.idx < $3 THEN
            lpad('', ($3 + 1) - $1.idx, ' ') || string.val
        ELSE
            string.val
        END, '[\n\t]', ' ', 'g'),
        greatest ($1.idx - $3, 1),
        $2
    )
FROM
    string
WHERE
    $1.string = string.id
$_$;


--
-- Name: concordance(text, integer, integer); Type: FUNCTION; Schema: nlpg; Owner: -
--

CREATE FUNCTION nlpg.concordance(text, integer DEFAULT 100, integer DEFAULT 50) RETURNS TABLE(string_id integer, context text)
    LANGUAGE sql
    AS $_$
SELECT
    w.string, "nlpg"."align_concordance" (w, $2, $3)
    FROM word_ w WHERE lemma = $1
$_$;


--
-- Name: feats_to_json(); Type: FUNCTION; Schema: nlpg; Owner: -
--

CREATE FUNCTION nlpg.feats_to_json() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    update
        morph
    set
        j = case when feats != '' then
            jsonb_object(regexp_split_to_array(feats, '\||='))
        else
            '{}'::jsonb
        end
    where
        id = new.id;
    return new;
end;
$$;


--
-- Name: has_head(nlpg.word); Type: FUNCTION; Schema: nlpg; Owner: -
--

CREATE FUNCTION nlpg.has_head(nlpg.word) RETURNS nlpg.word
    LANGUAGE sql
    AS $_$
    select
        m2
    from
        word m2
        join lexeme x2 on m2.lexeme = x2.id
        join lexeme x1 on $1.lexeme = x1.id
    where
        $1.string = m2.string
        and $1.head = m2.i
$_$;


--
-- Name: insert_annotations(integer); Type: FUNCTION; Schema: nlpg; Owner: -
--

CREATE FUNCTION nlpg.insert_annotations(integer DEFAULT 1) RETURNS void
    LANGUAGE plpgsql
    AS $_$
begin
    /* lemmas */
    raise info 'Inserting lemmas.';
    insert into lemma (
        lemma,
        pos)
    select distinct
        lemma,
        pos
    from
        _textobj
    where
        type = 1
    except
    select distinct
        lemma,
        pos
    from
        lemma;

    /* Morphologies */
    raise info 'Inserting morphologies.';
    insert into morph (
        feats)
    select distinct
        i.morph
    from
        _textobj i
    where
        type = 1
    except
    select distinct
        feats
    from
        nlpg.morph;

    /* Lexemes */
    raise info 'Inserting lexemes.';
    insert into lexeme (
        norm,
        lemma,
        morph)
    select distinct
        i.norm,
        l.id,
        m.id
    from
        _textobj i
        join lemma l on l.lemma = i.lemma
        join morph m on m.feats = i.morph
    where
        i.type = 1
    except
    select distinct
        x.norm,
        x.lemma,
        x.morph
    from
        lexeme x;

    /* Sentences */
    raise info 'Inserting sentences.';
    insert into sent (
        string,
        i)
    select
        i.text_id,
        i.sent_i
    from
        _textobj i
    where
        i.type = -1;

    /* Update indexes */
    raise info 'Updating indexes.';
    analyze sent;
    analyze lemma;
    analyze lexeme;
    analyze _textobj;

    /* Words */
    raise info 'Inserting words.';
    insert into word (
        sent,
        i,
        idx,
        len,
        s,
        tspace,
        dep,
        lexeme,
        head)
    select
        s.id,
        i.i,
        i.idx,
        i.len,
        i.s,
        i.tspace,
        i.dep,
        x.id,
        i.head
    from
        _textobj i
        join lemma l on l.lemma = i.lemma
            and l.pos = i.pos
        join morph m on m.feats = i.morph
        join lexeme x on x.norm = i.norm
            and l.id = x.lemma
            and x.morph = m.id
        join sent s on s.string = i.text_id
            and s.i = i.sent_i
    where
        i.type = 1;

    /* Non-word tokens */
    raise info 'Inserting non-words tokens...';
    insert into token (
        sent,
        i,
        idx,
        len,
        s,
        tspace)
    select
        s.id,
        i.i,
        i.idx,
        i.len,
        i.s,
        i.tspace
    from
        _textobj i
        join sent s on s.string = i.text_id
            and s.i = i.sent_i
    where
        i.type = 0;
    raise info 'Annotations successfully inserted!';

    /* Truncate table if parameter is 1. */
    if $1 = 1 then
        truncate _textobj;
    end if;
end;
$_$;


--
-- Name: tokenandtag(integer); Type: FUNCTION; Schema: nlpg; Owner: -
--

CREATE FUNCTION nlpg.tokenandtag(sid integer) RETURNS TABLE(s text, tspace integer, lemma text, pos text, idxtext integer, idxxml integer)
    LANGUAGE sql
    AS $_$
    with x as (
        select
            token.s,
            token.tspace,
            '' as lemma,
            '' as pos,
            token.idx as idxtext,
            token.idx as idxxml
        from
            only nlpg.token
            join nlpg.sent on sent.id = token.sent
        where
            sent.string = $1
        union
        select
            word.s,
            word.tspace,
            lemma.lemma,
            pos.name as pos,
            word.idx as idxtext,
            word.idx as idxxml
        from
            nlpg.word
            join nlpg.sent on sent.id = word.sent
            join nlpg.lexeme on lexeme.id = word.lexeme
            join nlpg.lemma on lemma.id = lexeme.lemma
            join nlpg.pos on pos.id = lemma.pos
        where
            sent.string = $1
        union
        select
            s,
            0 as tspace,
            '' as lemma,
            '' as pos,
            idxtext,
            idxxml
        from
            nlpg.xtag
        where
            sid = $1
)
    select
        *
    from
        x
    order by
        idxtext,
        idxxml
$_$;


--
-- Name: chunk; Type: TABLE; Schema: hum; Owner: -
--

CREATE TABLE hum.chunk (
    id bigint NOT NULL,
    passage bigint NOT NULL,
    metaphors jsonb,
    people jsonb,
    quotations jsonb,
    type text NOT NULL
);


--
-- Name: passage; Type: TABLE; Schema: hum; Owner: -
--

CREATE TABLE hum.passage (
    id bigint NOT NULL,
    uri text NOT NULL,
    work bigint,
    text text NOT NULL,
    translation text NOT NULL,
    lang text NOT NULL
);


--
-- Name: work; Type: TABLE; Schema: hum; Owner: -
--

CREATE TABLE hum.work (
    id bigint NOT NULL,
    uri text NOT NULL,
    label text NOT NULL,
    year integer
);


--
-- Name: passage_; Type: VIEW; Schema: hum; Owner: -
--

CREATE VIEW hum.passage_ AS
 SELECT p.id,
    p.uri,
    p.text,
    p.translation,
    p.lang,
    w.year,
    w.label,
    w.uri AS work
   FROM (hum.passage p
     JOIN hum.work w ON ((w.id = p.work)));


--
-- Name: string; Type: TABLE; Schema: hum; Owner: -
--

CREATE TABLE hum.string (
    id bigint NOT NULL,
    val text NOT NULL,
    chunk bigint NOT NULL,
    type text NOT NULL
);


--
-- Name: chunk_; Type: VIEW; Schema: hum; Owner: -
--

CREATE VIEW hum.chunk_ AS
 SELECT s1.val AS text,
    s2.val AS idea,
    c.type,
    c.metaphors,
    c.people,
    c.quotations,
    p.uri AS passage_uri,
    p.translation AS passage_translation,
    p.text AS passage_text,
    p.lang,
    s1.id AS text_id,
    s2.id AS idea_id
   FROM (((hum.chunk c
     JOIN hum.string s1 ON (((s1.chunk = c.id) AND (s1.type = 'text'::text))))
     JOIN hum.string s2 ON (((s2.chunk = c.id) AND (s2.type = 'idea'::text))))
     JOIN hum.passage_ p ON ((p.id = c.passage)));


--
-- Name: string_id_seq; Type: SEQUENCE; Schema: hum; Owner: -
--

ALTER TABLE hum.string ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME hum.string_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: _config; Type: TABLE; Schema: nlpg; Owner: -
--

CREATE TABLE nlpg._config (
    key text,
    value text
);


--
-- Name: _textobj; Type: TABLE; Schema: nlpg; Owner: -
--

CREATE TABLE nlpg._textobj (
    text_id integer,
    sent_i integer,
    type smallint,
    i integer,
    idx integer,
    len integer,
    s text,
    tspace smallint,
    norm text,
    pos smallint,
    morph text,
    lemma text,
    dep smallint,
    head integer,
    userdata jsonb
);


--
-- Name: dep_id_seq; Type: SEQUENCE; Schema: nlpg; Owner: -
--

ALTER TABLE nlpg.dep ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME nlpg.dep_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: has_synset; Type: TABLE; Schema: nlpg; Owner: -
--

CREATE TABLE nlpg.has_synset (
    lemma integer NOT NULL,
    synset integer NOT NULL,
    n integer NOT NULL
);


--
-- Name: lemma_id_seq; Type: SEQUENCE; Schema: nlpg; Owner: -
--

ALTER TABLE nlpg.lemma ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME nlpg.lemma_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: lexeme_; Type: VIEW; Schema: nlpg; Owner: -
--

CREATE VIEW nlpg.lexeme_ AS
 SELECT lexeme.id,
    lexeme.norm,
    lemma.lemma,
    pos.name AS pos,
    morph.tense,
    morph.polarity,
    morph.verbform,
    morph.mood,
    morph.definite,
    morph.poss,
    morph.numtype,
    morph.number_psor,
    morph.prontype,
    morph.voice,
    morph.number,
    morph.person,
    morph.reflex
   FROM (((nlpg.lexeme
     JOIN nlpg.lemma ON ((lemma.id = lexeme.lemma)))
     JOIN nlpg.pos ON ((pos.id = lemma.pos)))
     JOIN nlpg.morph ON ((morph.id = lexeme.morph)));


--
-- Name: lexeme_id_seq; Type: SEQUENCE; Schema: nlpg; Owner: -
--

ALTER TABLE nlpg.lexeme ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME nlpg.lexeme_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: markup; Type: TABLE; Schema: nlpg; Owner: -
--

CREATE TABLE nlpg.markup (
    id integer,
    text text
);


--
-- Name: morph_id_seq; Type: SEQUENCE; Schema: nlpg; Owner: -
--

ALTER TABLE nlpg.morph ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME nlpg.morph_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: pos_id_seq; Type: SEQUENCE; Schema: nlpg; Owner: -
--

ALTER TABLE nlpg.pos ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME nlpg.pos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: sent_id_seq; Type: SEQUENCE; Schema: nlpg; Owner: -
--

ALTER TABLE nlpg.sent ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME nlpg.sent_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: span; Type: TABLE; Schema: nlpg; Owner: -
--

CREATE TABLE nlpg.span (
    string bigint NOT NULL,
    id integer NOT NULL,
    idx integer NOT NULL,
    len integer NOT NULL,
    attrs jsonb
);


--
-- Name: stopword; Type: TABLE; Schema: nlpg; Owner: -
--

CREATE TABLE nlpg.stopword (
    norm text NOT NULL
);


--
-- Name: synset; Type: TABLE; Schema: nlpg; Owner: -
--

CREATE TABLE nlpg.synset (
    id integer NOT NULL,
    label text NOT NULL,
    hypernym_paths nlpg.ltree[],
    lemmas text[],
    definition text,
    examples text[]
);


--
-- Name: synset_id_seq; Type: SEQUENCE; Schema: nlpg; Owner: -
--

ALTER TABLE nlpg.synset ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME nlpg.synset_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: token_; Type: VIEW; Schema: nlpg; Owner: -
--

CREATE VIEW nlpg.token_ AS
 SELECT sent.string,
    sent.id AS sent,
    word.i,
    word.s,
    word.tspace,
    word.idx,
    word.len,
    lexeme.norm,
    lemma.lemma,
    pos.name AS pos,
    word.head,
    dep.name AS dep
   FROM (((((nlpg.word
     JOIN nlpg.sent ON ((sent.id = word.sent)))
     JOIN nlpg.lexeme ON ((lexeme.id = word.lexeme)))
     JOIN nlpg.lemma ON ((lemma.id = lexeme.lemma)))
     JOIN nlpg.pos ON ((pos.id = lemma.pos)))
     JOIN nlpg.dep ON ((dep.id = word.dep)))
UNION
 SELECT sent.string,
    sent.id AS sent,
    token.i,
    token.s,
    token.tspace,
    token.idx,
    token.len,
    ''::text AS norm,
    ''::text AS lemma,
    ''::text AS pos,
    '-1'::integer AS head,
    ''::text AS dep
   FROM (ONLY nlpg.token
     JOIN nlpg.sent ON ((sent.id = token.sent)));


--
-- Name: xspan; Type: TABLE; Schema: nlpg; Owner: -
--

CREATE TABLE nlpg.xspan (
    tag text
)
INHERITS (nlpg.span);


--
-- Name: xtag; Type: TABLE; Schema: nlpg; Owner: -
--

CREATE TABLE nlpg.xtag (
    sid integer,
    idxtext integer,
    idxxml integer,
    len integer,
    s text
);


--
-- Data for Name: chunk; Type: TABLE DATA; Schema: hum; Owner: -
--

COPY hum.chunk (id, passage, metaphors, people, quotations, type) FROM stdin;
1	1855762758963808	[]	[]	[]	practice
2	1855762758963808	[]	[]	[]	practice
3	1855762758963808	[]	[]	[]	practice
4	1856276471137690	["mother"]	[]	[]	theory
5	1856276471137690	["birth", "granddaughter"]	[]	[]	theory
6	1856276471137690	["plagues", "fights", "antidote", "poison"]	[]	[]	theory
7	1856277184069302	[]	[]	[]	taxonomy
8	1856277184069302	[]	[]	[]	taxonomy
9	1856277184069302	[]	[]	[]	taxonomy
10	1856277184069302	[]	[]	[]	taxonomy
11	1856277857370137	["battle array", "draws to the left"]	[]	[]	theory
12	1856277857370137	["army", "leads to the right"]	[]	[]	theory
13	1856277857370137	["companions"]	[]	[]	theory
14	1857548123237727	[]	[]	[]	example
15	1857548123237727	[]	[]	[]	example
16	1857548123237727	[]	[]	[]	example
17	1857625626759097	["safety"]	[]	[]	example
18	1857625626759097	[]	[]	[]	example
19	1857625626759097	[]	[]	[]	example
20	1857625626759097	[]	[]	[]	example
21	1857631053065982	[]	[{"name": "God", "type": "biblical"}]	[]	practice
22	1857631053065982	[]	[]	[]	practice
23	1857633512175968	[]	[{"name": "God", "type": "biblical"}]	[]	example
24	1857633512175968	[]	[]	[]	example
25	1857638230018891	[]	[]	[]	example
26	1857638230018891	[]	[]	[]	example
27	1858017432086829	[]	[{"name": "God", "type": "biblical"}]	[]	theory
28	1858017432086829	[]	[]	[]	theory
29	1858017432086829	[]	[{"name": "God", "type": "biblical"}]	[]	theory
30	1858017432086829	["bread of angels", "power of the heavens"]	[]	[]	theory
31	1858017432086829	[]	[{"name": "God", "type": "biblical"}]	[]	theory
32	1858018789194510	[]	[]	[]	theory
33	1858019016523862	["cloak itself"]	[]	[]	theory
34	1858203376142245	["bending"]	[]	[]	theory
35	1858204272034099	["Lady humility", "rises"]	[]	[]	theory
36	1858204272034099	["root", "foundation"]	[]	[]	theory
37	1858205879918496	["immersions", "river", "descend downward"]	[]	[]	taxonomy
38	1858205879918496	["ankles", "knees", "loins"]	[{"name": "Ezekiel", "type": "biblical"}]	[]	taxonomy
39	1858205879918496	[]	[]	[]	taxonomy
40	1858205934636520	[]	[]	[]	practice
41	1858205934636520	[]	[]	[]	practice
42	1858205934636520	[]	[]	[]	practice
43	1858205934636520	[]	[]	[]	practice
44	1858205934636520	[]	[]	[]	practice
45	1858205934636520	[]	[]	[]	practice
46	1858205934636520	["bad workman"]	[]	[]	practice
47	1858205934636520	[]	[]	[]	practice
48	1858205934636520	[]	[]	[]	practice
49	1858205934636520	[]	[]	[]	practice
50	1859808579384257	["steps", "footsteps"]	[{"name": "Jesus Christ", "type": "biblical"}]	[]	example
51	1859808579384257	["course", "path"]	[]	[]	example
52	1859808579384257	[]	[]	[]	example
53	1859808703738874	["exalts"]	[]	[]	example
54	1859817395767635	[]	[]	[]	example
55	1859817395767635	["earning", "gift"]	[]	[]	example
56	1859817395767635	[]	[]	[]	example
57	1859817395767635	[]	[]	[]	example
58	1859817530591260	["way"]	[]	[]	example
59	1859817530591260	["lamb"]	[]	[]	example
60	1859819039824652	[]	[{"name": "Lord", "type": "biblical"}]	[]	example
61	1859819039824652	[]	[]	[]	example
62	1859819039824652	[]	[]	[]	example
63	1859819039824652	[]	[]	[]	example
64	1859819039824652	[]	[]	[]	example
65	1859824805640975	["rooted", "shone forth"]	[]	[]	example
66	1859824805640975	["marks"]	[]	[]	example
67	1860629181610070	["argument", "proof"]	[]	[]	theory
68	1860629181610070	["instructs"]	[]	[]	theory
69	1860643125750836	[]	[]	[]	example
70	1860643125750836	[]	[{"name": "Pharisee", "type": "biblical"}, {"name": "publican", "type": "biblical"}]	[]	example
71	1860643125750836	[]	[{"name": "God", "type": "biblical"}]	[]	example
72	1860643125750836	[]	[]	[]	example
73	1860643125750836	[]	[{"name": "God", "type": "biblical"}]	[]	example
74	1860643125750836	[]	[]	[]	example
75	1860643863543677	[]	[{"name": "Lord God", "type": "biblical"}]	[]	practice
76	1860643863543677	[]	[]	[]	practice
77	1860643863543677	["compunction of tears"]	[]	[]	practice
78	1860643863543677	[]	[]	[]	practice
79	1860644292478230	["form", "robbery"]	[{"name": "Christ", "type": "biblical"}, {"name": "God", "type": "biblical"}]	[]	theory
80	1860644292478230	["emptied", "form", "servant"]	[]	[]	theory
81	1860644734474638	["conversion"]	[{"name": "God", "type": "biblical"}]	[]	theory
82	1860644734474638	["attached"]	[]	[]	theory
83	1860645749090297	[]	[]	[]	practice
84	1860645749090297	[]	[]	[]	practice
85	1860645749090297	["raising of the heart"]	[]	[]	practice
86	1860645749090297	[]	[]	[]	practice
87	1860646188452840	[]	[]	[]	theory
88	1860646188452840	["belly clings to the ground"]	[]	[]	theory
89	1860646188452840	[]	[]	[]	theory
90	1860646733992892	[]	[]	[]	practice
91	1860646733992892	[]	[]	[]	practice
92	1860646733992892	["pierce the clouds"]	[]	["Sirach"]	practice
93	1860647648500503	["form of a servant"]	[{"name": "Lord", "type": "biblical"}]	[]	practice
94	1860647648500503	[]	[{"name": "publican", "type": "biblical"}]	[]	practice
95	1860647648500503	[]	[{"name": "God", "type": "biblical"}]	[]	practice
96	1860647994318478	["seize"]	[{"name": "God", "type": "biblical"}]	[]	theory
97	1860647994318478	["depths of the heart"]	[{"name": "Cassidorus", "type": "historical"}]	["Cassidorus"]	theory
98	1860647994318478	[]	[{"name": "Lord", "type": "biblical"}]	[]	theory
101	1861119590980241	[]	[]	[]	practice
102	1861119590980241	[]	[]	[]	practice
103	1861119590980241	[]	[]	[]	practice
104	1861119590980241	[]	[]	[]	practice
105	1861119590980241	["Gold and silver are tried in the fire"]	[]	["Ecclesiasticus"]	practice
106	1861119590980241	[]	[{"name": "Augustine", "type": "historical"}]	["Augustine"]	practice
107	1861119590980241	[]	[{"name": "Christ", "type": "biblical"}]	[]	practice
108	1861121259074547	[]	[]	[]	practice
109	1861121259074547	["peacock", "feet are most vile", "splendid tail"]	[]	[]	practice
110	1861121259074547	[]	[{"name": "Publican", "type": "biblical"}]	["Luke"]	practice
111	1861121259074547	[]	[{"name": "Lord", "type": "biblical"}]	[]	practice
112	1861121259074547	[]	[]	[]	practice
113	1861160272319385	[]	[{"name": "Christ", "type": "biblical"}]	[]	practice
114	1861160272319385	["eagle", "sun"]	[{"name": "Christ", "type": "biblical"}]	[]	practice
115	1861160272319385	["sun of justice"]	[]	[]	practice
116	1861160272319385	[]	[{"name": "Isaiah", "type": "biblical"}, {"name": "Christ", "type": "biblical"}]	["Isaiah"]	practice
117	1861160272319385	[]	[{"name": "Father", "type": "biblical"}]	[]	practice
118	1861160272319385	["form of God"]	[{"name": "God", "type": "biblical"}]	["Philippians"]	practice
119	1861160272319385	[]	[{"name": "Luke", "type": "biblical"}]	["Luke"]	practice
120	1861160272319385	[]	[]	[]	practice
121	1861160272319385	[]	[]	[]	practice
122	1863722516753444	["highest realm", "earth"]	[]	[]	theory
123	1863724264537983	[]	[]	[]	example
124	1863724264537983	["burdened with"]	[]	[]	example
125	1863790575245133	[]	[]	[]	example
126	1863790575245133	[]	[]	[]	example
127	1863790575245133	["touching the holy wounds of Christ"]	[{"name": "Christ", "type": "biblical"}]	[]	example
128	1863792754906030	[]	[]	[]	example
129	1863792754906030	[]	[]	[]	example
130	1863792754906030	[]	[]	[]	example
131	1863793861361981	[]	[{"name": "Gabriel", "type": "biblical"}]	[]	example
132	1863793861361981	[]	[{"name": "mother of our Lord", "type": "biblical"}]	[]	example
133	1863795087100863	[]	[{"name": "Gottfried", "type": "historical"}]	[]	example
134	1863795484353259	["shines forth"]	[]	[]	example
135	1863795484353259	["riches"]	[]	[]	example
136	1863795844188488	[]	[]	[]	example
137	1863795844188488	["from the heart"]	[]	[]	example
138	1863796149542117	[]	[{"name": "Lord", "type": "biblical"}]	[]	example
139	1864335462373801	["poverty of spirit"]	[]	[]	taxonomy
140	1864336536902536	["attacks"]	[{"name": "devil", "type": "biblical"}]	[]	theory
141	1864336536902536	["drag"]	[]	[]	theory
142	1864336536902536	["incline"]	[]	[]	theory
143	1864337327689303	["battles", "before our eyes"]	[]	[]	practice
144	1864337327689303	[]	[]	[]	practice
145	1864337327689303	["mother of want"]	[]	[]	practice
146	1864337327689303	[]	[]	[]	practice
147	1864337810614375	[]	[]	[]	theory
148	1864337935995352	["companions"]	[]	[]	taxonomy
149	1864339191766783	[]	[{"name": "Christ", "type": "biblical"}]	[]	theory
150	1864339191766783	[]	[{"name": "Christ Jesus", "type": "biblical"}]	[]	theory
151	1864339191766783	["form", "emptied"]	[{"name": "God", "type": "biblical"}]	[]	theory
152	1864339191766783	["likeness", "appearance"]	[]	[]	theory
153	1864339191766783	[]	[]	[]	theory
154	1864339191766783	[]	[{"name": "Christ", "type": "biblical"}]	[]	theory
155	1864339191766783	[]	[]	[]	theory
156	1864339813688486	["summit"]	[]	[]	taxonomy
157	1864339813688486	[]	[]	["Apostle"]	taxonomy
158	1864339813688486	["fragrant aroma"]	[{"name": "God", "type": "biblical"}, {"name": "Christ", "type": "biblical"}]	[]	taxonomy
159	1864339813688486	[]	[{"name": "God", "type": "biblical"}]	[]	taxonomy
160	1864339813688486	[]	[]	[]	taxonomy
161	1864351463158531	[]	[]	[]	practice
162	1864351463158531	[]	[{"name": "God", "type": "biblical"}]	[]	practice
163	1864351463158531	[]	[]	[]	practice
164	1864351463158531	[]	[]	[]	practice
165	1864351463158531	[]	[{"name": "God", "type": "biblical"}, {"name": "evil spirit", "type": "biblical"}]	[]	practice
166	1864353704027894	["door", "cast-away"]	[]	[]	practice
167	1864353704027894	["press himself beneath"]	[{"name": "God", "type": "biblical"}]	[]	practice
168	1864353704027894	[]	[{"name": "God", "type": "biblical"}]	[]	practice
169	1864354393021102	["art", "enclosed"]	[]	[]	theory
170	1864354393021102	["gloss", "ground"]	[]	[]	theory
171	1864354947548686	[]	[{"name": "God", "type": "biblical"}]	[]	practice
172	1864354947548686	[]	[]	[]	practice
173	1864355400736826	[]	[]	[]	theory
174	1864355400736826	["lifted"]	[{"name": "God", "type": "biblical"}]	[]	theory
175	1864355400736826	["sinks", "ground"]	[]	[]	theory
176	1864355400736826	[]	[]	[]	theory
177	1864355400736826	[]	[]	[]	theory
178	1864355400736826	[]	[{"name": "Lord", "type": "biblical"}]	[]	theory
179	1864355781664527	["enter"]	[{"name": "God", "type": "biblical"}]	[]	theory
180	1864356234096140	["searching"]	[{"name": "God", "type": "biblical"}]	[]	theory
181	1870054903962330	[]	[]	[]	example
182	1870056375622536	["shine"]	[{"name": "Lord", "type": "biblical"}]	[]	example
183	1870056375622536	[]	[]	[]	example
184	1870057730633221	[]	[]	[]	theory
185	1870057730633221	["sweetness", "brought forth"]	[{"name": "Lord", "type": "biblical"}]	[]	theory
186	1870058651863608	[]	[]	[]	practice
187	1870059331974179	[]	[{"name": "Sister Getrut", "type": "historical"}]	[]	example
188	1870059331974179	[]	[]	[]	example
189	1870137484486919	[]	[]	[]	example
190	1870137484486919	[]	[]	[]	example
191	1870139523180822	[]	[{"name": "Lord God", "type": "biblical"}]	[]	example
192	1870139523180822	["heart breaks"]	[]	[]	example
193	1870144357486944	[]	[]	[]	example
194	1870144357486944	[]	[]	[]	example
195	1870144357486944	[]	[]	[]	example
196	1870145020650678	[]	[]	[]	example
197	1870145020650678	[]	[]	[]	example
198	1870145020650678	[]	[]	[]	example
199	1870145020650678	[]	[]	[]	example
200	1870146813670713	["little sheep", "green grass"]	[{"name": "Christ", "type": "biblical"}]	[]	practice
201	1870146813670713	[]	[{"name": "Mother of God", "type": "biblical"}, {"name": "saints", "type": "biblical"}]	[]	practice
202	1870226107719194	[]	[{"name": "God", "type": "biblical"}, {"name": "Jesus Christ", "type": "biblical"}]	[]	theory
203	1870226107719194	["days of his humility", "foundation"]	[{"name": "Saint John the Baptist", "type": "biblical"}]	[]	theory
204	1870309611691221	["queen", "death"]	[]	[]	theory
205	1870309611691221	["instrument", "nurse"]	[]	[]	theory
206	1870309611691221	["mistress", "teacher"]	[{"name": "Holy Spirit", "type": "biblical"}]	[]	theory
207	1870604707961962	[]	[]	[]	theory
208	1870604707961962	["friend of quiet"]	[]	[]	theory
209	1870604996053748	[]	[]	[]	theory
210	1870604996053748	[]	[]	[]	theory
211	1873216951180530	["follow in their footsteps"]	[{"name": "Lord our God", "type": "biblical"}, {"name": "holy mothers", "type": "historical"}]	[]	practice
212	1873219519418646	[]	[{"name": "Brother Johannes", "type": "historical"}, {"name": "sister Elisabet", "type": "historical"}]	[]	practice
213	1873219519418646	["bear in her heart", "follow in his footsteps"]	[{"name": "Jesus Christ", "type": "biblical"}, {"name": "John the Baptist", "type": "biblical"}]	[]	practice
214	1873222897757009	[]	[]	[]	example
215	1873223667510247	[]	[]	[]	practice
216	1873224248532625	[]	[{"name": "Virgin Mary", "type": "biblical"}]	[]	practice
217	1873225310966469	[]	[]	[]	theory
218	1873225310966469	["snares"]	[{"name": "Saint Anthony", "type": "historical"}]	[]	theory
\.


--
-- Data for Name: passage; Type: TABLE DATA; Schema: hum; Owner: -
--

COPY hum.passage (id, uri, work, text, translation, lang) FROM stdin;
1859819039824652	69b7edd371b0c	1857369139681484	Do si in daz closter waz ingangen, do fleisz si sich unserem herren zü dienen mit lutrem herczen in demütikeit und in senftmütikeit, und waz in allen dingen sich selben versmochen und verwerffen, so vil volkomenlicher so vil leben in der welt me zart waz gesin in wollústen. Alle tag wüsch si mit iren eignen henden die schússlen und andre geschirr der kuchi mit den dirnen, und half inen öch empcziklich in andren dingen, die do ze tün woren, in denen si inen mocht gehelfen. In disen wercken und den glich hat si lust als in allen richtümen. \r\n	When she had entered the convent, she devoted herself to serving our Lord with a pure heart, in humility and in gentleness, and in all things she so thoroughly despises and casts herself aside, in proportion as her life in the world had previously been the more delicate in its pleasures. Each day she washed bowls and other kitchen vessels with her own hands together with the serving girls, and she also zealously helped them in other tasks that were required, wherever she was able to assist them. In these works and the like she took as much delight as in all riches.	Middle High German
1859808579384257	69b7c6db973c1	1857369139681484	Si hat ire geng uff geseczt in die füssstapfen unsers herren Jhesu Christi und ist nit hinder sich gangen noch usz getretten uncz si den löff ires weges volbrocht hat, nochvolgende siner demütikeit, siner gedult, siner minn, und den andren tugenden, die er mit worten und mit exemplen het gelert.	She set her steps upon the footsteps of out Lord Jesus Christ and did not turn back nor step aside until she had completed the course of her path, following his humility, his patience, his love and the other virtues that he had taught by words and by example.	Middle High German
1859817395767635	69b7e7b38c953	1857369139681484	Und do die swestren, den si söliches seit, sich verwundreten und sprochen si selig um ir grosse luterkeit, zü hand kert si ir selben zü dem verdienen der demütikeit, die so úbertreffenliche gob der götlichen gob und sprach: “Ir söllend wissen in der worheit, daz es nit kunt usz tugend miner kúscheit, daz ich nit kan von unluteren dingen gedenken, sunder es ist ein torheit mines gemütes.”	And when the sisters to whom she said this were astonishing and spoke of her blessedness because of her great purity, she immediately turned herself back to the earning of humility, which so surpassingly gives glory to the divine gift of grace, and said: “You should know in truth that it does not come from the virtue of chastity, that I am unable to think of impure things; rather, it is the folly of my mind. 	Middle High German
1864351463158531	69f9e26b2b303	\N	Welher mensch aber sich selber ausser göttlicher minne vnd lieb mit eim reinen lautern hertzen vnd mit einr guten gewissen vnd mit eim waren, vesten, vngestifften glauben in allen dingen lat vnd sich got gentzlich gibt vnd bevihlt in lieb vnd in layd vnd mit slehten worten in allem leiden vnd widerwertikeit vnd betrübnüß vnd dem gotlichen willen demütiklich mit williger gedult vnd gelassenheit, dankberlich gehorsam ist, sig, diz ist rehter, warer, sicher vnd gewisser andaht vnd ist auch ie vnd ie gut vnd gereht vnd von got all zeit vnd nit von der natur noch von dem bösen geist vnd ist auch ein sicher gewisse zeichen rehter warer heilikeit vnd rechtes andahtes.	But whoever lets himself go in everything out of godly love with a pure and clear heart, and with a good consciousness and with a true, strong, unfaked faith, and who gives oneself to God completely in love and pain; and whoever is thankfully obedient with plain words in all pain and hardship and sadness, [whoever is thankfully obedient] to gods will, humbly, with chosen patience and reliance, look: this is the right, true, safe and certain kind of devotion, and it is also good and just, always from God, never from nature or the evil spirit, and it is furthermore a safe and certain sign of right, true holiness and right devotion. 	Middle High German
1863790575245133	69f1b8f2c574d	1857369139681484	Den dient si emtziklich mit milter sorg und mit unverdrossenem fliss, und nit allein dient si in emptziklichen, me öch die unsuferkeit und die geswer der siechen handlet si mit iren eigenen henden so demüttiklich, so wirdiklichen und so getrúwlichen, als ob si berürt die helgen wunden Christi. 	She serves them with tireless dedication, with gentle care and unwearied diligence; and not only does she serve them in this constancy, but she also handles the filth and the sores of the sick with her own hands, so humbly, so worthily, and so faithfully, as if she were touching the holy wounds of Christ.	Middle High German
1859808703738874	69b7c7522f3fa	1857369139681484	Ir tieffi wore demütikeit erhöchet si alwegen vor miner angesicht. 	Her deep and true humility always exalts her before my sight.	Middle High German
1860645749090297	69c3f58ed67f9	1858205689470586	Illud autem sciendum est quod genuflexio cum elevatione capitis et oculorum, junctis manibus, dispositio est inter omnes aptior ad orandum, sicut noverunt experti. Genuflexio enim habet humilitatem, elevationem vero capitis et oculorum sequitur facile elevatio cordis, quia anima propter colligationem quam habet cum corpore, facile sequitur dispositiones ejus; manuum vero junctio expressio est affectus. Nihil autem est utilius in oratione quam humilitas, intentio et affectus.	There is to know kneeling with the head and eyes raised, and with the hands joined, is among all postures the most suitable for praying, as those with experience know. For kneeling expresses humility; and the raising of the head and the eyes is easily followed by the raising of the heart, because the soul, on account of its connection with the body, easily follows the body's dispositions. The joining of the hands, moreover, is an expression of affection. Now nothing is more useful in prayer than humility, attentiveness, and heartfelt devotion.	Latin
1855762758963808	697ce70091260	1855762500562299	Signa uero humilitatis sunt humilitas habitus, uultus et gestus, abiectio sui, uehementia seipsum accusandi.	The signs of humility are humility in garment, in expression, and in gesture; self-abasement; and a strong eagerness to accuse oneself.	Latin
1863793861361981	69f1c530a813d	1857369139681484	Und die keisserliche jungfrow, die mütter unsers herren, unzüglichlichen schinende von antlit und von gewand mit irem sunderlichen botschaft werber, dem heilgen ertzengel Gabriel, giengen aller erwirdiklichest hin fúr zü dem altar, und zü der rechten sitten des altars böigten si demüttiklich ire heilgen knú.	And the imperial virgin, the mother of our Lord, shining without blemish in countenance and in garment, together with her particular messenger and herald, the holy archangel Gabriel, proceeded forward toward the altar with the greatest reverence; and on the right side of the altar they humbly bent their holy knees.	Middle High German
1873225310966469	6a7b0413e92c5	1857369139681484	Dis ist die forcht die usz demüttikeit kunt und sachet öch die demüttikeit, die allein enttrint den stricken des bösen geistes, als dem heilgen sant Anthonio geoffenbart wart. 	This is the fear that arises from humility and in turn gives rise to humility, which alone disentangled itself from the snares of the evil spirit, as was revealed to the holy Saint Anthony. 	Middle High German
1870058651863608	6a4cef5a74a38	1857369139681484	“Caritatem habete, humilitatem servate, pauperitatem voluntariam possidete.” “Habend götliche minn, behalten demütikeit, besitzent willige armüt.” 	"Have charity, preserve humility, posess voluntary poverty." "Have divine love, preserve humility, posess voluntary poverty."	Middle High German
1864354393021102	69f9ed554daae	\N	Dis ist ein kunst do alle kúnste inne beslossen sint der man zuͦ warer heilikeit bedarf; daz were ware demuͤtikeit sunder alle glose und nút in den worten oder in dem schine, sunder in der worheit und in dem grunde.	This is an art in which all arts are enclosed that one needs for true holiness: namely true humility, without all gloss or pretense, not in words or in outward appearance, but in truth and in the ground.	Middle High German
1858019016523862	699dbc3774056	1858017810233858	Gloriosa res humilitas, qua ipsa quoque superbia palliare se appetit, ne vilescat!	Humility is a glorious thing, so glorious that even pride itself seeks to cloak itself with it, lest it become despised.	Latin
1860647648500503	69c3fca241b17	\N	Aliquando enim orans formam assumit servi, Dominum et iudicem suum humiliter et timorate ad misericordiam provocando, sicut publicanus ille, qui nec oculos audebat ad caelum levare, sed percutiens pectus suum, dicebat: Deus, propitius esto mihi peccatori.	Sometimes, indeed, the one praying takes on the form of a servant, humbly and fearfully appealing to his Lord and Judge for mercy, like that publican who did not dare to lift his eyes to heaven, but struck his breast, saying: God, be merciful to me, a sinner.	Latin
1858205879918496	69a0745645fa0	1858205689470586	Istae sunt tres illae immersiones in flumen humilitatis, quae deorsum tendunt, in quibus immersus fuit Ezechiel, modo usque ad talos, modo usque ad genua, modo usque ad renes, sicut habetur cap. 47 ejusd.	These are those three immersions into the river of humility, which descend downward, in which Ezekiel was immersed—up to the ankles, up to the knees, or up to the loins—as is found in chapter 47 of the same book.	Latin
1856277184069302	6984636293eb6	1856274777543728	Humilitas est uirtus per quam animus in nullo se efferens, nichilque bonum sibi ascribens, exterius etiam deiecti prefert habitum. Humilitas autem diuiditur in tres species: in illam qua homo se humiliat maiori, que dicitur sufficiens; et in illam qua homo se humiliat pari, que dicitur perfecta; et in illam qua se humiliat minori, que dicitur superabundans.	Humility is the virtue by which the soul, exalting itself in nothing and attributing no good to itself, even outwardly prefers the appearance of lowliness. Humility, moreover, is divided into three kinds: into that by which a person humbles himself before one who is greater, which is called sufficient; and into that by which a person humbles himself before an equal, which is called perfect; and into that by which he humbles himself before one who is lesser, which is called superabundant.	Latin
1857633512175968	69982019db960	1857369139681484	Vil andre tröstung tet ir got der herr in verborgenheit, aber wenn si gar vast schemig und demütig waz, do wolt si si nit offenbaren.	God the Lord granted her many other forms of consolation in secrecy, but because she was very coy and deeply humble, she did not want to reveal them.	Middle High German
1873222897757009	6a7afb167eb51	1857369139681484	Do viel si demüttiklich an ir venye uf daz ertrich, und von der zit ward si aller volkomenlichest gesund. 	Then she humbly fell in venia to the ground and was thereafter fully healed.	Middle High German
1870604996053748	6a54e2a4e0af4	1870309049248986	Inest humili habitus equalis, firmus incessus, unitus granis, stabilitas ad eadem, status idem, capax prudentie spiritus, spei gaudium, lasciuie petulantis odium, decor in uirtute, confidentia in terrore, de profectu semper in alta gratiarum actio et de propriis meritis nulla umquam presumptio.	In the humble person there is an even bearing, a steady gait, a grave countenance, constancy in the same things, an unchanging state, a spirit capable of prudence, the joy of hope, hatred of wanton frivolity, grace in virtue, confidence in the midst of terror, thanksgiving always directed on high for any progress, and never any presumption about one's own merits.	Latin
1860644734474638	69c3f1c73998e	\N	Nihil ergo aliud est oratio quam mentis deuotio, id est, conuersio in Deum per pium et humilem affectum, fide, spe et caritate subnixa.	Therefore, prayer is nothing else than devotion of the mind, that is: a conversion towards God through a pious and humble affect; belief, hope and love attached.	Latin
1864337327689303	69f9adc288e57	1864335545898141	Nos vero si contra haec bella inimici humilitatem nostram illaesam custodire volumus, mala nostra iugiter ante oculos habere studeamus. Mala autem dico non solum interiora, quae ad iniquitatem et culpam pertinent, sed etiam exteriora, quae pertinent ad utilitatem: sicut est ignobilitas generis, inopia, quae est mater paupertatis; debilitas corporis, et si qua sunt talia quae hominem humiliant. Nam si culpas nostras et miserias nostras bene et attente inspicere volumus, tunc fortassis nec indignum iudicabimus, si nobis inferatur iniuria; nec dignum, si reverentia exhibeatur.	But if we truly wish to keep our humility unharmed against these battles of the enemy, let us strive to keep our own faults constantly before our eyes. By faults, however, I mean not only the interior ones, which pertain to iniquity and sin, but also the exterior ones, which pertain to our benefit: such as lowliness of birth, poverty — which is the mother of want — weakness of body, and whatever else of this kind humbles a person. For if we are willing to look well and attentively upon our sins and our miseries, then perhaps we will judge it neither undeserved, if an injury is inflicted upon us, nor deserved, if reverence is shown.	Latin
1860647994318478	69c3fdec0de8e	\N	Est autem oratio dei benivolentie captatio. Item Cassiodorus: Est autem oratio oris ratio, frequens deprecatio et assidua supplicatio, que ab imo pectoris archano procedit cum pietate et devotione. Effectus vero orationis est domini misericordem et propitium nobis efficere.	Prayer is to seize the goodwill of God. Cassidorus adds: Prayer is oral reasoning, frequent deprecation and constant supplication, which proceeds from the depths of the heart with piety and devotion. The effect of prayer is to make the Lord merciful and favorable to us.	Latin
1870144357486944	6a4e2ea1b5160	1857369139681484	Also kam diese swester wider und hat usz der mossen einen demüttigen wandel. Si hat ir selben an ein zedel geschriben alle ir liplichen und geistlichen gebresten, die lasz si dick ir selben zü demüttigung.	Thus the sister retunred and thereafter lived a life of extraordinary humility. She wrote down for herself on a slip of paper all her bodily and spiritual shortcomings, and she often read it for her own humbling.	Middle High German
1870226107719194	6a4f5f2ccde1a	1857369139681484	Der selb milt got des ewigen gottes sun unser herr Jhesus Christus, der durch die predige sins userwelten fúrlöiffers und sins aller wirdigesten töiffers sancti Johannis baptiste und durch daz exempel sins aller strengesten heilgesten lebens het vor gekúndet und erzöiget, und in den tagen siner demüttikeit selber het geheilget daz sacrament der volkomenen penitentz und selber geleit daz fundament der woren geistlicheit [...]	The same gracious God, the Son of the eternal God, our Lord Jesus Christ, who through the preaching of his chosen forerunner and most worthy baptizer, Saint John the Baptist, and through the example of his most strictly religious and holy life, had proclaimed and demonstrated this; and who, in the days of his humility, himself sanctified the sacrament of perfect penance himself laid the foundation of true spirituality [...]	Middle High German
1881462699258650	6af2e2bd8f31a	1881462039439812	Dis ist von götlicher gnad sällikait […] Zuo dem drytten ist zemercken, wie wir gnad aber koment. Zuo dem ersten mit götlicher vorcht. Zuo dem andren mit demüttikait, so wisset dz zuo demüttikait, an sechen das vnsicher gericht vnsser heren, das der mesch nit waist wie er da funden wirt, vnd dz wir aigenlich schetzen vnsser ge-bresten, vnd das wir vns fürsetzen, vnd ansechent ain bild ains guotten menschen, vnd vnsser leben danach richten. Zuo dem drytten: So über komen wir götlich gnad mit danckberkait. Dz fierd ist von der frucht der gand.	This is about the blessedness of divine grace. [...] In regards to the third, it is to be noted how we may come to grace again. First, through the fear of God. Second, through humility. Know that humility consists in considering the uncertain judgement of Our Lord, for a person does not know how he will be found there; and in rightly esteeming our shortcomings; and in setting before ourselves the example of a good person and ordering our lives according to it. Third, we obtain divine grace through gratitude. The fourth part deals with the fruits of grace.	Middle High German
1864355781664527	69f9f2819df0f	\N	Daz dis gemuͤte ge mit minnen in, in inniger begerunge, in einem demuͤtigen underwurffe under Got, das ist dis wore gebet alleine.	That the soul should enter with love, with outmost desire, humbly submitting to God - this alone is true prayer.	Middle High German
1864337810614375	69f9af8f16867	1864337564964356	Humilitas autem habitus non superabundans in sumptibus et praeparationibus.	Humility, moreover, is a disposition that is not excessive in expenditures and preparations.	Latin
1863792754906030	69f1c111753ae	1857369139681484	Aber under andren tugenden ires gemüttes hand wir an ir gesechen ein zü verwundrende gnod der demüttikeit und der gehorssam, also daz si nie mit einem einigen wort sich unwillig bewiset zü gehorssame, sunder on alles widersprechen gehorssamet si dem willen der gebiettenden oder heissenden in allen dingen.	But among other virtues of her disposition we have observed in her a grace of humility and obedience worthy of admiration, so that she never show herself unwilling to obey with a single word; rather, without contradiction, she obeyed the will of those who command or instruct her in all things. 	Middle High German
1870054903962330	6a4ce1642dada	1857369139681484	Do noch bat si demüttiklichen und ernstlichen, daz si in daz closter enpfangen wurd zü dem dienst der kuchi als lang si lebt. 	After that, she humbly and earnestly requested she be accepted into the convent for service in the kitchen as long as she lived. 	Middle High German
1864356234096140	69f9f43116e0c	\N	Got suͦcht und wil haben einen demuͤtigen menschen, einen senftmuͤtigen menschen, einen armen menschen, einen lutern menschen und einen gelossenen menschen der gelich ste.	God is searching for and wants to have a humble person, a gentle-minded person, a poor person, a pure person, and a let-go person who perseveres in equanimity.	Middle High German
1863722516753444	69f0bb6922c24	1857369139681484	„Ich, do ich grosz und hoch waz in dem höchsten, do bin ich um dinen willen klein und demütig worden uff dem ertrich.“ 	"I who was great and exalted in the highest realm, became, for your sake, small and humble upon the earth."	Middle High German
1864335462373801	69f9a6cfa19a9	1864334606835737	Deinde quarto loco succedunt septem virtutes. Prima, paupertas spiritus, id est humilitas; secunda, mansuetudo sive benignitas; tertia, compunctio sive dolor; quarta, esuries iustitiae sive desiderium bonum; quinta, misericordia; sexta, cordis munditia; septima, pax.	Then, in fourth place, come the seven virtues. First, poverty of spirit, that is, humility; second, meekness or kindness; third, compunction or sorrow; fourth, hunger for righteousness or a good desire; fifth, mercy; sixth, purity of heart; seventh, peace.	Latin
1870057730633221	6a4cebebe6e05	1857369139681484	Si sind von unsrem herren fúrkomen in dem segnen der süssikeit, wele götlichen himelsche süssikeit hie in diser zit ervolget wirt mit reinikeit des inneren und des usseren mönschen, mit senftmüttiger demüttikeit des hertzen und der usseren wandlung, mit andechtiger volbringung des götlichen dienstes, mit flissiger nochfolgung oder behaltung des ordens und der gehorsam in lutterer ungestifteter götlicher minn. 	They have been brought forth by our Lord in the blessings of sweetness, a divine heavenly sweetness that is attained in this life thorugh purity of the inner and outer person, through gentle humility of the heart and outward conduct, through devout performance of divine service, through diligent observance and preservation of the order and of obedience, in pure undivided divine love.	Middle High German
1873224248532625	6a7b001eb1e91	1857369139681484	Aber dis soltu wissen vor allen dingen, daz alle die vorgeseiten ding dir nit nútz weren, es sy denn daz du mit der gesegneten jungfrowen Maria besitzest die aller tieffeste demüttikeit.	But above all things you shall know, that all the aforementioned things will be of no use to you unless you possess, together with the blessed Virgin Mary, the deepest humility of all.	Middle High German
1870137484486919	6a4e15071a907	1857369139681484	Si stünd snelliklichen uf und sasz bald uf irem wagen, und si und der provincial mit sinen gesellen seitten der selben frowen demüttiklich grosse gnod und danck umb die grossen und manigfaltigen güttet, die si inen hat bewiset, und gesegneten si demüttiklich und schieden enweg. 	She rose promptlyand soon took her seat on her wagon. She and the provincial, together with his companions, expressed to that woman humble and heartfelt gratitude and thanks for the great manifold kindness she had shown them. They humbly bestowed their blessings upon her and then departed. 	Middle High German
1858017432086829	699db6506a92d	1858015725877463	Ecce Dei humilitas incomparabilis, quia comparationem dignam non recipit; inaestimabilis, quia aestimari non potest; ineffabilis, quia verbis explicari non potest, ut Deus et Dominus omnium fieret homo et servus omnium, invisibilis videretur, panis Angelorum aleretur, virtus coelorum infirmaretur, vita moreretur; sed huius mysterii causa est, Dei iustitia et misericordia.	Behold the incomparable humility of God! In comparable, because it does not admit a worthy com parison; inestimable, because it is not able to be measured; ineffable, because it cannot be explained with words: that the God and Lord of all should be come a man and the servant of all, that the invisible should be seen, that the Lord, the bread of angels would be nourished, that the power of the heavens should be made weak, that life should die. The cause of this mystery is the justice and mercy of God. 	Latin
1870059331974179	6a4cf1e30f423	1857369139681484	Die brüder und die vorgeseite swester Gertrut stünden erwirdiklich uf gegen ir und mit demüttikeit seitten si ir, daz si umb herberg dar weren komen zü der stund. 	The brothers and the aforementioned Sister Getrut stood up venerably before her, and with humbly told her that they had come there at that time to search for hospitality. 	Middle High German
1858205934636520	69a0748a74de8	\N	Humilitas uero his indiciis conprobatur: primo si mortificatas in sese omnes habeat uoluntates, secundo si non solum suorum actuum, uerum etiam cogitationum nihil suum celauerit seniorem, tertio si nihil suae discretioni, sed iudicio eius uniuersa committat ac monita eius sitiens ac libenter auscultet, quarto si in omnibus seruet oboedientiae mansuetudinem patientiae que constantiam, quinto si non solum iniuriam inferat nulli, sed ne ab alio quidem sibimet inrogatam doleat atque tristetur, sexto si nihil agat, nihil praesumat, quod non uel communis regula uel maiorum cohortantur exempla, septimo si omni uilitate contentus sit et ad omnia se quae sibi praebentur uelut operarium malum iudicarit indignum, octauo si semet ipsum cunctis inferiorem non superficie pronuntiet labiorum, sed intimo cordis credat affectu, nono si linguam cohibeat uel non sit clamosus in uoce, decimo si non sit facilis ac promptus in risu	Humility is proved by these signs: first, if they have their desires mortified in themselves; second, if they do not conceal not only their actions, but also their thoughts from their superior; third, if they commit all things not to their own judgment but to that of their superior, listening eagerly and willingly to his instructions; fourth, if in all things they preserve the mildness of obedience and the perseverance of patience; fifth, if they not only inflict no injury on anyone, but also bear calmly and without sourness any wrong done to them by another; sixth, if they do nothing and dare nothing except what is supported either by the common rule or by the example of their elders; seventh, if they are content with every meanness and judge themselves unworthy of whatever is offered to them, like a bad workman; eighth, if they sincerely believe in their heart, and not only declare with their lips, that they are inferior to all; ninth, if they restrain their tongue and are not loud of voice; tenth, if they are not ready or quick to laugh	Latin
1857548123237727	6996e2009ed5f	1857369139681484	Si trüg alwegen gnüg snödes und verworffennes gewand, und umb die behütung der demütikeit, in der si vil fúr traff, so wolt si nit tages uff legen nüwe wil und wisz geweschene sleyger, sunder si trüg si ze nacht ze metti, uncz si gealteten und gebrúnt wurden.	She always wore sufficiently shabby and worn-out clothing, and in order to protect the virtue of humility, at which she greatly excelled, similarily she did not want to put on newly white and freshly washed veils during the day. Instead, she wore them tot he nightly mass service until they had become old and browned.	Middle High German
1864339813688486	69f9b7055e4a6	1864338116770483	Ad summum itaque caritatis culmen profecerunt et iam in quarto caritatis gradu positi sunt qui pro amicis animam suam ponere et illud apostolicum implere iam possunt: Estote imitatores Dei sicut filii carissimi, et ambulate in dilectione sicut et Christus dilexit vos et tradidit semetipsum pro vobis oblationem et hostiam Deo in odorem suavitatis. In tertio itaque gradu anima in Deum glorificatur, in quarto propter Deum humiliatur. In tertio gradu conformatur divine claritati, in quarto vero conformatur christiane humilitati.	They have therefore advanced to the supreme summit of charity and are already placed in the fourth degree of charity, those who are already able to lay down their lives for their friends and to fulfil that word of the Apostle: Be imitators of God as most beloved children, and walk in love as Christ also loved you and gave himself up for you as an offering and a sacrifice to God as a fragrant aroma. In the third degree, therefore, the soul is glorified in God; in the fourth it is humbled for God. In the third degree it is conformed to the divine glory; in the fourth, however, it is conformed to Christian humility.	Latin
1864355400736826	69f9f1165603a	\N	Und alsus so hanget rechte der mensche enzwúschent himmel und erden: mit sinen úbersten kreften so ist er erhaben úber sich selber und úber alle ding und wonet in Gotte, aber mit sinen nidersten kreften so ist er verdunst under alle ding in den grunt der demuͤtekeit und ist rechte also ein anhabende mensche, in der allerniedersten uͤbunge kan er sich halten, do er es zuͤ dem aller ersten begunde, und verkleinet kein ding, wie snoͤde es ouch si, und het in eime ieglichem gewaren frieden; und alsus ist er ein wesenlich gezúg unsers herren, das er der ist der von dem himmel kummen ist nider, wider in den himmel gevarn ist und úber alle himmele.	And thus the human being is rightly placed between heaven and earth: with his highest powers he is lifted above himself and above all things and dwells in God; but with his lowest powers he sinks beneath all things into the ground of humility. And thus he is truly a beginner: in the very lowest exercises he can remain there where he first began, and he despises no thing, however base it may be, and in every single thing he has true peace. And thus he is an essential witness of our Lord, that he is the one who came down from heaven, ascended again into heaven, and is above all heavens.	Middle High German
1859817530591260	69b7e8342081c	1857369139681484	Die gieng durch den weg der demütikeit und der gehorsam on clag, und si wandlet under den swestren als ein senftmütiges lempli.\r\n	She went the way of humility and obedience without complaint, and she moved among the sisters like a gentle lamb.	Middle High German
1856276471137690	698460baac59a	1856274655398719	Dictum est quod inuidie mater est superbia, detractionis inuidia, et ita detractio est pessima neptis superbie. Contra istas tres pessimas pestes militat humilitas quasi per antithesim contra toxicum illarum antidotum. 	It has been said that the mother of envy is pride, that envy gives birth to detraction, and thus detraction is the most wicked granddaughter of pride. Against these three most grievous plagues, humility fights as if by antithesis, an antidote to their poison.	Latin
1863795087100863	69f1c9c19cbbf	1857369139681484	Ein durlúchtiger groff von Hasburg genant Götfridus, der sasz etwen an dem redfenster der swestren, und die vor geseite swester wa och do, und der groff befal sich demüttiklich und ernstlich in ir gebet.	A most illustrious count of Habsburg, called Gottfried, was occasionally sitting at the sister’s speaking window, and the aforesaid sister was also present there. The count commended himself humbly and earnestly to her prayers.	Middle High German
1863724264537983	69f0c1ebf3f7f	1857369139681484	In sölichen diensten der miltikeit und der demüttikeit hat si lust, und floch die spil der kinden und ander úppikeit und untugen, mit dem söliche jugent gewonlich bekúmeret ist, waz si flissiklich vermiden.	She took delight in such services of kindness and humility, and she avoided the games of the children and other frivolity and misconduct with which such youth is usually burdened with, which she diligently shunned. 	Middle High German
1870145020650678	6a4e311a264b6	1857369139681484	Öch von grosser demüttikeit müttet si nieman an keinen dienst fúr si ze tünd, wele ir aber út dienstes ted, der kond si gnüg demüttiklich gedancken. Si fleisz sich alwegen ze haben die unwegesten becher, messer, löffel, schússlen und des glich und daz verbrant eschecht brot, die gebrochenen usz gelöffenen eyger, und daz minst angericht. 	Also out of great humility, she never compelled anyone to perform any service for her. But if someone did offer her their services, she would thank that person very humbly. She always strove to take the poorest cups, knives, spoons, bowls, and the like, as well as burnt and stale bread, cracked and emptied eggshells, and the least desirable dishes. 	Middle High German
1860644292478230	69c3f021b4516	1858015725877463	Christus igitur cum in forma Dei esset, non rapinam arbitratus est esse se aequalem Deo, sed semetipsum exinanivit, formam servi accipiens.	Christ, since he was in the form of God, did not con sider it robbery to be equal to God, but emptied himself, taking the form of a servant.	Latin
1864353704027894	69f9eac43a6f6	\N	Die erste pforte an disen uͤbungen das ist ein tieffe verworffene demuͤtekeit, daz der mensche von ime selber zuͦmole nút enthalte und kúnne sich in lidender wisen gedrucken under Got und alle creaturen unde ein ieglich ding wo es herkome, das er daz demuͤtecliche von Gotte neme und von nieman anders, und las sich Gotte in einer demuͤtigen vorhte, in woreme versmohende sich selber in allen dingen, in liebe und in leide, in habende und in darbende.	The first door to these exercises is a deep, cast‑away humility: that a person holds himself to be nothing at all and is able, in a suffering way, to press himself beneath God and all creatures and every thing, wherever it may come from; that he receives it humbly from God and from no one else, and so leaves himself to God in humble fear, in true self‑contempt in all things - in love and in suffering, in having or in want.	Middle High German
1870146813670713	6a4e37c81b539	1857369139681484	Aber denn ligen die schefflin Christi in dem grünen grasz, so si durch demüttikeit sich neigen oder ire knú böigen oder nider fallen uf ire antlit vor dem bild der wirdigen mütter gottes und der lieben heilgen, und si anrüffen zü fúrbittern und zü fúr sprechen vor got irem sun unsrem herren. 	But then Christ's little sheep lie down in the green grass when, through humility, they bow themselves, bend their knees, or fall down upon their faces before the image of worthy Mother of God and the beloved saints, invoking them to plead and to speak on their behalf before God, her Son, our Lord. 	Middle High German
1859824805640975	69b8034e27b0f	1857369139681484	Si waz gewurczlet in so grosser senftmütikeit, daz alle ire wort und werck wider luchten mit den zeichen der demütikeit.	She was rooted in such great gentleness that all her words and deeds, in return, shone forth with the marks of humility. 	Middle High German
1858018789194510	699dbb5ea7b0e	1858017810233858	Humilitatis vero talis potest esse definitio: humilitas est virtus, qua homo verissima sui cognitione sibi ipse vilescit.	Now this can be the definition of humility: humility is the virtue by which a man, through a most truthful knowledge of himself, becomes lowly in his own eyes.	Latin
1873216951180530	6a7ae4ef65cf2	1857369139681484	Der selb herr unser got durch die verdienen und fúrbitten unser heilgen mütteren, von der leben und sitten wir etwaz geschriben hand zü bessrung der noch komenden, geb uns iren füsz stapffen also an ze halten, denn sinn ir demüttikeit und einfaltikeit also ze halten, daz wir durch daz mit wúrcken siner gnoden verdienen ze komen zü der ere der ewigen selikeit, zü der wir on zwiffel glöben daz die selben unser heilgen mütteren komen sigen, amen.\r\n\r\n\r\n	May the same Lord our God, through the merits and intercessions of our holy mothers, concerning whose lives and conduct we have written something for the edification of posterity, grant that we may follow in their footsteps; that is, emulate their humility and simplicity, so that through this, by the working of his grace, we may merit to attain the glory of eternal blessedness, to which, without doubt, we believe these same holy mothers have achieved. Amen.	Middle High German
1864354947548686	69f9ef662460e	\N	 Alles daz der mensche moͤhte haben in eigen willen, es si Got oder creature, do ist ime unzellicher vil nútzer ein willig demuͤtig darben desseben und alles habendes in rechter gelossenheit und in uzgon dins willen in gelossenheit.	All that a person might want to possess in self‑will, be it God or creature, it is for him incomparably more beneficial to be willingly and humbly deprived of that very thing, and to have all things in right letting-go, in the surrender of your will in letting-go.	Middle High German
1857638230018891	699831ad24b4b	1857369139681484	Si waz so grosser senftmütikeit und gedult und demütikeit, da wir si nie hand gesechen erczúrnt, noch si nie hand gehört murmlen oder reden wort des zornes.	She was of such great gentleness, patience, and humility, that we have never seen her mad nor have we ever heard her murmur or say a word of wrath.	Middle High German
1857625626759097	699802b9bcfb9	1857369139681484	Doch wolt si lieber ston in der sicherheit der demütikeit, und alle die volkomenen swestren sacztz si ir selbz zü einem exempel und fleisz sich, ir tugenden sich zü verwunderen und ir verdienen grosz und hoch zü scheczen, aber von ir selben nideren ding ze halten, und in ansechen der andren swestren scheczet si ir leben nit eines ögenblickes wert. 	Yet she preferred to remain within the safety of humility, and she set all the truly perfect sisters before herself as an example. She strove to admire their virtues and to esteem their merits as great and lofty, but to regard herself as lowly; and in comparison with the other sisters she considered her own life not worth even a single moment.	Middle High German
1873225842250665	6a7b060e953a9	1857369139681484	Du sigest gegen in allen demüttig und güttig, und in den dingen, die du hest inen uf ze legen, soltu gebruchen bittung und manung me denn gewalt des gebietten.	Be humble and kind toward them all, and in those matters that you have to impose upon them, you should make rather use petition and exhortation than the power of command. 	Middle High German
1870139523180822	6a4e1c9f5a916	1857369139681484	Do antwirtet si demüttiklich: “Ich mag mit dem leben nit gesechen got minen herren gecrútzget. Wann ich in also ansech so brech mir min hertz.”	She answered humbly: "I cannot behold my Lord God crucified and continue to live. For wherever I look at him, my heart breaks within me."	Middle High German
1864337935995352	69f9b006a91d8	1864337564964356	Familiares autem ipsius sunt: austeritas, continentia, humilitas, simplicitas, ornatus, bona ordinatio, per se sufficientia.	Its companions, moreover, are: austerity, continence, humility, simplicity, refinement, good order, self-sufficiency.	Latin
1870604707961962	6a54e19221c6a	1870309049248986	Humilis mens doctrine sacre legis intendit, actus suos eque moderatur; nimia fastidit, modum studiis suis ponit; deuote mentis conceptum aperit; ad discendum auida, suauis in doctrina; in faciendo iuditio timida, in arguendo difficilis, ad ignoscendum facilis; immobilis in aduersis, in prosperis eadem; in iniuriis secura, de pace sollicita; in amiciciis cauta, in officiis sedula; quietis amica, magnorum magna contemptrix, in prelatione uerecunda, magis seruire quam imperare parata. 	The humble mind attends to the teaching of the sacred law and governs its own actions with equity; it recoils from excess, and sets a measure to its studies; it opens up what a devout mind conceives; eager to learn, it is gentle in teaching; timid in passing judgment, reluctant to reproach, ready to forgive; unmoved in adversity, and the same in prosperity; untroubled under injuries, anxious for peace; cautious in friendships, diligent in its duties; a friend of quiet, a great despiser of great things, modest when placed in authority, more ready to serve than to command	Latin
1860646733992892	69c3f93a1d3bc	1881662123877701	Ideo sequitur humilitas: et procidit in faciem suam, unde exemplum humilitatis ostendit. Et primo propter humilitatem communem, quia humilitas necessaria est ad orationem (Eccli 35,21: “Oratio humiliantis se nubes penetrabit”).	Therefore humility follows: and he fell upon his face, whence he showed an example of humility. And first, on account of the common (general) humility, because humility is necessary for prayer (Sirach 35:21: ‘The prayer of one who humbles himself will pierce the clouds’).	Latin
1861119590980241	69cadac1ada91	1861117094325501	Est igitur humilitas sic descripta imitanda, primo quia sue angustie est paciens tolleratrix; ut matrona a viro suo iniuriose tractata pacienter sustinet ne virum dignum vituperio reddat, et si forte vituperio ex verberis lesio foris appareat, illam caute dissimulat asserens se aliunde tale malum incurrisse. Ecclesiastici 2 dicitur: "Aurum et argentum in igne probantur," etc. Unde Augustinus: "Beati, inquit, humiles qui, etsi quando fieri solet ut iniustas audiant increpaciones, amplius se Christo humilient et minus se audire quam meruerunt proclamant."	Humility as thus defined must be practiced, first because it patiently endures its troubles; just as a wife who is mistreated by her husband suffers it patiently so that she may not cause her husband to become worthy of public shame, and if perhaps, to his shame, some external lesion from his beating can be seen on her, she carefully dissimulates saying she took an injury elsewhere. In Ecclesiasticus 2 it is said: "Gold and silver are tried in the fire," and so forth. Whence Augustine says: "Blessed are the humble who, if it sometimes happens that they hear unjust accusations against them, humble themselves further before Christ and declare the hear less than they have deserved."	Latin
1857631053065982	699816f0aaefe	1857369139681484	O, wölte got, daz wir tregen und hinlessigen in unseren versümnissen und súnden hetten die demütikeit, die die helgen swestren do hand gehept in iren tugenden und güten wercken! 	O, God granted that we, in our shortcomings and sins, possessed the humility that the holy sisters then upheld in their virtues and good works!	Middle High German
1864339191766783	69f9b4b441eff	1864338116770483	In hoc itaque statu anime eiusmodi proponitur forma humilitatis Christi, unde et dicitur ei: Hoc sentite in vobis quod et in Christo Ihesu, qui cum in forma Dei esset, non rapinam arbitratus est esse se equalem Deo, sed semetipsum exinanivit, formam servi accipiens, in similitudinem hominum factus, et habitu inventus ut homo; humiliavit autem semetipsum, factus obediens usque ad mortem, mortem autem crucis. Hec est forma humilitatis Christi ad quam conformare se debet quisquis supremum consummate caritatis gradum attingere volet. Maiorem siquidem caritatem nemo habet quam ut animam suam ponat quis pro amicis suis.	In this state of the soul, therefore, the model of Christ's humility is proposed to it, wherefore it is also said to it: Have this mind in you which was also in Christ Jesus, who, though he was in the form of God, did not count equality with God a thing to be grasped, but emptied himself, taking the form of a servant, made in the likeness of men, and found in appearance as a man; he humbled himself, becoming obedient unto death, even the death of the cross. This is the model of Christ's humility to which whoever wishes to attain the highest and perfect degree of charity must conform himself. For no one has greater charity than this, that a man lay down his life for his friends.	Latin
1873223667510247	6a7afdf496be7	1857369139681484	Din gewand sig haben demüttikeit in der gestalt, hertikeit in dem anrüren, armüt in dem gelt oder kosten.	Your clothing should exhibit humility in appearance, roughness to the touch, and poverty in its price or cost.	Middle High German
1863795484353259	69f1cb3c762eb	1857369139681484	Doch so lucht offenbarlichen in ir gantze gehorssam und grosse demüttikeit. Wann in allen iren tagen ires lebens hat si me denn in allen richtum lust in den wercken der demüttikeit und der verworffenheit.	In her complete obedience and great humility shines forth openly. For throughout all the days of her life she took more delight than all riches in the works of humility and abasement. 	Middle High German
1860646188452840	69c3f731d8be8	\N	Quisquis enim ita humilatur ut genua figat, adhuc habet quo humiletur; quisquis autem sic humilatur et haereat in terra venter eius, ultra quo humiletur non habet. Si enim ultra voluerit, iam non erit humilare, sed obruere.	For whoever humbles himself in such a way as to bend the knee still has room to humble himself further; but whoever humbles himself so deeply that his belly clings to the ground has no further place to humble himself. For if he wanted to go further, it would no longer be humbling, but destroying.	Latin
1861160272319385	69cb724e6d399	1861117094325501	Tertio, quia operum Christi crebra inspectrix et assecutrix. Ad modum quo aquila contra solem irreverberatis oculis respicit, sic vere humilis opera Christi qui est sol iusticie, Ysaie 66: Ad quem aspiciamus nisi ad humilem", scilicet Christum, ut eum imitemur, scilicet quomodo se Patri humiliavit - cui erat equalis in deitate - in assumpcione humane nature; Philippensium 2: "Qui cum in forma Dei esset", etc. Quomodo se eciam humiliavit parentibus in voluntaria subiectione; Luce 2: "Erat subditus illis." Et tertio erat humilis peccatoribus, quia "usque ad mortem", ut sic sibi humiliemus animas nostras, pro peccatis primo corde conterendo, secundo ore confitendo, et tercio opere satisfaciendo. Et de ists quere in titulo "De confessione".	Third, humility must be striven for because it frequently meditates on and follows Christ's deeds. As the eagle looks at the sun with unblinking eyes, just so does a truly humble person look at Christ's deeds, who is the sun of justice. Isaiah 66: "To whom shall we look if not the humble one," that is, Christ, that we may follow him, that is, in the way he has humbled himself before the Father - whose equal he was in divinity -by assuming human nature; Philippians 2: "Who, while he was in the form of God," etc. Further, in the way he humbled himself before his parents in voluntary submission; Luke 2: "He became subject to them." And in the third place he humbled himself before sinners "even unto death," so that we might humble our souls before him, first by having contrition of heart for our sins, second by confession of mouth, and third by satisfaction in deed. On these matters see under the title "On Confession".	Latin
1860643863543677	69c3ee88a3f7d	\N	Si, cum hominibus potentibus volumus aliqua suggerere, son praesuminus nisi cum humilitate et reverentia, quanto magis domino deo universorum cum omni humilitate et puritatis devotione supplicandum est. Et non in multiloquio, sed in puritate cordis et conpunctione lacrimarum nos exaudiri sciamus. Et ideo brevis debet esse et pura oratio, nisi forte ex affectu inspirationis divinae gratiae protendatur. In conventu tamen omnino brevietur oratio, et facto signo a priore pariter surgant.	If, when we wish to make some request to powerful people, we dare not do so except with humility and reverence, how much more must we make supplication to the Lord God of all things with all humility and devotion of purity. And we should know that it is not by much speaking but by purity of heart and compunction of tears that we are heard. And therefore, prayer ought to be short and pure, unless perhaps it is prolonged out of the affection by divine grace. In the convent, however, prayer should always be brief, and at the signal from the prior they should rise together.	Latin
1860629181610070	69c3b7d6db856	\N	Gestus vero corporis est argumentum et probatio mentalis devotionis. Status autem exterioris hominis instruit nos de humilitate et affectu interioris.	The gesture of the body is an argument and a proof of mental devotion. The external state of the human being instructs us of their humility and internal affect.	Latin
1863796149542117	69f1cdb6d5ce5	1857369139681484	Do dient si unsrem herren ernstlich untz in iren tod, in grosser demüttikeit und senftmüttikeit.	Thus she served the Lord earnestly until her death, in great humility and gentleness. 	Middle High German
1870056375622536	6a4ce6dfa9b88	1857369139681484	Doch welt si lieber demüttig und verworffen sin in diser zit, daz si in den himlen mit dester grösserer er wurde schinen vor unsrem herren. Also dient si in der kuchi und in andren diensten der swestren demüttiklich alle ir tag, und si kam zü grosser heilikeit und volkomenheit des lebens mit hilff der gnoden gottes.	Yet, she preffered to be humble and despised in this life, so that she might shine before our Lord in heaven all the more greatly. Thus she served in the kitchen and in other services for the sisters, humbly throughout all her days, and through God's grace she attained great holiness and perfection of life.	Middle High German
1856277857370137	698465e4b0019	1856274953835526	Cognito jam horrendo procinctu superbiae qui trahit ad sinistram, humilitatis exercitum attende qui ducit ad dexteram. Ejus autem hi sunt comitatus principales: Prudentia, justitia, fortitudo, temperantia, fides, spes et charitas.	Now that the dreadful battle array of pride, which draws to the left, has been recognized, turn your attention to the army of humility, which leads to the right. Its principal companions, however, are these: prudence, justice, fortitude, temperance, faith, hope, and charity.	Latin
1873219519418646	6a7aee80a9116	1857369139681484	Der erwirdigen geistlichen dienerin Christi, swester Elisabet, priorin des closters sancti Johannis baptiste in Underlinden prediger ordens, wunschet der demüttig brüder des selben ordens, brüder Johannes, fúr ein grüsz den ursprung und den wúrcker unsers heiles Christum Jhesum ze tragen im hertzen und mit kreften, begeren, und flissen noch ze folgen sinen füsz stapffen úwer götlichen minn.	To Christ’s venerable spiritual servant, sister Elisabet, prioress of the convent St. John the Baptist at Unterlinden of the Order of the Preachers, Brother Johannes, a humble member of the same order, sends greetings, wishing that she may bear in her heart and with all her strength Jesus Christ, the source and author of our salvation, and that through divine love she may desire and diligently endeavor to follow in his footsteps.	Middle High German
1864336536902536	69f9aad061b88	1864335545898141	Duobus modis diabolus humilitatem in nobis oppugnat, per iniuriam videlicet, et per reverentiam. Aliquando enim instigat homines, ut iniuriam nobis inferant; ac per hoc ad indignationem, et ad iram, et ad impatientiam nos pertrahere nititur. Aliquando facit illos nobis reverentiam exhibere, et sic ad vanam gloriam, et inanem laetitiam nos inclinare conatur.	The devil attacks humility in us in two ways, namely through insult and through reverence. For sometimes he incites people to inflict injury upon us, and through this he strives to drag us toward indignation, anger, and impatience. Other times he causes them to show us reverence, and in this way he attempts to incline us toward vainglory and empty joy.	Latin
1863795844188488	69f1cc93a0948	1857369139681484	Sy waz der grösten demüttikeit und gehorssam, und waz alwegen milt und erbarmhertzig, wann durch die meisterschaft der götlichen gnoden hat si gelert milt und demuttig ze sin von hertzen.	She was of the greatest humility and obedience and was always gentle and merciful; for throughout the discipline of divine grace she had learned to be gentle and humble from the heart.	Middle High German
1870309611691221	6a50964065cd5	1870309049248986	Igitur humilitas regina virtutum est, mors viciorum; instrumentum iusticie, nutrix sedula discipline; sanctimonie vigor, sancte religionis rigor; sensati cordis indicium, spiritus sancti testimonium; morum vigilantia, proprie mensure intelligentia; custodia fida virtutum, divine caritatis hospicium; insimulatus affectus, ordo religionis, libertas in periculis, modus in verbis; profectuum magistra, per exemplum doctrix tacita; magnorum contemptus, honeste vite appetitus.	Therefore humility is the queen of the virtues, the death of vices; the instrument of justice, the diligent nurse of discipline; the strength of holiness, the discipline of holy religion; the sign of a wise heart, the testimony of the Holy Spirit; watchfulness over conduct, the knowledge of one's own measure; the faithful guardian of the virtues, the dwelling-place of divine charity; unfeigned affection, the ordering of religious life, freedom amid dangers, restraint in speech; the mistress of spiritual progress, a silent teacher through example; contempt for great things, the desire for an upright life.	Latin
1858204272034099	69a06e58e0133	1861117094325501	Nunc autem expleta parte superbie cum suis membris et oblectamentis offert se domina Humilitas econtra tamquam istorum expugnatrix ac bonorum reparatrix. Ipsa enim est radix et fundamentum omnis boni.	After the section on pride and its members and false pleasures has been completed, Lady humility now rises against them to overcome them and to restore the good qualities. For she is the root and foundation of every good. 	Latin
1881462561569088	6af2e23a3f940	1881462039439812	zuo dissen gelüpten gehört ware demüttikait wann on die so mag man es nit [191r] behalten, wan sy ain muotter vnd ain hütterin ist aller tugenden. Ware demüttikait hät erwa vil aigenschaft[:] Das erst ist sy folget nit iren aignen rätten. Das ander sy hät gern das man sy straff. Dz drit ire claider sind nit mercklich. Dz vierd sy gät mit genaigtem hopt. Das fünfft ir lachen ist beschaiden vnd still. Das sechst sy sind demüttiger senffter red vnd reübent nieman mit iren wortten. Das sibent ir gon vnd ir wandel ist zuchtig. Das achten sy wellent mit erschinen in sunder haillikait. Das nünd sy sind nit strittig, wa man sy an kumet da vint man sy gelässen. Vs wärer demüttikai kumet ware gedultikait.	True humility belongs to these vows, for without it one cannot keep them, since it is the mother and guardian of all virtues. True humility has many characteristics. First, she does not follow her own counsel. Second, she gladly accepts correction. Third, her clothing is plain and unostentatious. Fourth, she goes with her head bowed. Fifth, her laughter is modest and restrained. Sixth, she speaks humbly and gently and harms no one with her words. Seventh, her manner of walking and conduct are modest and disciplined. Eighth, she does not wish to distinguish herself through exceptional holiness. Ninth, she is not contentious; wherever one encounters her, one finds her calm and composed. From true humility comes true patience.	Middle High German
1858203376142245	69a06b027c7a5	1861117094325501	Dico ergo primo quod humilitas est voluntaria mentis inclinacio et proprie excellencie contemptus. 	First, then, I say that humilitas is the voluntary bending of our mind and contempt for our own superiority. 	Latin
1860643125750836	69c3ebc906c34	\N	9 Dixit autem et ad quosdam, qui in se confidebant tamquam iusti, et aspernabantur ceteros, parabolam istam: 10 Duo homines ascenderunt in templum ut orarent: unus pharisaeus, et alter publicanus. 11 Pharisaeus stans, haec apud se orabat: Deus, gratias ago tibi, quia non sum sicut ceteri hominum: raptores, iniusti, adulteri, velut etiam hic publicanus; 12 ieiuno bis in sabbato; decimas do omnium quae possideo. 13 Et publicanus a longe stans, nolebat nec oculos ad caelum levare; sed percutiebat pectus suum, dicens: Deus, propitius esto mihi peccatori. 14 Dico vobis, descendit hic iustificatus in domum suam ab illo: quia omnis qui se exaltat, humiliabitur; et qui se humiliat, exaltabitur.	9 And he spoke also this parable to some who trusted in themselves as being righteous, and despised others: 10 Two men went up into the temple to pray: the one a Pharisee, and the other a publican. 11 The Pharisee, standing, prayed thus with himself:\r\n“God, I give thee thanks that I am not as the rest of men: extortioners, unjust, adulterers; as also is this publican. 12 I fast twice in the week; I give tithes of all that I possess.” 13 And the publican, standing afar off, would not so much as lift up his eyes towards heaven; but struck his breast, saying:“God, be merciful to me a sinner.” 14 I say to you: this man went down to his house justified rather than the other; for every one that exalteth himself shall be humbled: and he that humbleth himself shall be exalted.	Latin
1861121259074547	69cae0f87f3f3	1861117094325501	Secundo, quia mala sua recogitans est bonorum morum occultatrix, sicut pavo aspiciens pedes turpissimos caudam suam dimittit lucentem. Luce 18: "Publicanus a longe stans noluit levare oculos ad celum set percuciens pectus suum ait: 'Deus, propicius,'" etc. Et sequitur: "Amen dico vobis, descendit hic iustificatus in domum suam, quia omnis quis se exaltat, humiliabitur, " etc. 	Humility must be striven for secondly because it reflects on its shortcomings and hides its good qualities, like the peacock which, seeing that its feet are most vile, forgets about its splendid tail. Therefore in Luke 18: "The Publican, standing afar off, would not lift his eyes up to heaven but striking his breast said: 'Lord, have mercy on me,'" etc. And then follows: "Amen, I say to you, this man went down into his house justified, because everyone that exalts himself will be humbled," etc. 	Latin
\.


--
-- Data for Name: string; Type: TABLE DATA; Schema: hum; Owner: -
--

COPY hum.string (id, val, chunk, type) FROM stdin;
1	displaying humble appearance and gesture	1	idea
2	lowering oneself	2	idea
3	accusing oneself	3	idea
4	identifying pride as envy's source	4	idea
5	linking detraction to pride	5	idea
6	opposing vices	6	idea
7	virtue of self-effacement	7	idea
8	humbling before superiors	8	idea
9	humbling before equals	9	idea
10	humbling before inferiors	10	idea
11	recognizing pride's arrangement	11	idea
12	focusing on humility's group	12	idea
13	associating virtues	13	idea
14	wearing poor clothing	14	idea
15	avoiding fresh veils	15	idea
16	using aged items	16	idea
17	staying safe	17	idea
18	setting others as examples	18	idea
19	admiring others' merits	19	idea
20	devaluing oneself	20	idea
21	desiring humility	21	idea
22	imitating sisters	22	idea
23	receiving consolation	23	idea
24	hiding consolation	24	idea
25	possessing virtues	25	idea
26	avoiding anger	26	idea
27	observing God's humility	27	idea
28	describing uniqueness	28	idea
29	God becoming servant	29	idea
30	describing paradoxes	30	idea
31	attributing cause	31	idea
32	defining humility via self-knowledge	32	idea
33	describing humility's value	33	idea
34	defining humility as mental bending	34	idea
35	opposing pride	35	idea
36	establishing goodness	36	idea
37	describing levels of humility	37	idea
38	referencing biblical immersion	38	idea
39	citing source	39	idea
40	mortifying desires	40	idea
41	revealing thoughts	41	idea
42	obeying superior	42	idea
43	preserving obedience	43	idea
44	bearing wrongs	44	idea
45	following rules	45	idea
46	accepting meanness	46	idea
47	believing inferiority	47	idea
48	restraining speech	48	idea
49	avoiding laughter	49	idea
50	following Christ	50	idea
51	persisting on path	51	idea
52	imitating virtues	52	idea
53	exalting via humility	53	idea
54	sisters praising purity	54	idea
55	attributing glory to humility	55	idea
56	denying chastity virtue	56	idea
57	claiming mental folly	57	idea
58	walking humble path	58	idea
59	behaving gently	59	idea
60	serving God humbly	60	idea
61	self-despising proportional to past luxury	61	idea
62	performing menial tasks personally	62	idea
63	assisting others zealously	63	idea
64	delighting in humble works	64	idea
65	being rooted in gentleness	65	idea
66	manifesting humility in actions	66	idea
67	bodily gesture proving mental devotion	67	idea
68	external state indicating internal humility	68	idea
69	addressing self-righteous despisers	69	idea
70	contrasting two pray ers	70	idea
71	thanking God for superiority	71	idea
72	standing afar avoiding eye contact	72	idea
73	pleading mercy as sinner	73	idea
74	humbling leads to exaltation	74	idea
75	supplicating God with humility	75	idea
76	praying with pure devotion	76	idea
77	being heard through purity not speech	77	idea
78	keeping prayer short and pure	78	idea
79	Christ not clinging to divinity	79	idea
80	emptying oneself to serve	80	idea
81	defining prayer as mental devotion	81	idea
82	converting through humble affect	82	idea
83	adopting suitable praying posture	83	idea
84	kneeling expressing humility	84	idea
85	soul following body's disposition	85	idea
86	prioritizing humility in prayer	86	idea
87	kneeling allowing further humbling	87	idea
88	prostration limiting further humbling	88	idea
89	excessive humbling becoming destruction	89	idea
90	demonstrating humility via prostration	90	idea
91	requiring humility for prayer	91	idea
92	humble prayer reaching God	92	idea
93	praying as a servant	93	idea
94	imitating publican's gesture	94	idea
95	confessing sinfulness to God	95	idea
96	seizing God's goodwill	96	idea
97	defining prayer as oral reasoning	97	idea
98	making Lord merciful via devotion	98	idea
99	patiently enduring trouble	101	idea
100	suffering mistreatment patiently	102	idea
101	hiding injuries to protect shame	103	idea
102	dissimulating injury source	104	idea
103	testing virtue like metal	105	idea
104	humbling amidst accusations	106	idea
105	declaring oneself less deserving	107	idea
106	reflecting on shortcomings	108	idea
107	ignoring virtues like peacock	109	idea
108	publican avoiding eye contact	110	idea
109	pleading for mercy	111	idea
110	exaltation leading to humbling	112	idea
111	meditating on Christ's deeds	113	idea
112	looking at Christ like eagle	114	idea
113	Christ being sun of justice	115	idea
114	looking to humble Christ	116	idea
115	humbling before Father via incarnation	117	idea
116	being in form of God	118	idea
117	submitting to parents	119	idea
118	humbling before sinners unto death	120	idea
119	humbling souls via contrition	121	idea
120	becoming humble from exaltation	122	idea
121	delighting in humble services	123	idea
122	avoiding youthful frivolity	124	idea
123	serving with dedication	125	idea
124	handling sick's filth	126	idea
125	touching Christ's wounds via service	127	idea
126	observing humility grace	128	idea
127	showing willingness to obey	129	idea
128	obeying commands without contradiction	130	idea
129	proceeding with reverence	131	idea
130	bending knees humbly	132	idea
131	commending oneself humbly	133	idea
132	humility shining forth	134	idea
133	delighting in humility works	135	idea
134	being humble and obedient	136	idea
135	learning humility through grace	137	idea
136	serving in humility	138	idea
137	equating poverty of spirit with humility	139	idea
138	attacking humility via insult or reverence	140	idea
139	inciting injury to cause anger	141	idea
140	causing reverence to induce vainglory	142	idea
141	keeping faults before eyes	143	idea
142	defining interior and exterior faults	144	idea
143	listing exterior humbling conditions	145	idea
144	judging injuries and reverence correctly	146	idea
145	being a non-excessive disposition	147	idea
146	listing virtue companions	148	idea
147	proposing Christ's humility model	149	idea
148	having Christ's mind	150	idea
149	emptying oneself to serve	151	idea
150	taking servant form	152	idea
151	obeying unto death	153	idea
152	conforming to Christ's humility	154	idea
153	laying down life for friends	155	idea
154	advancing to fourth degree of charity	156	idea
155	laying down lives for friends	157	idea
156	imitating God's love	158	idea
157	being humbled for God	159	idea
158	conforming to Christian humility	160	idea
159	letting go out of love	161	idea
160	giving oneself to God	162	idea
161	being obedient to God's will	163	idea
162	identifying true devotion	164	idea
163	signifying true holiness	165	idea
164	entering via humility	166	idea
165	holding oneself as nothing	167	idea
166	leaving oneself to God	168	idea
167	defining humility as essential art	169	idea
168	being humble in truth	170	idea
169	being deprived of self-will	171	idea
170	surrendering will	172	idea
171	placing human between heaven and earth	173	idea
172	dwelling in God	174	idea
173	sinking into humility	175	idea
174	remaining in lowest exercises	176	idea
175	despising nothing	177	idea
176	witnessing Lord's movement	178	idea
177	submitting to God in prayer	179	idea
178	God wanting humble person	180	idea
179	requesting lifelong lowly service	181	idea
180	preferring lowliness for heavenly glory	182	idea
181	serving sisters modestly daily	183	idea
182	practicing gentle internal and external modesty	184	idea
183	attaining divine sweetness via purity	185	idea
184	possessing virtues including modesty	186	idea
185	standing venerably before another	187	idea
186	requesting hospitality modestly	188	idea
187	expressing modest gratitude	189	idea
188	bestowing blessings modestly	190	idea
189	answering modestly regarding devotion	191	idea
190	feeling emotional pain from devotion	192	idea
191	living a modest life	193	idea
192	recording personal shortcomings	194	idea
193	reading for self-abasement	195	idea
194	refusing service from others	196	idea
195	thanking servants modestly	197	idea
196	choosing poorest items	198	idea
197	choosing worst food and dishes	199	idea
198	humbling oneself like sheep	200	idea
199	prostrating before holy images	201	idea
200	identifying Jesus Christ	202	idea
201	sanctifying penance via modesty	203	idea
202	ruling virtues and killing vices	204	idea
203	enabling justice and discipline	205	idea
204	teaching spiritual progress silently	206	idea
205	following law and governing actions equitably	207	idea
206	serving rather than commanding	208	idea
207	displaying steady physical demeanor	209	idea
208	thanking God without presuming merit	210	idea
209	emulating modesty and simplicity	211	idea
210	greeting modestly	212	idea
211	following Christ's footsteps via love	213	idea
212	humbling oneself for healing	214	idea
213	wearing modest clothing	215	idea
214	possessing modesty with Mary	216	idea
215	fear arising from and creating modesty	217	idea
216	escaping evil spirit snares	218	idea
217	The signs of humility are humility in garment, in expression, and in gesture;	1	text
218	[A sign of humility] is self-abasement;	2	text
219	and [a sign of humility is] a strong eagerness to accuse oneself.	3	text
220	It has been said that the mother of envy is pride,	4	text
221	that envy gives birth to detraction, and thus detraction is the most wicked granddaughter of pride.	5	text
222	Against these three most grievous plagues, humility fights as if by antithesis, an antidote to their poison.	6	text
223	Humility is the virtue by which the soul, exalting itself in nothing and attributing no good to itself, even outwardly prefers the appearance of lowliness.	7	text
224	Humility, moreover, is divided into three kinds: into that by which a person humbles himself before one who is greater, which is called sufficient;	8	text
225	and into that by which a person humbles himself before an equal, which is called perfect	9	text
226	and into that by which he humbles himself before one who is lesser, which is called superabundant.	10	text
227	Now that the dreadful battle array of pride, which draws to the left, has been recognized,	11	text
228	turn your attention to the army of humility, which leads to the right.	12	text
229	Its principal companions, however, are these: prudence, justice, fortitude, temperance, faith, hope, and charity.	13	text
230	She always wore sufficiently shabby and worn-out clothing,	14	text
231	and in order to protect the virtue of humility, at which she greatly excelled, similarily she did not want to put on newly white and freshly washed veils during the day.	15	text
232	Instead, [she] wore them to the nightly mass service until they had become old and browned.	16	text
233	Yet [she] preferred to remain within the safety of humility,	17	text
234	and [she] set all the truly perfect sisters before herself as an example.	18	text
235	[She] strove to admire their virtues and to esteem their merits as great and lofty, but to regard herself as lowly;	19	text
236	and in comparison with the other sisters [she] considered her own life not worth even a single moment.	20	text
237	O, God granted that we, in our shortcomings and sins, possessed the humility	21	text
238	that the holy sisters then upheld in their virtues and good works!	22	text
239	God the Lord granted her many other forms of consolation in secrecy,	23	text
240	but because she was very coy and deeply humble, she did not want to reveal them.	24	text
241	She was of such great gentleness, patience, and humility,	25	text
242	that we have never seen her mad nor have we ever heard her murmur or say a word of wrath.	26	text
243	Behold the incomparable humility of God!	27	text
244	In comparable, because it does not admit a worthy comparison; inestimable, because it is not able to be measured; ineffable, because it cannot be explained with words:	28	text
245	that the God and Lord of all should become a man and the servant of all,	29	text
246	that the invisible should be seen, that the Lord, the bread of angels would be nourished, that the power of the heavens should be made weak, that life should die.	30	text
247	The cause of this mystery is the justice and mercy of God.	31	text
248	Now this can be the definition of humility: humility is the virtue by which a man, through a most truthful knowledge of himself, becomes lowly in his own eyes.	32	text
249	Humility is a glorious thing, so glorious that even pride itself seeks to cloak itself with it, lest it become despised.	33	text
250	First, then, I say that humilitas is the voluntary bending of our mind and contempt for our own superiority.	34	text
251	After the section on pride and its members and false pleasures has been completed, Lady humility now rises against them to overcome them and to restore the good qualities.	35	text
252	For she is the root and foundation of every good.	36	text
253	These are those three immersions into the river of humility, which descend downward,	37	text
254	in which Ezekiel was immersed—up to the ankles, up to the knees, or up to the loins—	38	text
255	as is found in chapter 47 of the same book.	39	text
256	Humility is proved by these signs: first, if they have their desires mortified in themselves;	40	text
257	second, if they do not conceal not only their actions, but also their thoughts from their superior;	41	text
258	third, if they commit all things not to their own judgment but to that of their superior, listening eagerly and willingly to his instructions;	42	text
259	fourth, if in all things they preserve the mildness of obedience and the perseverance of patience;	43	text
260	fifth, if they not only inflict no injury on anyone, but also bear calmly and without sourness any wrong done to them by another;	44	text
261	sixth, if they do nothing and dare nothing except what is supported either by the common rule or by the example of their elders;	45	text
262	seventh, if they are content with every meanness and judge themselves unworthy of whatever is offered to them, like a bad workman;	46	text
263	eighth, if they sincerely believe in their heart, and not only declare with their lips, that they are inferior to all;	47	text
264	ninth, if they restrain their tongue and are not loud of voice;	48	text
265	tenth, if they are not ready or quick to laugh	49	text
266	She set her steps upon the footsteps of our Lord Jesus Christ	50	text
267	and did not turn back nor step aside until she had completed the course of her path,	51	text
268	following his humility, his patience, his love and the other virtues that he had taught by words and by example.	52	text
269	Her deep and true humility always exalts her before my sight.	53	text
270	And when the sisters to whom she said this were astonishing and spoke of her blessedness because of her great purity,	54	text
271	she immediately turned herself back to the earning of humility, which so surpassingly gives glory to the divine gift of grace,	55	text
272	and said: You should know in truth that it does not come from the virtue of chastity, that I am unable to think of impure things;	56	text
273	rather, it is the folly of my mind.	57	text
274	She went the way of humility and obedience without complaint,	58	text
275	and she moved among the sisters like a gentle lamb.	59	text
276	she devoted herself to serving our Lord with a pure heart, in humility and in gentleness	60	text
277	in all things she so thoroughly despises and casts herself aside, in proportion as her life in the world	61	text
278	Each day she washed bowls and other kitchen vessels with her own hands together with the serving girls	62	text
279	and she also zealously helped them in other tasks that were required, wherever she was able to assist them.	63	text
280	In these works and the like she took as much delight as in all riches.	64	text
281	She was rooted in such great gentleness that all her words and deeds, in return, shone forth	65	text
282	with the marks of humility.	66	text
283	The gesture of the body is an argument and a proof of mental devotion.	67	text
284	The external state of the human being instructs us of their humility and internal affect.	68	text
285	And he spoke also this parable to some who trusted in themselves as being righteous, and despised others:	69	text
286	Two men went up into the temple to pray: the one a Pharisee, and the other a publican.	70	text
287	The Pharisee, standing, prayed thus with himself: «God, I give thee thanks that I am not as the rest of men	71	text
288	And the publican, standing afar off, would not so much as lift up his eyes towards heaven;	72	text
289	but struck his breast, saying:«God, be merciful to me a sinner.»	73	text
290	for every one that exalteth himself shall be humbled: and he that humbleth himself shall be exalted.	74	text
291	we dare not do so except with humility and reverence, how much more must we make supplication to the Lord God	75	text
292	with all humility and devotion of purity.	76	text
293	it is not by much speaking but by purity of heart and compunction of tears that we are heard.	77	text
294	And therefore, prayer ought to be short and pure, unless perhaps it is prolonged out of the affection by divine grace.	78	text
295	Christ, since he was in the form of God, did not con sider it robbery to be equal to God,	79	text
296	but emptied himself, taking the form of a servant.	80	text
297	Therefore, prayer is nothing else than devotion of the mind, that is: a conversion towards God	81	text
298	through a pious and humble affect; belief, hope and love attached.	82	text
299	kneeling with the head and eyes raised, and with the hands joined, is among all postures the most suitable for praying	83	text
300	For kneeling expresses humility; and the raising of the head and the eyes is easily followed	84	text
301	by the raising of the heart, because the soul, on account of its connection with the body, easily follows the body's dispositions.	85	text
302	Now nothing is more useful in prayer than humility, attentiveness, and heartfelt devotion.	86	text
303	whoever humbles himself in such a way as to bend the knee still has room to humble himself further;	87	text
304	but whoever humbles himself so deeply that his belly clings to the ground has no further place to humble himself.	88	text
305	For if he wanted to go further, it would no longer be humbling, but destroying.	89	text
306	and he fell upon his face, whence he showed an example of humility.	90	text
307	because humility is necessary for prayer	91	text
308	(Sirach 35:21: 'The prayer of one who humbles himself will pierce the clouds').	92	text
309	the one praying takes on the form of a servant, humbly and fearfully appealing to his Lord and Judge for mercy,	93	text
310	like that publican who did not dare to lift his eyes to heaven, but struck his breast,	94	text
311	saying: God, be merciful to me, a sinner.	95	text
312	Prayer is to seize the goodwill of God.	96	text
313	Cassidorus adds: Prayer is oral reasoning, frequent deprecation and constant supplication, which proceeds from the depths of the heart	97	text
314	with piety and devotion. The effect of prayer is to make the Lord merciful and favorable to us.	98	text
315	Humility as thus defined must be practiced, first because it patiently endures its troubles;	101	text
316	just as a wife who is mistreated by her husband suffers it patiently so that she may not cause her husband	102	text
317	to become worthy of public shame, and if perhaps, to his shame, some external lesion from his beating can be seen on her,	103	text
318	she carefully dissimulates saying she took an injury elsewhere.	104	text
319	In Ecclesiasticus 2 it is said: «Gold and silver are tried in the fire,» and so forth.	105	text
320	Whence Augustine says: «Blessed are the humble who, if it sometimes happens that they hear unjust accusations against them,	106	text
321	humble themselves further before Christ and declare the hear less than they have deserved.»	107	text
322	Humility must be striven for secondly because it reflects on its shortcomings and hides its good qualities,	108	text
323	like the peacock which, seeing that its feet are most vile, forgets about its splendid tail.	109	text
324	Therefore in Luke 18: «The Publican, standing afar off, would not lift his eyes up to heaven	110	text
325	but striking his breast said: 'Lord, have mercy on me,'» etc.	111	text
326	because everyone that exalts himself will be humbled,» etc.	112	text
327	humility must be striven for because it frequently meditates on and follows Christ's deeds.	113	text
328	As the eagle looks at the sun with unblinking eyes, just so does a truly humble person look at Christ's deeds,	114	text
329	who is the sun of justice.	115	text
330	Isaiah 66: «To whom shall we look if not the humble one,» that is, Christ, that we may follow him,	116	text
331	in the way he has humbled himself before the Father - whose equal he was in divinity -by assuming human nature;	117	text
332	Philippians 2: «Who, while he was in the form of God,» etc.	118	text
333	Further, in the way he humbled himself before his parents in voluntary submission; Luke 2: «He became subject to them.»	119	text
334	And in the third place he humbled himself before sinners «even unto death,»	120	text
335	so that we might humble our souls before him, first by having contrition of heart for our sins,	121	text
336	«I who was great and exalted in the highest realm, became, for your sake, small and humble upon the earth.»	122	text
337	She took delight in such services of kindness and humility,	123	text
338	and she avoided the games of the children and other frivolity and misconduct with which such youth is usually burdened with, which she diligently shunned.	124	text
339	She serves them with tireless dedication, with gentle care and unwearied diligence;	125	text
340	and not only does she serve them in this constancy, but she also handles the filth and the sores of the sick	126	text
341	with her own hands, so humbly, so worthily, and so faithfully, as if she were touching the holy wounds of Christ.	127	text
342	But among other virtues of her disposition we have observed in her a grace of humility and obedience worthy of admiration,	128	text
343	so that [she] never show herself unwilling to obey with a single word;	129	text
344	rather, without contradiction, [she] obeyed the will of those who command or instruct her in all things.	130	text
345	together with her particular messenger and herald, the holy archangel Gabriel, proceeded forward toward the altar with the greatest reverence;	131	text
346	and on the right side of the altar they humbly bent their holy knees.	132	text
347	The count commended himself humbly and earnestly to her prayers.	133	text
348	In her complete obedience and great humility shines forth openly.	134	text
349	For throughout all the days of her life she took more delight than all riches in the works of humility and abasement.	135	text
350	She was of the greatest humility and obedience and was always gentle and merciful;	136	text
351	for throughout the discipline of divine grace [she] had learned to be gentle and humble from the heart.	137	text
352	Thus [she] served the Lord earnestly until her death, in great humility and gentleness.	138	text
353	First, poverty of spirit, that is, humility;	139	text
354	The devil attacks humility in us in two ways, namely through insult and through reverence.	140	text
355	For sometimes he incites people to inflict injury upon us, and through this he strives to drag us toward indignation, anger, and impatience.	141	text
356	Other times he causes them to show us reverence, and in this way he attempts to incline us toward vainglory and empty joy.	142	text
357	But if we truly wish to keep our humility unharmed against these battles of the enemy, let us strive to keep our own faults constantly before our eyes.	143	text
358	By faults, however, I mean not only the interior ones, which pertain to iniquity and sin, but also the exterior ones, which pertain to our benefit:	144	text
359	such as lowliness of birth, poverty — which is the mother of want — weakness of body, and whatever else of this kind humbles a person.	145	text
360	For if we are willing to look well and attentively upon our sins and our miseries, then perhaps we will judge it neither undeserved, if an injury is inflicted upon us, nor deserved, if reverence is shown.	146	text
361	Humility, moreover, is a disposition that is not excessive in expenditures and preparations.	147	text
362	Its companions, moreover, are: austerity, continence, humility, simplicity, refinement, good order, self-sufficiency.	148	text
363	In this state of the soul, therefore, the model of Christ's humility is proposed to it,	149	text
364	wherefore it is also said to it: Have this mind in you which was also in Christ Jesus,	150	text
365	who, though he was in the form of God, did not count equality with God a thing to be grasped, but emptied himself,	151	text
366	taking the form of a servant, made in the likeness of men, and found in appearance as a man;	152	text
367	he humbled himself, becoming obedient unto death, even the death of the cross.	153	text
368	This is the model of Christ's humility to which whoever wishes to attain the highest and perfect degree of charity must conform himself.	154	text
369	For no one has greater charity than this, that a man lay down his life for his friends.	155	text
370	They have therefore advanced to the supreme summit of charity and are already placed in the fourth degree of charity,	156	text
371	those who are already able to lay down their lives for their friends and to fulfil that word of the Apostle:	157	text
372	Be imitators of God as most beloved children, and walk in love as Christ also loved you and gave himself up for you as an offering and a sacrifice to God as a fragrant aroma.	158	text
373	In the third degree, therefore, the soul is glorified in God; in the fourth it is humbled for God.	159	text
374	In the third degree it is conformed to the divine glory; in the fourth, however, it is conformed to Christian humility.	160	text
375	But whoever lets himself go in everything out of godly love with a pure and clear heart,	161	text
376	and with a good consciousness and with a true, strong, unfaked faith, and who gives oneself to God completely in love and pain;	162	text
377	and whoever is thankfully obedient with plain words in all pain and hardship and sadness, [whoever is thankfully obedient] to gods will, humbly,	163	text
378	with chosen patience and reliance, look: this is the right, true, safe and certain kind of devotion,	164	text
379	and it is also good and just, always from God, never from nature or the evil spirit, and it is furthermore a safe and certain sign of right, true holiness and right devotion.	165	text
380	The first door to these exercises is a deep, cast‑away humility:	166	text
381	that a person holds himself to be nothing at all and is able, in a suffering way, to press himself beneath God and all creatures and every thing, wherever it may come from;	167	text
382	that he receives it humbly from God and from no one else, and so leaves himself to God in humble fear, in true self‑contempt in all things - in love and in suffering, in having or in want.	168	text
383	This is an art in which all arts are enclosed that one needs for true holiness: namely true humility,	169	text
384	without all gloss or pretense, not in words or in outward appearance, but in truth and in the ground.	170	text
385	All that a person might want to possess in self‑will, be it God or creature, it is for him incomparably more beneficial to be willingly and humbly deprived of that very thing,	171	text
386	and to have all things in right letting-go, in the surrender of your will in letting-go.	172	text
387	And thus the human being is rightly placed between heaven and earth:	173	text
388	with his highest powers he is lifted above himself and above all things and dwells in God;	174	text
389	but with his lowest powers he sinks beneath all things into the ground of humility.	175	text
390	And thus he is truly a beginner: in the very lowest exercises he can remain there where he first began,	176	text
391	and he despises no thing, however base it may be, and in every single thing he has true peace.	177	text
392	And thus he is an essential witness of our Lord, that he is the one who came down from heaven, ascended again into heaven, and is above all heavens.	178	text
393	That the soul should enter with love, with outmost desire, humbly submitting to God - this alone is true prayer.	179	text
394	God is searching for and wants to have a humble person, a gentle-minded person, a poor person, a pure person, and a let-go person who perseveres in equanimity.	180	text
395	After that, [she] humbly and earnestly requested she be accepted into the convent for service in the kitchen as long as she lived.	181	text
396	Yet, [she] preffered to be humble and despised in this life, so that she might shine before our Lord in heaven	182	text
397	Thus [she] served in the kitchen and in other services for the sisters, humbly throughout all her days,	183	text
398	through gentle humility of the heart and outward conduct,	184	text
399	a divine heavenly sweetness that is attained in this life thorugh purity of the inner and outer person,	185	text
400	«Have charity, preserve humility, posess voluntary poverty.»	186	text
401	The brothers and the aforementioned Sister Getrut stood up venerably before her,	187	text
402	and with [humility] told her that they had come there at that time to search for hospitality.	188	text
403	She and the provincial, together with his companions, expressed to that woman humble and heartfelt gratitude and thanks	189	text
404	They humbly bestowed their blessings upon her and then departed.	190	text
405	She answered humbly: «I cannot behold my Lord God crucified and continue to live.	191	text
406	For wherever I look at him, my heart breaks within me.»	192	text
407	Thus the sister retunred and thereafter lived a life of extraordinary humility.	193	text
408	She wrote down for herself on a slip of paper all her bodily and spiritual shortcomings,	194	text
409	and she often read it for her own humbling.	195	text
410	Also out of great humility, [she] never compelled anyone to perform any service for her.	196	text
411	But if someone did offer her their services, [she] would thank that person very humbly.	197	text
412	She always strove to take the poorest cups, knives, spoons, bowls, and the like,	198	text
413	as well as burnt and stale bread, cracked and emptied eggshells, and the least desirable dishes.	199	text
414	But then Christ's little sheep lie down in the green grass when, through humility, they bow themselves,	200	text
415	bend their knees, or fall down upon their faces before the image of worthy Mother of God and the beloved saints,	201	text
416	The same gracious God, the Son of the eternal God, our Lord Jesus Christ,	202	text
417	and who, in the days of his humility, himself sanctified the sacrament of perfect penance	203	text
418	Therefore humility is the queen of the virtues, the death of vices;	204	text
419	the instrument of justice, the diligent nurse of discipline;	205	text
420	the mistress of spiritual progress, a silent teacher through example;	206	text
421	The humble mind attends to the teaching of the sacred law and governs its own actions with equity;	207	text
422	modest when placed in authority, more ready to serve than to command	208	text
423	In the humble person there is an even bearing, a steady gait, a grave countenance,	209	text
424	thanksgiving always directed on high for any progress, and never any presumption about one's own merits.	210	text
425	grant that we may follow in their footsteps; that is, emulate their humility and simplicity,	211	text
426	Brother Johannes, a humble member of the same order, sends greetings,	212	text
427	and that through divine love she may desire and diligently endeavor to follow in his footsteps.	213	text
428	Then [she] humbly fell in venia to the ground and was thereafter fully healed.	214	text
429	Your clothing should exhibit humility in appearance, roughness to the touch, and poverty in its price or cost.	215	text
430	all the aforementioned things will be of no use to you unless you possess, together with the blessed Virgin Mary, the deepest humility of all.	216	text
431	This is the fear that arises from humility and in turn gives rise to humility,	217	text
432	which alone disentangled itself from the snares of the evil spirit,	218	text
\.


--
-- Data for Name: work; Type: TABLE DATA; Schema: hum; Owner: -
--

COPY hum.work (id, uri, label, year) FROM stdin;
\.


--
-- Data for Name: _config; Type: TABLE DATA; Schema: nlpg; Owner: -
--

COPY nlpg._config (key, value) FROM stdin;
\.


--
-- Data for Name: _textobj; Type: TABLE DATA; Schema: nlpg; Owner: -
--

COPY nlpg._textobj (text_id, sent_i, type, i, idx, len, s, tspace, norm, pos, morph, lemma, dep, head, userdata) FROM stdin;
\.


--
-- Data for Name: dep; Type: TABLE DATA; Schema: nlpg; Owner: -
--

COPY nlpg.dep (id, name, definition) FROM stdin;
1	ROOT	\N
2	acl	\N
3	acomp	\N
4	advcl	\N
5	advmod	\N
6	agent	\N
7	amod	\N
8	appos	\N
9	attr	\N
10	aux	\N
11	auxpass	\N
12	case	\N
13	cc	\N
14	ccomp	\N
15	compound	\N
16	conj	\N
17	csubj	\N
18	csubjpass	\N
19	dative	\N
20	dep	\N
21	det	\N
22	dobj	\N
23	expl	\N
24	intj	\N
25	mark	\N
26	meta	\N
27	neg	\N
28	nmod	\N
29	npadvmod	\N
30	nsubj	\N
31	nsubjpass	\N
32	nummod	\N
33	oprd	\N
34	parataxis	\N
35	pcomp	\N
36	pobj	\N
37	poss	\N
38	preconj	\N
39	predet	\N
40	prep	\N
41	prt	\N
42	punct	\N
43	quantmod	\N
44	relcl	\N
45	xcomp	\N
\.


--
-- Data for Name: has_synset; Type: TABLE DATA; Schema: nlpg; Owner: -
--

COPY nlpg.has_synset (lemma, synset, n) FROM stdin;
\.


--
-- Data for Name: lemma; Type: TABLE DATA; Schema: nlpg; Owner: -
--

COPY nlpg.lemma (id, lemma, pos, stem) FROM stdin;
\.


--
-- Data for Name: lexeme; Type: TABLE DATA; Schema: nlpg; Owner: -
--

COPY nlpg.lexeme (id, lemma, morph, norm) FROM stdin;
\.


--
-- Data for Name: markup; Type: TABLE DATA; Schema: nlpg; Owner: -
--

COPY nlpg.markup (id, text) FROM stdin;
\.


--
-- Data for Name: morph; Type: TABLE DATA; Schema: nlpg; Owner: -
--

COPY nlpg.morph (id, feats, j, numtype, number, person, prontype, mood, tense, definite, verbform, voice, reflex, polarity, number_psor, poss) FROM stdin;
\.


--
-- Data for Name: pos; Type: TABLE DATA; Schema: nlpg; Owner: -
--

COPY nlpg.pos (id, name, definition) FROM stdin;
1		\N
2	adj	\N
3	adp	\N
4	adv	\N
5	aux	\N
6	conj	\N
7	cconj	\N
8	det	\N
9	intj	\N
10	noun	\N
11	num	\N
12	part	\N
13	pron	\N
14	propn	\N
15	punct	\N
16	sconj	\N
17	sym	\N
18	verb	\N
19	x	\N
20	eol	\N
21	space	\N
\.


--
-- Data for Name: sent; Type: TABLE DATA; Schema: nlpg; Owner: -
--

COPY nlpg.sent (string, i, id) FROM stdin;
\.


--
-- Data for Name: span; Type: TABLE DATA; Schema: nlpg; Owner: -
--

COPY nlpg.span (string, id, idx, len, attrs) FROM stdin;
\.


--
-- Data for Name: stopword; Type: TABLE DATA; Schema: nlpg; Owner: -
--

COPY nlpg.stopword (norm) FROM stdin;
\.


--
-- Data for Name: synset; Type: TABLE DATA; Schema: nlpg; Owner: -
--

COPY nlpg.synset (id, label, hypernym_paths, lemmas, definition, examples) FROM stdin;
\.


--
-- Data for Name: token; Type: TABLE DATA; Schema: nlpg; Owner: -
--

COPY nlpg.token (sent, i, idx, len, s, tspace) FROM stdin;
\.


--
-- Data for Name: word; Type: TABLE DATA; Schema: nlpg; Owner: -
--

COPY nlpg.word (sent, i, idx, len, s, tspace, dep, lexeme, head) FROM stdin;
\.


--
-- Data for Name: xspan; Type: TABLE DATA; Schema: nlpg; Owner: -
--

COPY nlpg.xspan (string, id, idx, len, attrs, tag) FROM stdin;
\.


--
-- Data for Name: xtag; Type: TABLE DATA; Schema: nlpg; Owner: -
--

COPY nlpg.xtag (sid, idxtext, idxxml, len, s) FROM stdin;
\.


--
-- Name: string_id_seq; Type: SEQUENCE SET; Schema: hum; Owner: -
--

SELECT pg_catalog.setval('hum.string_id_seq', 432, true);


--
-- Name: dep_id_seq; Type: SEQUENCE SET; Schema: nlpg; Owner: -
--

SELECT pg_catalog.setval('nlpg.dep_id_seq', 45, true);


--
-- Name: lemma_id_seq; Type: SEQUENCE SET; Schema: nlpg; Owner: -
--

SELECT pg_catalog.setval('nlpg.lemma_id_seq', 1, false);


--
-- Name: lexeme_id_seq; Type: SEQUENCE SET; Schema: nlpg; Owner: -
--

SELECT pg_catalog.setval('nlpg.lexeme_id_seq', 1, false);


--
-- Name: morph_id_seq; Type: SEQUENCE SET; Schema: nlpg; Owner: -
--

SELECT pg_catalog.setval('nlpg.morph_id_seq', 1, false);


--
-- Name: pos_id_seq; Type: SEQUENCE SET; Schema: nlpg; Owner: -
--

SELECT pg_catalog.setval('nlpg.pos_id_seq', 21, true);


--
-- Name: sent_id_seq; Type: SEQUENCE SET; Schema: nlpg; Owner: -
--

SELECT pg_catalog.setval('nlpg.sent_id_seq', 1, false);


--
-- Name: synset_id_seq; Type: SEQUENCE SET; Schema: nlpg; Owner: -
--

SELECT pg_catalog.setval('nlpg.synset_id_seq', 1, false);


--
-- Name: chunk chunk_pkey; Type: CONSTRAINT; Schema: hum; Owner: -
--

ALTER TABLE ONLY hum.chunk
    ADD CONSTRAINT chunk_pkey PRIMARY KEY (id);


--
-- Name: passage passage_pkey; Type: CONSTRAINT; Schema: hum; Owner: -
--

ALTER TABLE ONLY hum.passage
    ADD CONSTRAINT passage_pkey PRIMARY KEY (id);


--
-- Name: string string_pkey; Type: CONSTRAINT; Schema: hum; Owner: -
--

ALTER TABLE ONLY hum.string
    ADD CONSTRAINT string_pkey PRIMARY KEY (id);


--
-- Name: work work_pkey; Type: CONSTRAINT; Schema: hum; Owner: -
--

ALTER TABLE ONLY hum.work
    ADD CONSTRAINT work_pkey PRIMARY KEY (id);


--
-- Name: dep dep_name_key; Type: CONSTRAINT; Schema: nlpg; Owner: -
--

ALTER TABLE ONLY nlpg.dep
    ADD CONSTRAINT dep_name_key UNIQUE (name);


--
-- Name: dep dep_pkey; Type: CONSTRAINT; Schema: nlpg; Owner: -
--

ALTER TABLE ONLY nlpg.dep
    ADD CONSTRAINT dep_pkey PRIMARY KEY (id);


--
-- Name: has_synset has_synset_lemma_n_key; Type: CONSTRAINT; Schema: nlpg; Owner: -
--

ALTER TABLE ONLY nlpg.has_synset
    ADD CONSTRAINT has_synset_lemma_n_key UNIQUE (lemma, n);


--
-- Name: has_synset has_synset_lemma_synset_key; Type: CONSTRAINT; Schema: nlpg; Owner: -
--

ALTER TABLE ONLY nlpg.has_synset
    ADD CONSTRAINT has_synset_lemma_synset_key UNIQUE (lemma, synset);


--
-- Name: lemma lemma_lemma_pos_key; Type: CONSTRAINT; Schema: nlpg; Owner: -
--

ALTER TABLE ONLY nlpg.lemma
    ADD CONSTRAINT lemma_lemma_pos_key UNIQUE (lemma, pos);


--
-- Name: lemma lemma_pkey; Type: CONSTRAINT; Schema: nlpg; Owner: -
--

ALTER TABLE ONLY nlpg.lemma
    ADD CONSTRAINT lemma_pkey PRIMARY KEY (id);


--
-- Name: lexeme lexeme_pkey; Type: CONSTRAINT; Schema: nlpg; Owner: -
--

ALTER TABLE ONLY nlpg.lexeme
    ADD CONSTRAINT lexeme_pkey PRIMARY KEY (id);


--
-- Name: lexeme lexeme_uniq; Type: CONSTRAINT; Schema: nlpg; Owner: -
--

ALTER TABLE ONLY nlpg.lexeme
    ADD CONSTRAINT lexeme_uniq UNIQUE (lemma, norm, morph);


--
-- Name: morph morph_feats_key; Type: CONSTRAINT; Schema: nlpg; Owner: -
--

ALTER TABLE ONLY nlpg.morph
    ADD CONSTRAINT morph_feats_key UNIQUE (feats);


--
-- Name: morph morph_pkey; Type: CONSTRAINT; Schema: nlpg; Owner: -
--

ALTER TABLE ONLY nlpg.morph
    ADD CONSTRAINT morph_pkey PRIMARY KEY (id);


--
-- Name: pos pos_name_key; Type: CONSTRAINT; Schema: nlpg; Owner: -
--

ALTER TABLE ONLY nlpg.pos
    ADD CONSTRAINT pos_name_key UNIQUE (name);


--
-- Name: pos pos_pkey; Type: CONSTRAINT; Schema: nlpg; Owner: -
--

ALTER TABLE ONLY nlpg.pos
    ADD CONSTRAINT pos_pkey PRIMARY KEY (id);


--
-- Name: sent sent_pkey; Type: CONSTRAINT; Schema: nlpg; Owner: -
--

ALTER TABLE ONLY nlpg.sent
    ADD CONSTRAINT sent_pkey PRIMARY KEY (id);


--
-- Name: stopword stopword_pkey; Type: CONSTRAINT; Schema: nlpg; Owner: -
--

ALTER TABLE ONLY nlpg.stopword
    ADD CONSTRAINT stopword_pkey PRIMARY KEY (norm);


--
-- Name: synset synset_label_key; Type: CONSTRAINT; Schema: nlpg; Owner: -
--

ALTER TABLE ONLY nlpg.synset
    ADD CONSTRAINT synset_label_key UNIQUE (label);


--
-- Name: synset synset_pkey; Type: CONSTRAINT; Schema: nlpg; Owner: -
--

ALTER TABLE ONLY nlpg.synset
    ADD CONSTRAINT synset_pkey PRIMARY KEY (id);


--
-- Name: token token_sent_i_key; Type: CONSTRAINT; Schema: nlpg; Owner: -
--

ALTER TABLE ONLY nlpg.token
    ADD CONSTRAINT token_sent_i_key UNIQUE (sent, i);


--
-- Name: word word_sent_i_key; Type: CONSTRAINT; Schema: nlpg; Owner: -
--

ALTER TABLE ONLY nlpg.word
    ADD CONSTRAINT word_sent_i_key UNIQUE (sent, i);


--
-- Name: dep_name_idx; Type: INDEX; Schema: nlpg; Owner: -
--

CREATE INDEX dep_name_idx ON nlpg.dep USING btree (name);


--
-- Name: lemma_pos_idx; Type: INDEX; Schema: nlpg; Owner: -
--

CREATE INDEX lemma_pos_idx ON nlpg.lemma USING btree (pos);


--
-- Name: lexeme_lemma_idx; Type: INDEX; Schema: nlpg; Owner: -
--

CREATE INDEX lexeme_lemma_idx ON nlpg.lexeme USING btree (lemma);


--
-- Name: lexeme_morph_idx; Type: INDEX; Schema: nlpg; Owner: -
--

CREATE INDEX lexeme_morph_idx ON nlpg.lexeme USING btree (morph);


--
-- Name: lexeme_norm_idx; Type: INDEX; Schema: nlpg; Owner: -
--

CREATE INDEX lexeme_norm_idx ON nlpg.lexeme USING btree (norm);


--
-- Name: morph_feats_idx; Type: INDEX; Schema: nlpg; Owner: -
--

CREATE INDEX morph_feats_idx ON nlpg.morph USING btree (feats);


--
-- Name: morph_j_idx; Type: INDEX; Schema: nlpg; Owner: -
--

CREATE INDEX morph_j_idx ON nlpg.morph USING btree (j);


--
-- Name: pos_name_idx; Type: INDEX; Schema: nlpg; Owner: -
--

CREATE INDEX pos_name_idx ON nlpg.pos USING btree (name);


--
-- Name: sent_i_idx; Type: INDEX; Schema: nlpg; Owner: -
--

CREATE INDEX sent_i_idx ON nlpg.sent USING btree (i);


--
-- Name: sent_string_idx; Type: INDEX; Schema: nlpg; Owner: -
--

CREATE INDEX sent_string_idx ON nlpg.sent USING btree (string);


--
-- Name: word_dep_idx; Type: INDEX; Schema: nlpg; Owner: -
--

CREATE INDEX word_dep_idx ON nlpg.word USING btree (dep);


--
-- Name: word_head_idx; Type: INDEX; Schema: nlpg; Owner: -
--

CREATE INDEX word_head_idx ON nlpg.word USING btree (head);


--
-- Name: word_i_idx; Type: INDEX; Schema: nlpg; Owner: -
--

CREATE INDEX word_i_idx ON nlpg.word USING btree (i);


--
-- Name: word_lexeme_idx; Type: INDEX; Schema: nlpg; Owner: -
--

CREATE INDEX word_lexeme_idx ON nlpg.word USING btree (lexeme);


--
-- Name: word_sent_idx; Type: INDEX; Schema: nlpg; Owner: -
--

CREATE INDEX word_sent_idx ON nlpg.word USING btree (sent);


--
-- Name: morph jsonize_feats; Type: TRIGGER; Schema: nlpg; Owner: -
--

CREATE TRIGGER jsonize_feats AFTER INSERT OR UPDATE OF feats ON nlpg.morph FOR EACH ROW EXECUTE FUNCTION nlpg.feats_to_json();


--
-- Name: chunk chunk_passage_fkey; Type: FK CONSTRAINT; Schema: hum; Owner: -
--

ALTER TABLE ONLY hum.chunk
    ADD CONSTRAINT chunk_passage_fkey FOREIGN KEY (passage) REFERENCES hum.passage(id);


--
-- Name: string string_chunk_fkey; Type: FK CONSTRAINT; Schema: hum; Owner: -
--

ALTER TABLE ONLY hum.string
    ADD CONSTRAINT string_chunk_fkey FOREIGN KEY (chunk) REFERENCES hum.chunk(id);


--
-- Name: lemma lemma_pos_fkey; Type: FK CONSTRAINT; Schema: nlpg; Owner: -
--

ALTER TABLE ONLY nlpg.lemma
    ADD CONSTRAINT lemma_pos_fkey FOREIGN KEY (pos) REFERENCES nlpg.pos(id);


--
-- Name: lexeme lexeme_lemma_fkey; Type: FK CONSTRAINT; Schema: nlpg; Owner: -
--

ALTER TABLE ONLY nlpg.lexeme
    ADD CONSTRAINT lexeme_lemma_fkey FOREIGN KEY (lemma) REFERENCES nlpg.lemma(id);


--
-- Name: lexeme lexeme_morph_fkey; Type: FK CONSTRAINT; Schema: nlpg; Owner: -
--

ALTER TABLE ONLY nlpg.lexeme
    ADD CONSTRAINT lexeme_morph_fkey FOREIGN KEY (morph) REFERENCES nlpg.morph(id);


--
-- Name: token token_sent_fkey; Type: FK CONSTRAINT; Schema: nlpg; Owner: -
--

ALTER TABLE ONLY nlpg.token
    ADD CONSTRAINT token_sent_fkey FOREIGN KEY (sent) REFERENCES nlpg.sent(id);


--
-- Name: word word_dep_fkey; Type: FK CONSTRAINT; Schema: nlpg; Owner: -
--

ALTER TABLE ONLY nlpg.word
    ADD CONSTRAINT word_dep_fkey FOREIGN KEY (dep) REFERENCES nlpg.dep(id);


--
-- Name: word word_lexeme_fkey; Type: FK CONSTRAINT; Schema: nlpg; Owner: -
--

ALTER TABLE ONLY nlpg.word
    ADD CONSTRAINT word_lexeme_fkey FOREIGN KEY (lexeme) REFERENCES nlpg.lexeme(id);


--
-- Name: word word_sent_fkey; Type: FK CONSTRAINT; Schema: nlpg; Owner: -
--

ALTER TABLE ONLY nlpg.word
    ADD CONSTRAINT word_sent_fkey FOREIGN KEY (sent) REFERENCES nlpg.sent(id);


--
-- PostgreSQL database dump complete
--

\unrestrict mWhDgkpy5gmUXigSobONjPu9BlCDmJBEl0OoogBrLf6fQ4pS5O1YCq5nHoJw3GH

