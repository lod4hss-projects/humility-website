const ROOT = "https://humility.lod4hss.org"
const BASE_URI = `${ROOT}/sparql-queries/text-page.html?uri=https%3A%2F%2Fhumility.lod4hss.cloud%2Fresource%2F`

const kwic = document.getElementById("kwic")
const queryDesc = document.getElementById("query")
const tbody = document.getElementById("kwic-tbody")

/* helper function to create an element and set its attributes.
 * it's mostly there to enable one-liner: `div.append(createElement(tag, {id: id}))`
 * */
function createElement(tag, attrs, callback) {
  const elem = document.createElement(tag)
  if (attrs)
    Object.entries(attrs).forEach(([key, value]) => (elem[key] = value))
  if (callback) callback(elem)
  return elem
}

/* populate a <select> element with values as <option> */
function populateSelect(select, values) {
  for (let i of values)
    select.append(createElement("option", { value: i, text: i }))
}

/* check that identifier are safe.
 * this is not really important since there's no actual database.
 * but let's stick to safe practices anyway!
 * */
const re_identifier = /^[A-Za-z_]+$/
function checkIdentifier(identifier) {
  if (!re_identifier.exec(identifier)) {
    throw new Error("Invalid identifier")
  }
}

/* SELECT DISTINCT from `table`.`column`, plus an empty string at the start. */
function selectDistinct(table, column, addEmpty = true) {
  checkIdentifier(table)
  checkIdentifier(column)
  const query = `SELECT DISTINCT ${column} from ${table} ORDER BY ${column}`
  const values = alasql(query).map((i) => i[column])
  if (addEmpty) values.unshift("")
  return values
}

/* get the query parameters from the user interface. */
function getQueryParams() {
  const params = []
  for (let i of [
    "pos",
    "dep",
    "lemma",
    "hypernym",
    "type",
    "language",
    "work-label",
    "year-start",
    "year-end",
  ]) {
    const value = (document.getElementById(i).value || "").trim()
    params.push(value)
    params.push(value)
  }
  return params
}

/* run the select KWIC query using user-defined parameters. */
function runQuery() {
  const params = getQueryParams()
  const orderBy = document.getElementById("order-by").value
  return alasql(
    `
WITH w AS (
  SELECT DISTINCT
    word.idx,
    word.len,
    word.chunk
  FROM word
    JOIN lemma ON lemma.id = word.lemma
    JOIN chunk ON chunk.id = word.chunk
    JOIN excerpt ON excerpt.text = chunk.excerpt_uri
  WHERE (? = '' OR lemma.pos = ?)
    AND (? = '' OR word.dep = ?)
    AND (? = '' OR lemma.lemma LIKE '%' + ? + '%')
    AND (? = '' OR lemma.hypernym_path LIKE '%' + ? + '%')
    AND (? = '' OR chunk.type = ?)
    AND (? = '' OR excerpt.lang = ?)
    AND (? = '' OR excerpt.source_label = ?)
    AND (? = '' OR (excerpt.crea_year IS NOT NULL AND excerpt.crea_year >= ?))
    AND (? = '' OR (excerpt.crea_year IS NOT NULL AND excerpt.crea_year <= ?))
)
SELECT
  chunk.excerpt_uri,
  substring(chunk.val, 1, w.idx - 1) AS ctx_left,
  substring(chunk.val, w.idx, w.len) AS keyword,
  substring(chunk.val, w.idx + w.len) AS ctx_right
  FROM w
  JOIN chunk ON chunk.id = w.chunk
  ORDER BY ${orderBy}, keyword, ctx_left, ctx_right
`,
    params
  )
}

/* update the KWIC table. */
function updateKWIC() {
  console.time("query")
  const result = runQuery()
  console.timeEnd("query")
  console.time("update")
  tbody.innerHTML = ""
  result.forEach((i) => {
    const tr = createElement("tr")
    for (let j of ["ctx_left", "keyword", "ctx_right"]) {
      const td = createElement("td", { className: j })
      td.append(
        createElement("a", {
          textContent: i[j],
          href: `${BASE_URI}${i.excerpt_uri}`,
        })
      )
      tr.append(td)
    }
    tbody.append(tr)
  })
  console.timeEnd("update")
}

