import{a as e,i as t,o as n,t as r}from"./sql.C22JFWHe.js";var i=n(e(),1);for(let e of[`chunk_lemma`,`passage`])await r(e);function a(e,n){let r=t(`div`,{innerHTML:e});for(let e of r.children){let t=`/scalable-reading/kwic?lemma=${e.getAttribute(`data-lemma`)||e.textContent.toLowerCase()}&property=${n}`;e.setAttribute(`href`,t)}return r.innerHTML}var o=new DataTable(`#chunk-table`,{data:()=>[],paging:!1,searching:!1,bInfo:!1,columns:[{data:`text`,title:`Content`,render:e=>a(e,`text`)},{data:`idea`,title:`Idea`,render:e=>a(e,`idea`)},{data:`type`,title:`Type`}]});function s(e){i.default.promise(`SELECT c.text, c.idea, c.type
            FROM chunk_lemma AS c
            JOIN passage p ON p.uri = c.passage_uri
            WHERE p.uri = ?
            `,e).then(e=>{o.clear(),o.rows.add(e),o.draw()})}var c=new URLSearchParams(window.location.search).get(`uri`),l=address;if(!c)throw document.body.innerHTML=`<p style="color:red; padding:20px;">Error: Missing ?uri parameter.</p>`,Error(`Missing ?uri parameter`);var u=`Unknown Entity`,d=`N/A`,f=`N/A`,p=``,m=``,h=[],g=document.getElementById(`final-links`);async function _(){let e=`
      SELECT  ?expressionLabel ?textUri ?text ?translationUri ?translation ?wisskiPageURL
        WHERE {
            BIND( <${c}> as ?textUri)
            ?textUri a <http://www.cidoc-crm.org/cidoc-crm/E33>;
                <http://www.cidoc-crm.org/cidoc-crm/P190> ?text;
                <http://www.w3.org/2002/07/owl#sameAs> ?wisskiPageURL.
            ?expression <http://www.cidoc-crm.org/cidoc-crm/P165> ?textUri;
                a <http://iflastandards.info/ns/lrm/lrmoo/F2>;
                <https://sdhss.org/ontology/shortcuts/P9> ?expressionLabel.
            OPTIONAL{
                 <${c}> <http://www.cidoc-crm.org/cidoc-crm/P73> ?translationUri.
                ?translationUri    <http://www.cidoc-crm.org/cidoc-crm/P190> ?translation.
            }
        }
        LIMIT 1
      `;try{let t=await fetch(`${l}?query=${encodeURIComponent(e)}`,{headers:{Accept:`application/sparql-results+json`}});if(!t.ok)throw Error(`Entity info error: ${t.status}`);let n=(await t.json()).results.bindings;n.length>0&&(u=n[0].expressionLabel?.value||u,d=n[0].text?.value||d,p=n[0].textUri?.value||c,m=n[0].wisskiPageURL?.value||``,f=n[0].translation?.value||`No translation available`);let r=`
          <h2>${u}</h2>
          <div style="margin-bottom:10px;">
            ${m?`<a href="${m}" target="_blank" style="font-weight:bold;">View on WissKI</a>`:``}
          </div>
          <table>
            <thead>
              <tr>
                <th>Original Text</th>
                <th>Translation</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>${d}</td>
                <td>${f}</td>
              </tr>
            </tbody>
          </table>
        `;document.getElementById(`entity-header`).innerHTML=r,g.innerHTML=`
          <span><a href="../chunk-table.html">← Back to chunks' list</a></span>
          <span><a href="../instance-page.html?uri=${encodeURIComponent(p)}" target="_blank">View Text Triples</a></span>
        `}catch(e){document.getElementById(`entity-header`).innerHTML=`<p style="color:red">Error loading header: ${e.message}</p>`}}async function v(){let e=`
        SELECT (GROUP_CONCAT(DISTINCT ?conceptLabel; SEPARATOR=", ") AS ?concepts) 
              (GROUP_CONCAT(DISTINCT ?conceptClassLabel; SEPARATOR=", ") AS ?conceptClasses) 
              (MAX(?chunk) AS ?chunkText) 
              ?chunkUri 
              ?textUri
        WHERE {
          BIND (<${c}> AS ?textUri)
          ?textUri a <http://www.cidoc-crm.org/cidoc-crm/E33>;
                  <http://www.cidoc-crm.org/cidoc-crm/P165> ?chunkUri.
          ?chunkUri <http://www.cidoc-crm.org/cidoc-crm/P190> ?chunk;
                    <http://www.cidoc-crm.org/cidoc-crm/P67> ?conceptUriFilter.
          ?conceptUriFilter <https://sdhss.org/ontology/shortcuts/P9> ?conceptLabelFilter.
          
          OPTIONAL {
            ?chunkUri <http://www.cidoc-crm.org/cidoc-crm/P67> ?conceptUri. 
            ?conceptUri <https://sdhss.org/ontology/shortcuts/P9> ?conceptLabel;
                      a <https://sdhss.org/ontology/sources-information-metadata/C20>.
          }
          OPTIONAL {
            ?chunkUri <http://www.cidoc-crm.org/cidoc-crm/P67> ?conceptClassUri. 
            ?conceptClassUri <https://sdhss.org/ontology/shortcuts/P9> ?conceptClassLabel;
                        a <https://sdhss.org/ontology/sources-information-metadata/C21>.
          }
        }
        GROUP BY ?textUri ?chunkUri
        ORDER BY ?chunkUri
        LIMIT 500
      `;try{let t=await fetch(l+`?query=`+encodeURIComponent(e),{headers:{Accept:`application/sparql-results+json`}});if(!t.ok)throw Error(`SPARQL error: ${t.status}`);h=(await t.json()).results.bindings.map(e=>{for(let t of[`chunkText`,`textUri`,`concepts`,`conceptClasses`,`chunkUri`])e[t]=e[t]?.value||``;return e}),new DataTable(`#associated-chunks`,{data:h,searching:!1,paging:!1,bInfo:!1,columns:[{data:`chunkText`,title:`Chunk Content`,render:(e,t,n)=>(n.chunkUri&&n.chunkUri.startsWith(`http`)&&(e=`<a href="${n.chunkUri.startsWith(`https://humility.lod4hss.cloud/resource/`)?`./instance-page.html?uri=${encodeURIComponent(n.chunkUri)}`:n.chunkUri}" target="_blank">${n.chunkText}</a>`),e)},{data:`concepts`,title:`Concepts`},{data:`conceptClasses`,title:`Concept Classes`}]}),c&&s(c.split(`/`).reverse()[0])}catch(e){console.error(e)}}(async()=>{await _(),await v()})();