const fs = require("fs");
const path = require("path");
const tm = require("markdown-it-texmath");
var md = require("markdown-it")({ html: true }).use(tm, {
  engine: require("katex"),
  delimiters: "dollars",
  katexOptions: { macros: { "\\RR": "\\mathbb{R}" } },
});
const argv = require("minimist")(process.argv.slice(2));
const inputs = argv.i.split(" ");
const output = argv.o;

const content_template = fs.readFileSync(
  path.resolve(__dirname, "../templates/index.html"),
  "utf8",
);

var contents_md = fs.readFileSync(
  path.resolve(__dirname, "../" + inputs[0]),
  "utf8",
);
contents_md = contents_md
  .replaceAll(".png", ".webp")
  .replaceAll(".jpg", ".webp")
  .replaceAll(".jpeg", ".webp");

// Populate the content of a project page
var contents_html = md.render(contents_md);
var content = content_template.replace("<!-- CONTENT -->", contents_html);

// Write the article to file
fs.writeFileSync(path.resolve(__dirname, "../" + output), content);
