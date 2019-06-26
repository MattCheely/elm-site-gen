#!/usr/bin/env node
const Fs = require("fs-extra");
const { Feed } = require("feed");
const Glob = require("glob");
const JsDom = require("jsdom").JSDOM;
const Path = require("path");
const Promise = require("bluebird");
const R = require("ramda");
const { Script } = require("vm");
const removeMarkdown = require("remove-markdown");
const { spawn } = require("cross-spawn");
// ACTION STARTS HERE

let mode = "help";
if (process.argv.length < 3) mode = "generate";
else if (process.argv[2] == "init") mode = "init";
else if (process.argv[2] == "draft") mode = "draft";

if (mode == "generate" || mode == "draft") {
  try {
    Fs.accessSync("config.json", Fs.constants.R_OK);
  } catch (err) {
    console.error(
      "Couldn't find config.json. Is this a new project? Run `elmstatic init` to generate a scaffold."
    );
    return;
  }

  const config = JSON.parse(Fs.readFileSync("config.json").toString());
  const { copy, feed, elm, outputDir, siteTitle } = config;
  const allowedTags = R.map(R.toLower, R.defaultTo([], config.tags));
  const includeDrafts = mode == "draft";

  try {
    console.log(`Compiling Site Engine...`);
    build(elm);
    const compiledPath = Path.join(process.cwd(), "elm.js");
    const { Elm } = require(compiledPath);
    const elmJs = Fs.readFileSync(compiledPath);

    let siteSrc = {
      config: config,
      files: readContentFiles()
    };

    Elm.FileProcessor.init({
      flags: siteSrc
    }).ports.sendFileData.subscribe(parsedSrc => {
        if (parsedSrc.error) {
            console.log(`
I had a problem processing your source files:

${parsedSrc.error}`);
            process.exit(1);
        } else {
            renderFiles(elmJs, parsedSrc);
        }
    });
  } catch (err) {
    console.log(err.message);
  }
} else if (mode == "init") {
  generateScaffold();
} else {
  printHelp();
}

function build(elmPath) {
  const layouts = R.reject(
    R.endsWith("Elmstatic.elm"),
    Glob.sync("_layouts/Post*.elm")
  );
  const engine = "_engine/FileProcessor.elm";
  const elmFiles = layouts.concat(engine);

  let command = R.isNil(elmPath) ? "elm" : elmPath;
  let args = ["make", elmFiles, /*"--optimize",*/ "--output", "elm.js"];

  console.log(`  $ ${command} ${R.flatten(args).join(" ")}`);
  const res = spawn.sync(command, R.flatten(args), { stdio: "inherit" });
  if (res.status != 0) throw new Error(res.error);
}

// () -> ()/Effects
function generateScaffold() {
  console.log("Generating scaffold...");
  Fs.copySync(Path.join(__dirname, "..", "scaffold"), process.cwd());
}

// () -> ()/Effects
function printHelp() {
  const { version } = JSON.parse(
    Fs.readFileSync(Path.join(__dirname, "..", "package.json")).toString()
  );
  R.forEach(console.log, [
    "Elmstatic v" + version + "\n",
    "Usage:\n",
    "Elmstatic has to be run from the site directory\n",
    "$ elmstatic       -> generate HTML for an existing site in the specified output directory",
    "$ elmstatic draft -> same as above, but including future-dated draft posts",
    "$ elmstatic init  -> generate a scaffold for a new site in the current directory\n",
    "See https://korban.net/elm/elmstatic for more information"
  ]);
}

function readContentFiles() {
  const fileNames = Glob.sync("_posts/**/*");
  return R.map(readFileData, fileNames);
}

function readFileData(path) {
  return {
    path: path,
    content: Fs.readFileSync(path).toString()
  };
}

function renderFiles(elmJs, parsedSrc) {
  parsedSrc.files.forEach(file => {
    generateHtml(elmJs, {
      siteConfig: parsedSrc.siteConfig,
      content: file
    }).then(page => {
      writePage(page);
    });
  });
}

function writePage(page) {
  const outputPath = Path.join("dist", page.outputPath);
  Fs.mkdirsSync(Path.dirname(outputPath));
  Fs.writeFileSync(outputPath, page.html);
}

// String -> PageConfig | PostConfig -> Promise<HtmlString>
function generateHtml(elmJs, fileData) {
  const script = new Script(`
    ${elmJs}; let app = Elm.${fileData.content.layout}.init({
         flags: ${JSON.stringify(fileData)}
     }).ports.renderError.subscribe((err) => {
         window.renderError = err;
     });
    `);

  const dom = new JsDom(`<!DOCTYPE html><html><body></body></html>`, {
    runScripts: "outside-only"
  });

  try {
    dom.runVMScript(script);
    return Promise.delay(1).then(() => {
      if (dom.window.renderError) {
        throw `
Unable to process ${fileData.content.layout} at ${fileData.content.source}:
${dom.window.renderError}
`;
      } else {
        return {
          outputPath: fileData.content.data.outputPath,
          html:
            "<!doctype html>" +
            R.replace(
              /citatsmle-script/g,
              "script",
              dom.window.document.body.innerHTML
            )
        };
      }
    });
  } catch (err) {
    return Promise.reject(err);
  }
}
