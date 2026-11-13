import{a as e,i as t,n,o as r,r as i,t as a}from"./sql.C22JFWHe.js";var o=r(e(),1);for(let e of[`chunk_lemma`,`passage`])await a(e);function s(){return(0,o.default)(`SELECT c.text, c.idea, c.type, p.lang, p.year, p.work_label, p.uri
      FROM chunk_lemma AS c
      JOIN passage p ON p.uri = c.passage_uri
      `)}function c(e){return t(`a`,{className:`passage-uri`,href:`${i}${e}`,textContent:e}).outerHTML}function l(e,n){let r=t(`div`,{innerHTML:e});for(let e of r.children){let t=`/scalable-reading/kwic?lemma=${e.getAttribute(`data-lemma`)||e.textContent.toLowerCase()}&property=${n}`;e.setAttribute(`href`,t)}return r.innerHTML}var u=new DataTable(`#chunk-table`,{data:s(),columns:[{data:`text`,title:`text`,render:e=>l(e,`text`)},{data:`idea`,title:`idea`,render:e=>l(e,`idea`)},{data:`type`,title:`type`},{data:`year`,title:`year`},{data:`lang`,title:`language`},{data:`work_label`,title:`work`},{data:`uri`,title:`passage`,render:c}]});function d(){o.default.promise(`SELECT c.text, c.idea, c.type, p.lang, p.year, p.work_label, p.uri
            FROM chunk_lemma AS c
            JOIN passage p ON p.uri = c.passage_uri
            WHERE ($chunk_type = '' OR c.type = $chunk_type)
            AND ($work = '' OR p.work_label = $work)
            AND ($lang = '' OR p.lang = $lang)
            AND ($year_start = '' OR p.year >= $year_start)
            AND ($year_end = '' OR p.year <= $year_end)
            `,n()).then(e=>{u.clear(),u.rows.add(e),u.draw()})}d();