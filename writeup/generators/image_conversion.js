const ffmpeg = require('fluent-ffmpeg')
const fs = require('fs')
const { Readable } = require('stream')

var argv = require('minimist')(process.argv.slice(2));

function convertImage(imagePath, outputName) {
	ffmpeg().input(fs.createReadStream(imagePath)).save(outputName)
}

convertImage(argv.i, argv.o)
