const fs = require("node:fs")
const fptree = require("file-paths-to-tree")

fs.readFile(process.argv[2], "utf8", (err, data) => {
  if (err) {
    console.error(err)
    return
  }
  const paths = data
    .split("\n")
    .slice(1)
    .filter((i) => i != "")
  var tree = fptree.filePathsToTree(paths, { separator: "." })
  if (tree.length != 1) {
    console.error("array length > 1. cannot build tree.")
    return
  }
  console.log(JSON.stringify(tree[0], ["name", "children", "path"], 0))
})