/****** Describe the components of the interface. ******/

const ui = [
  {
    label: "Type",
    tag: "select",
    attrs: { id: "type" },
    callback: (i) => populateSelect(i, selectDistinct("chunk", "type", false)),
  },
  {
    label: "Part Of Speech",
    tag: "select",
    attrs: { id: "pos" },
    callback: (i) => populateSelect(i, selectDistinct("lemma", "pos", true)),
  },
  {
    label: "Dependency Label",
    tag: "select",
    attrs: { id: "dep" },
    callback: (i) => populateSelect(i, selectDistinct("word", "dep", true)),
  },
  { label: "Hypernym", tag: "input", attrs: { id: "hypernym" } },
  { label: "Lemma", tag: "input", attrs: { id: "lemma" } },
  /**** filters relative to the expression/work metadata ****/
  { tag: "hr" },
  {
    label: "Language (orig. text)",
    tag: "select",
    attrs: { id: "language" },
    callback: (i) => populateSelect(i, selectDistinct("excerpt", "lang", true)),
  },
  {
    label: "Year (start)",
    tag: "input",
    attrs: { type: "number", id: "year-start" },
  },
  {
    label: "Year (end)",
    tag: "input",
    attrs: { type: "number", id: "year-end" },
  },
  {
    label: "Work",
    tag: "select",
    attrs: { id: "work-label" },
    callback: (i) =>
      populateSelect(i, selectDistinct("excerpt", "source_label", false)),
  },
  /**** presentations options ****/
  { tag: "hr" },
  {
    label: "Order By",
    tag: "select",
    attrs: { id: "order-by" },
    callback: (i) => populateSelect(i, ["keyword", "ctx_left", "ctx_right"]),
  },
  {
    label: "Aligned",
    tag: "input",
    attrs: {
      id: "aligned",
      type: "checkbox",
      checked: true,
      onclick: (_) => {
        const className = "tb-inline"
        kwic.className = kwic.className == className ? "" : className
      },
    },
  },
  // TODO: add filter idea/text
  // TODO: add filter with work metadata, such as orig_language, year, ...
  /**** submit button at the end ****/
  { tag: "hr" },
  {
    tag: "span",
    attrs: {
      id: "submit",
      className: "button",
      textContent: "submit",
      onclick: updateKWIC,
    },
  },
  {
    tag: "span",
    attrs: {
      id: "reset",
      className: "button",
      textContent: "reset",
      onclick: createUI,
    },
  },
]

/****** Load the data and build the interface ******/

/* create tables from CSV files.
 * this is the slowest part of the module. but we cannot really change this.
 * however, we only load data once, so it's fine for now.
 * */
console.time("csv")
for (let i of ["lemma", "word", "chunk", "excerpt"]) {
  await alasql.promise(
    `create table ${i}; select * into ${i} from csv(?, {separator:","})`,
    [`./${i}.csv`]
  )
}
console.timeEnd("csv")

/* create indexes.
 * i don't know if it's really more efficient, but it's quick.
 * */
console.time("index")
const indexes = {
  word: ["string", "lemma"],
  lemma: ["id", "pos"],
  chunk: ["id", "excerpt_uri", "type"],
  excerpt: ["text"],
}
Object.entries(indexes).forEach(([t, cols]) => {
  cols.forEach((c) => alasql(`create index index_${t}_${c} on ${t} (${c})`))
})
console.timeEnd("index")

function createUI() {
  // TODO: build the query in `index.html` and only populate the <select> here.
  /* create the query user interface */
  console.time("create-ui")
  queryDesc.innerHTML = ""
  tbody.innerHTML = ""
  for (let i of ui) {
    const p = createElement("p")
    if (i.label)
      p.append(createElement("label", { textContent: `${i.label}: ` }))
    p.append(createElement(i.tag, i.attrs, i.callback))
    queryDesc.append(p)
  }
  console.timeEnd("create-ui")
}

createUI()
