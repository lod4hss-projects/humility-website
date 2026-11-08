import{i as e,n as t,r as n,t as r}from"./util.rq5p7hKl.js";var i=e(n(),1),a=document.getElementById(`kwic`);a||console.error("no element with id `kwic`");var o=[`pos`,`dep`,`lemma`,`hypernym`,`type`,`lang`,`work`,`year-start`,`year-end`];function s(){o.forEach(e=>{let t=document.getElementById(e);t?t.value=t.tagName.toLowerCase()==`select`?(t?.childNodes[0]).value:t[`data-default`]||``:console.error(`id not found: ${e}`)})}function c(){let e=[];for(let t of o){let n=document.getElementById(t);n||console.error(`id not found: ${t}`);let r=(n.value||``).trim();e.push(r),e.push(r)}return e}function l(){let e=c(),t=document.getElementById(`order-by`).value||`keyword`;return(0,i.default)(`
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
  ORDER BY ${t}, keyword, ctx_left, ctx_right`,e)}function u(){console.time(`query`);let e=l();console.timeEnd(`query`),a&&(a.innerHTML=``,e.forEach(e=>{let n=t(`div`,{className:`row`});for(let i of[`ctx_left`,`keyword`,`ctx_right`]){let a=t(`span`,{className:i});console.log(e),a.append(t(`a`,{textContent:e[i],href:`${r}${e.passage_uri}`})),n.append(a)}a.append(n)}))}console.time(`tables`);for(let e of[`lemma`,`word`,`chunk`,`passage`])await i.default.promise(`CREATE TABLE ${e}; SELECT * INTO ${e} FROM csv(?, {separator:","})`,[`/data/${e}.csv`]);console.timeEnd(`tables`);var d=new URLSearchParams(document.location.search);for(let e of o){let t=d.get(e);t&&(document.getElementById(e).value=t)}u(),document.getElementById(`button-submit`)?.addEventListener(`click`,u),document.getElementById(`button-reset`)?.addEventListener(`click`,s);