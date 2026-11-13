/* Functions related to ALASQL. */
import alasql from "alasql"

const re_check_name = /^[a-zA-Z]\w+$/

export async function csvToTable(name: string) {
  if (!re_check_name.exec(name)) console.error(`invalid table name: ${name}`)
  console.time(`create table ${name}`)
  await alasql.promise(
    `CREATE TABLE ${name}; SELECT * INTO ${name} FROM csv(?, {separator:","})`,
    [`/data/${name}.csv`]
  )
  console.timeEnd(`create table ${name}`)
}

export function getFilterParams() {
  const filterParams = document.getElementsByClassName("filter-param")
  const params = { id: 0 }
  for (let i of filterParams) {
    params[i.id.replace("-", "_")] = i.value
  }
  console.log(params)
  return params
}

export function resetFilters() {
  const filterParams = document.getElementsByClassName("filter-param")
  for (let elem of filterParams) {
    if (elem.tagName.toLowerCase() == "select") {
      elem.value = (elem?.childNodes[0] as HTMLOptionElement).value
    } else elem.value = elem["data-default"] || ""
  }
}
