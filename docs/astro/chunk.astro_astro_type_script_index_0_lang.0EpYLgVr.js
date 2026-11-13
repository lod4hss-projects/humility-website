import{a as e,i as t,n,o as r,r as i,s as a,t as o}from"./sql.mi5m7eO5.js";var s=a(r(),1);for(let e of[`chunk_lemma`,`passage`])await o(e);function c(){return(0,s.default)(`SELECT c.text, c.idea, c.type, p.lang, p.year, p.work_label, p.uri
      FROM chunk_lemma AS c
      JOIN passage p ON p.uri = c.passage_uri
      `)}function l(n){return e(`a`,{className:`passage-uri`,href:`${t}${n}`,textContent:n}).outerHTML}function u(t,n){let r=e(`div`,{innerHTML:t});for(let e of r.children){let t=`/scalable-reading/kwic?lemma=${e.getAttribute(`data-lemma`)||e.textContent.toLowerCase()}&property=${n}`;e.setAttribute(`href`,t)}return r.innerHTML}var d=new DataTable(`#tbl`,{data:c(),columns:[{data:`text`,title:`text`,render:e=>u(e,`text`)},{data:`idea`,title:`idea`,render:e=>u(e,`idea`)},{data:`type`,title:`type`},{data:`year`,title:`year`},{data:`lang`,title:`language`},{data:`work_label`,title:`work`},{data:`uri`,title:`passage`,render:l}]});function f(){s.default.promise(`SELECT c.text, c.idea, c.type, p.lang, p.year, p.work_label, p.uri
            FROM chunk_lemma AS c
            JOIN passage p ON p.uri = c.passage_uri
            WHERE ($chunk_type = '' OR c.type = $chunk_type)
            AND ($work = '' OR p.work_label = $work)
            AND ($lang = '' OR p.lang = $lang)
            AND ($year_start = '' OR p.year >= $year_start)
            AND ($year_end = '' OR p.year <= $year_end)
            `,n()).then(e=>{d.clear(),d.rows.add(e),d.draw()})}f(),document.getElementById(`button-submit`)?.addEventListener(`click`,f),document.getElementById(`button-reset`)?.addEventListener(`click`,()=>{i(),f()});