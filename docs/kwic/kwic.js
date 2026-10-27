/* create tables from CSV files */
console.time("csv")
for (let i of ["lemma", "word", "chunk"]) {
  await alasql.promise(
    `create table ${i}; select * into ${i} from csv(?, {separator:","})`,
    [`./${i}.csv`]
  )
}
console.timeEnd("csv")

/* create indexes */
console.time("index")
const indexes = {
  word: ["string", "lemma"],
  lemma: ["id", "pos"],
  chunk: ["id"],
}
Object.entries(indexes).forEach(([tb, cols]) => {
  cols.forEach((i) => alasql(`create index index_${tb}_${i} on ${tb} (${i})`))
})
console.timeEnd("index")

/* create a <select> with an <option> for each value and an ID */
function createSelect(values, id) {
  const select = document.createElement("select")
  select.id = id
  values.forEach((i) => {
    const option = document.createElement("option")
    option.value = i
    option.text = i
    select.append(option)
  })
  return select
}

/* create a <select> and an associated <label> */
function createSelectWithLabel(labelText, values, id) {
  const div = document.createElement("div")
  div.classList.add("select")
  const label = document.createElement("label")
  label.textContent = `${labelText}: `
  div.append(label)

  div.append(createSelect(values, id))
  return div
}

/* check that identifier are safe */
const re_identifier = /^[A-Za-z_]+$/
function checkIdentifier(identifier) {
  if (!re_identifier.exec(identifier)) {
    throw new Error("Invalid identifier")
  }
}

/* create a <select> and populate it from a query */
function createSelectFromQuery(form, label, table, column, id) {
  try {
    checkIdentifier(table)
    checkIdentifier(column)
    const query = `SELECT DISTINCT ${column} from ${table} ORDER BY ${column}`
    const values = alasql(query).map((i) => i[column])
    values.unshift("")
    form.append(createSelectWithLabel(label, values, id))
  } catch (e) {
    console.error(e)
  }
}

/* create an <input> with a label and an ID */
function createInput(form, labelText, id) {
  const div = document.createElement("div")
  const label = document.createElement("label")
  label.textContent = `${labelText}: `
  div.append(label)
  const input = document.createElement("input")
  input.id = id
  div.append(input)
  form.append(div)
}

function runQuery() {
  const values = {}
  const params = []
  for (let i of ["pos", "dep", "lemma", "hypernym"]) {
    const value = document.getElementById(i).value
    params.push(value)
    params.push(value)
  }
  const order_by = document.getElementById("order-by").value
  checkIdentifier(order_by)
  console.log(params)
  console.time("query")
  const result = alasql(
    `
WITH w AS (
  SELECT DISTINCT
    word.idx,
    word.len,
    word.chunk
  FROM word
    JOIN lemma ON lemma.id = word.lemma
  WHERE (? = '' OR lemma.pos = ?)
    AND (? = '' OR word.dep = ?)
    AND (? = '' OR lemma.lemma like '%' + ? + '%')
    AND (? = '' OR lemma.hypernym_path LIKE '%' + ? + '%')
)
SELECT
  substring(chunk.val, 1, w.idx - 1) AS ctx_left,
  substring(chunk.val, w.idx, w.len) AS keyword,
  substring(chunk.val, w.idx + w.len) AS ctx_right
  FROM w
  JOIN chunk ON chunk.id = w.chunk
  ORDER BY ${order_by}, keyword
`,
    params
  )
  console.timeEnd("query")
  const tb = document.getElementById("kwic")
  tb.innerHTML = ""
  result.forEach((i) => {
    const tr = document.createElement("tr")
    for (let j of ["ctx_left", "keyword", "ctx_right"]) {
      const td = document.createElement("td")
      td.classList = [j]
      td.textContent = i[j]
      tr.append(td)
    }
    tb.append(tr)
  })
}

/* create the query user interface */
function createUIQuery() {
  console.time("uiquery")
  const form = document.createElement("div")
  form.id = "form"
  try {
    createSelectFromQuery(form, "part-of-speech", "lemma", "pos", "pos")
    createSelectFromQuery(form, "dependency label", "word", "dep", "dep")
  } catch (e) {
    console.error(e)
    return
  }
  createInput(form, "lemma", "lemma")
  createInput(form, "hypernym", "hypernym")
  form.append(
    createSelectWithLabel(
      "order by",
      ["keyword", "ctx_left", "ctx_right"],
      "order-by"
    )
  )
  const buttonDiv = document.createElement("div")
  const button = document.createElement("span")
  button.classList.add("submit")
  button.id = "submit"
  button.textContent = "submit"
  button.onclick = runQuery
  form.append(button)
  document.getElementById("query").append(form)
  console.timeEnd("uiquery")
}

createUIQuery()
