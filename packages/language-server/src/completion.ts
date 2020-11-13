import * as antlrSoqlParser from '../src.generated/soql-completion-parser/SoqlParser';
import * as antlrSoqlLexer from '../src.generated/soql-completion-parser/SoqlLexer';

// import {LowerCasingCharStream} from '@salesforce/soql-parser/lib/soql-parser';
import { CompletionItemKind } from 'vscode-languageserver';

import { ANTLRInputStream, CommonTokenStream } from 'antlr4ts';
// import  * as soql from '@salesforce/soql-parser';

import * as c3 from 'antlr4-c3';
import { ConsoleErrorListener } from 'antlr4/error/ErrorListener';
import { ParseTree } from 'antlr4ts/tree/ParseTree';
import { TerminalNode } from 'antlr4ts/tree/TerminalNode';

const completionResolveFunctions = {
  _START: (ctx: any) => [], // for empty query but also for nested SELECTs
  SELECT: (ctx: any) => [],
  FROM: (ctx: any) => {
    return [
      {
        label: 'Account2',
        kind: CompletionItemKind.Class,
        data: 1,
      },
      {
        label: 'Contact2',
        kind: CompletionItemKind.Class,
        data: 2,
      },
      {
        label: 'User2',
        kind: CompletionItemKind.Class,
        data: 3,
      },
    ];
  },
  WHERE: (ctx: any) => [],
  ORDER_BY: (ctx: any) => [],
  GROUP_BY: (ctx: any) => [],
  LIMIT: (ctx: any) => [],
};

class LowerCasingCharStream extends ANTLRInputStream {
  constructor(data: string) {
    super(data);
  }

  public LA(offset: number): number {
    const la = super.LA(offset);
    if (la <= 0) {
      return la;
    }
    const char = String.fromCharCode(la);
    return char.toLowerCase().charCodeAt(0);
  }
}

export function completionsFor(text: string, line: number, column: number) {
  const lexer = new antlrSoqlLexer.SoqlLexer(new LowerCasingCharStream(text));
  const tokenStream = new CommonTokenStream(lexer);
  const parser = new antlrSoqlParser.SoqlParser(tokenStream);
  const parsedQuery = parser.soqlQuery();

  const core = new c3.CodeCompletionCore(parser);
  core.preferredRules = new Set([
    antlrSoqlParser.SoqlParser.RULE_soqlFromExpr,
    antlrSoqlParser.SoqlParser.RULE_soqlField,
  ]);
  core.showDebugOutput = true;
  const tokenIndex =
    computeTokenIndex(parsedQuery, { line, column }) || tokenStream.size - 1;
  // console.log('===== tokenIndex = ' + tokenIndex);
  const candidates = core.collectCandidates(tokenIndex, parsedQuery);
  // console.log(
  //   '===candidates.tokens: ' +
  //     JSON.stringify(
  //       Array.from(candidates.tokens.keys()).map(
  //         parser.vocabulary.getLiteralName.bind(parser.vocabulary)
  //       )
  //     )
  // );
  // console.log(
  //   '===candidates.rules: ' +
  //     JSON.stringify(
  //       Array.from(candidates.rules.keys()).map(
  //         (ruleIndex) => parser.ruleNames[ruleIndex]
  //       )
  //     )
  // );

  const keywordCandidates: string[] = [];
  for (let token of candidates.tokens) {
    switch (token[0]) {
      case antlrSoqlLexer.SoqlLexer.SELECT:
        keywordCandidates.push('SELECT');
        break;
      case antlrSoqlLexer.SoqlLexer.FROM:
        keywordCandidates.push('FROM');
        break;
      case antlrSoqlLexer.SoqlLexer.WHERE:
        keywordCandidates.push('WHERE');
        break;
      case antlrSoqlLexer.SoqlLexer.LIMIT:
        keywordCandidates.push('LIMIT');
        break;
      case antlrSoqlLexer.SoqlLexer.COMMA:
        keywordCandidates.push(',');
        break;
    }
  }
  console.log('===  keywordCandidates = ' + JSON.stringify(keywordCandidates));

  let sObjectCandidates: string[] = [];
  let fieldCandidates: string[] = [];
  for (let rule of candidates.rules) {
    switch (rule[0]) {
      case antlrSoqlParser.SoqlParser.RULE_soqlGroupByClause:
        keywordCandidates.push('GROUP BY');
        break;
      case antlrSoqlParser.SoqlParser.RULE_soqlOrderByClause:
        keywordCandidates.push('ORDER BY');
        break;
      case antlrSoqlParser.SoqlParser.RULE_soqlFromExpr:
        sObjectCandidates.push('Account');
        sObjectCandidates.push('User');
        sObjectCandidates.push('ZZZ');
        break;

      case antlrSoqlParser.SoqlParser.RULE_soqlField:
        fieldCandidates = [
          'field1',
          'field2',
          'field3',
          'Account.field1',
          'Account.field2',
          'Account.field3',
        ];
        break;
    }
  }
  return [
    ...keywordCandidates.map((n) => ({
      label: n,
      kind: CompletionItemKind.Keyword,
    })),
    ...fieldCandidates.map((s) => {
      const [targetObject, targetField] = s.split('.');

      return {
        label: s,
        kind: CompletionItemKind.Field,
        insertText: targetField ? `${targetField} FROM ${targetObject}` : s,
      };
    }),
    ...sObjectCandidates.map((n) => ({
      label: n,
      kind: CompletionItemKind.Class,
    })),
  ];
}

export type CaretPosition = { line: number; column: number };
export function computeTokenIndex(
  parseTree: ParseTree,
  caretPosition: CaretPosition
): number | undefined {
  if (parseTree instanceof TerminalNode) {
    return computeTokenIndexOfTerminalNode(parseTree, caretPosition);
  } else {
    return computeTokenIndexOfChildNode(parseTree, caretPosition);
  }
}

function computeTokenIndexOfTerminalNode(
  parseTree: TerminalNode,
  caretPosition: CaretPosition
) {
  let start = parseTree.symbol.charPositionInLine;
  let stop = parseTree.symbol.charPositionInLine + parseTree.text.length;
  if (
    parseTree.symbol.line == caretPosition.line &&
    start <= caretPosition.column &&
    stop >= caretPosition.column
  ) {
    return parseTree.symbol.tokenIndex;
  } else {
    return undefined;
  }
}

function computeTokenIndexOfChildNode(
  parseTree: ParseTree,
  caretPosition: CaretPosition
) {
  for (let i = 0; i < parseTree.childCount; i++) {
    let index = computeTokenIndex(parseTree.getChild(i), caretPosition);
    if (index !== undefined) {
      return index;
    }
  }
  return undefined;
}
