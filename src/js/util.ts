/* helper function to create an element and set its attributes.
 * it's mostly there to enable one-liner: `div.append(createElement(tag, {id: id}))`
 * */
export default function createElement(tag: string, attrs: object | null) {
  const elem = document.createElement(tag)
  if (attrs)
    Object.entries(attrs).forEach(([key, value]) => (elem[key] = value))
  return elem
}

export const BASE_URI =
  "https://humility.lod4hss.org/sparql-queries/text-page.html?uri=https%3A%2F%2Fhumility.lod4hss.cloud%2Fresource%2F"
