import{a as e,i as t,n,o as r,r as i,t as a}from"./sql.D5FpUcYn.js";var o=r(e(),1);for(let e of[`chunk_lemma`,`passage`])await a(e);function s(){let e=document.getElementById(`tb`);e?o.default.promise(`SELECT c.*
            FROM chunk_lemma AS c
            JOIN passage p ON p.uri = c.passage_uri
            WHERE ($chunk_type = '' OR c.type = $chunk_type)
            AND ($work = '' OR p.work = $work)
            AND ($lang = '' OR p.lang = $lang)
            AND ($year_start = '' OR p.year_start > $year_start)
            AND ($year_end = '' OR p.year_end > $year_end)
            `,n()).then(n=>{e.innerHTML=``,n.forEach(n=>{let r=t(`tr`,{});for(let e of[`text`,`idea`]){let i=t(`td`,{className:e,innerHTML:n[e]});for(let t of i.children){let n=`/scalable-reading/kwic?lemma=${t.getAttribute(`data-lemma`)||t.textContent.toLowerCase()}&property=${e}`;t.setAttribute(`href`,n)}r.append(i)}r.append(t(`td`,{textContent:n.type}));let a=t(`td`,{className:`passage_uri`});a.append(t(`a`,{href:`${i}${n.passage_uri}`,textContent:n.passage_uri})),r.append(a),e.append(r)})}):console.error(`element 'tb' not found`)}s(),document.getElementById(`button-submit`)?.addEventListener(`click`,s);