// adapted from https://observablehq.com/@d3/collapsible-tree

var data = await d3.json("tree.json")

const ideas_csv = await d3.csv("ideas.csv")

function add_ideas(node) {
  node.ideas = []
  ideas_csv.forEach((i) => {
    if (i.path.startsWith(node.path)) {
      node.ideas.push(i.idea)
    }
  })
  node.children.forEach(add_ideas)
}

add_ideas(data)

const width = 928
const marginTop = 10
const marginRight = 10
const marginBottom = 10
const marginLeft = 40

const root = d3.hierarchy(data)
const dx = 14
const dy = 120

const tree = d3.tree().nodeSize([dx, dy])
const diagonal = d3
  .linkHorizontal()
  .x((d) => d.y)
  .y((d) => d.x)

const svg = d3
  .select("#tree")
  .append("svg")
  .attr("width", width)
  .attr("height", dx)
  .attr("viewBox", [-marginLeft, -marginTop, width, dx])
  .attr("style", "width: 2000px; height: auto; font: 10px sans-serif")

const gLink = svg
  .append("g")
  .attr("fill", "none")
  .attr("stroke", "#555")
  .attr("stroke-opacity", 0.4)
  .attr("stroke-width", 1.5)

const gNode = svg
  .append("g")
  .attr("cursor", "pointer")
  .attr("pointer-events", "all")

function update(event, source) {
  const duration = event?.altKey ? 2500 : 250
  const nodes = root.descendants().reverse()
  const links = root.links()

  tree(root)

  let left = root
  let right = root
  root.eachBefore((node) => {
    if (node.x < left.x) left = node
    if (node.x > right.x) right = node
  })

  const height = right.x - left.x + marginTop + marginBottom

  const transition = svg
    .transition()
    .duration(duration)
    .attr("height", height)
    .attr("viewBox", [-marginLeft, left.x - marginTop, width, height])
    .tween(
      "resize",
      window.ResizeObserver ? null : () => () => svg.dispatch("toggle")
    )

  const node = gNode.selectAll("g").data(nodes, (d) => d.id)

  const nodeEnter = node
    .enter()
    .append("g")
    .attr("transform", (d) => `translate(${source.y0},${source.x0})`)
    .attr("fill-opacity", 0)
    .attr("stroke-opacity", 0)
    .on("click", (event, d) => {
      d.children = d.children ? null : d._children
      // TODO: make something cleaner
      const div = d3.select("#ideas")
      document.getElementById("ideas").innerHTML = ""
      div.append("h3").text(d.data.name)
      d.data.ideas.forEach((idea) => {
        div.append("p").text(idea)
      })
      update(event, d)
    })

  nodeEnter
    .append("circle")
    .attr("r", 2.5)
    .attr("fill", (d) => (d._children ? "#555" : "#999"))
    .attr("stroke-width", 10)

  nodeEnter
    .append("text")
    .attr("dy", "0.31em")
    .attr("x", (d) => (d._children ? -6 : 6))
    .attr("text-anchor", (d) => (d._children ? "end" : "start"))
    .text((d) => d.data.name)
    .attr("stroke-linejoin", "round")
    .attr("stroke-width", 5)
    .attr("stroke", "white")
    .attr("paint-order", "stroke")

  const nodeUpdate = node
    .merge(nodeEnter)
    .transition(transition)
    .attr("transform", (d) => `translate(${d.y},${d.x})`)
    .attr("fill-opacity", 1)
    .attr("stroke-opacity", 1)

  const nodeExit = node
    .exit()
    .transition(transition)
    .remove()
    .attr("transform", (d) => `translate(${source.y},${source.x})`)
    .attr("fill-opacity", 0)
    .attr("stroke-opacity", 0)

  const link = gLink.selectAll("path").data(links, (d) => d.target.id)

  const linkEnter = link
    .enter()
    .append("path")
    .attr("stroke-width", 1)
    .attr("stroke", "#888")
    .attr("stroke-opacity", 1)
    .attr("d", (d) => {
      const o = { x: source.x0, y: source.y0 }
      return diagonal({ source: o, target: o })
    })

  link.merge(linkEnter).transition(transition).attr("d", diagonal)

  link
    .exit()
    .transition(transition)
    .remove()
    .attr("d", (d) => {
      const o = { x: source.x, y: source.y }
      return diagonal({ source: o, target: o })
    })

  root.eachBefore((d) => {
    d.x0 = d.x
    d.y0 = d.y
  })
}

root.x0 = dy / 2
root.y0 = 0
root.descendants().forEach((d, i) => {
  d.id = i
  d._children = d.children
  if (d.depth > 0) d.children = null
})

update(null, root)
