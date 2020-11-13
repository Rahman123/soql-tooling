parser grammar imports;

@header {
// var ParserHelper = require('./parserHelper').ParserHelper;
import  { ParserHelper } from './parserHelper';

}

@members {
helper =  new ParserHelper(false, 50.0, true)
//this.helper =  undefined;
//this.getHelper = () => this.helper;
//this.setHelper = (helper) => { this.helper = helper; };
}
