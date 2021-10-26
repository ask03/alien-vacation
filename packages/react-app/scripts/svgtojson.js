const fs = require('fs');
const parser = require('fast-xml-parser');
const he = require('he');

let xmlData = fs.readFileSync('./src/svgs/mouth/Open.svg', {
  encoding: 'utf-8',
})

const options = {
    attributeNamePrefix : "@_",
    attrNodeName: "attr", //default is 'false'
    textNodeName : "#text",
    ignoreAttributes : false,
    ignoreNameSpace : false,
    allowBooleanAttributes : false,
    parseNodeValue : true,
    parseAttributeValue : false,
    trimValues: true,
    cdataTagName: "__cdata", //default is 'false'
    cdataPositionChar: "\\c",
    parseTrueNumberOnly: false,
    numParseOptions:{
      hex: true,
      leadingZeros: true,
      //skipLike: /\+[0-9]{10}/
    },
    arrayMode: false, //"strict"
    attrValueProcessor: (val, attrName) => he.decode(val, {isAttributeValue: true}),//default is a=>a
    tagValueProcessor : (val, tagName) => he.decode(val), //default is a=>a
    stopNodes: ["parse-me-as-string"],
    alwaysCreateTextNode: false
};

const LETTERS = [
  "a",
  "b",
  "c",
  "d",
  "e",
  "f",
  "g",
  "h",
  "i",
  "j",
  "k",
  "l",
  "m",
  "n",
  "o",
  "p",
  "q",
  "r",
  "s",
  "t",
  "u",
  "v",
  "w",
  "x",
  "y",
  "z"
]

const SVGMAP = [
  '#000000',
  '#323C39',
  '#847E87',
  '#A0A0A0',
  '#A49393',
  '#9BADB7',
  '#CFCFCF',
  '#3000FF',
  '#3E51FB',
  '#5266FA',
  '#43D6A7',
  '#3F3F74',
  '#5B6EE1',
  '#37946E',
  '#5FCDE4',
  '#A3FBED',
  '#CBDBFC',
  '#F142FB',
  '#FD9FCC',
  '#CF9DC1',
  '#ECB3DC',
  '#DBC7EC',
  '#014508',
  '#02660C',
  '#058F13',
  '#6ABE30',
  '#99E550',
  '#CDC304',
  '#FBF236',
  '#BE560A',
  '#DF7126',
  '#D48B55',
  '#D9A066',
  '#FB9F5C',
  '#FFD970',
  '#5F1E00',
  '#663931',
  '#8A6F30',
  '#FB2323',
  '#FF5555',
  '#AC3232',
  '#EEC39A',
  '#639BFF',
  '#94BF98',
  '#FFA500',
  '#D77BBA',
  '#D95763',
  '#8F563B',
  '#222034'
];

if(parser.validate(xmlData)=== true){//optional
	var jsonObj = parser.parse(xmlData,options);
}

let traitString = '';
let pixelCount = jsonObj.svg.rect.length
for(let i = 0; i < jsonObj.svg.rect.length; i++) {

  for(let j = 0; j < 26; j++) {
    if(jsonObj.svg.rect[i].attr['@_x'] == j) {
      traitString += LETTERS[j]
    }
  }
  for(let k = 0; k < 26; k++) {
    if(jsonObj.svg.rect[i].attr['@_y'] == k) {
      traitString += LETTERS[k]
    }
  }
  for(let l = 0; l < SVGMAP.length; l++) {
    if(jsonObj.svg.rect[i].attr['@_fill'] == SVGMAP[l]) {
      if(l < 10) {
        traitString += '0'
      }
      traitString += l
    }
  }
}

console.log(traitString)
console.log("pixelCount", pixelCount)

console.log("obj.rect.@_x", jsonObj.svg.rect[0].attr['@_x'])
