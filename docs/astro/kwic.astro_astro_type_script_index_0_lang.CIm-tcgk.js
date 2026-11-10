import{a as e,i as t,o as n,r,t as i}from"./sql.D5FpUcYn.js";var a=n(e(),1),o=document.getElementById(`kwic`);o||console.error("no element with id `kwic`");var s=[`pos`,`dep`,`lemma`,`hypernym`,`chunk-type`,`property`,`lang`,`work`,`year-start`,`year-end`];function c(){s.forEach(e=>{let t=document.getElementById(e);t?t.value=t.tagName.toLowerCase()==`select`?(t?.childNodes[0]).value:t[`data-default`]||``:console.error(`id not found: ${e}`)})}function l(){let e=[];for(let t of s){let n=document.getElementById(t);n||console.error(`id not found: ${t}`);let r=(n.value||``).trim();e.push(r),e.push(r)}return e}function u(){let e=l(),t=document.getElementById(`order-by`).value||`keyword`;return(0,a.default)(`
WITH w AS (
  SELECT DISTINCT
    word.idx,
    word.len,
    word.chunk
  FROM word
    JOIN lemma ON lemma.id = word.lemma
    JOIN chunk ON chunk.id = word.chunk
    JOIN passage ON passage.uri = chunk.passage_uri
  WHERE (? = '' OR lemma.pos = ?)
    AND (? = '' OR word.dep = ?)
    AND (? = '' OR lemma.lemma = ?)
    AND (? = '' OR lemma.hypernym_path LIKE '%' + ? + '%')
    AND (? = '' OR chunk.type = ?)
    AND (? = '' OR chunk.property = ?)
    AND (? = '' OR passage.lang = ?)
    AND (? = '' OR passage.label = ?)
    AND (? = '' OR (passage.year IS NOT NULL AND passage.year >= ?))
    AND (? = '' OR (passage.year IS NOT NULL AND passage.year <= ?))
)
SELECT
  chunk.passage_uri,
  substring(chunk.text, 1, w.idx - 1) AS ctx_left,
  substring(chunk.text, w.idx, w.len) AS keyword,
  substring(chunk.text, w.idx + w.len) AS ctx_right
  FROM w
  JOIN chunk ON chunk.id = w.chunk
  ORDER BY ${t}, keyword, ctx_left, ctx_right`,e)}function d(){console.time(`query`);let e=u();console.timeEnd(`query`),o&&(o.innerHTML=``,e.forEach(e=>{let n=t(`div`,{className:`row`});for(let i of[`ctx_left`,`keyword`,`ctx_right`]){let a=t(`span`,{className:i});a.append(t(`a`,{textContent:e[i],href:`${r}${e.passage_uri}`})),n.append(a)}o.append(n)}))}for(let e of[`lemma`,`word`,`chunk`,`passage`])await i(e);var f=new URLSearchParams(document.location.search);for(let e of s){let t=f.get(e);t&&(document.getElementById(e).value=t)}d(),document.getElementById(`button-submit`)?.addEventListener(`click`,d),document.getElementById(`button-reset`)?.addEventListener(`click`,c);