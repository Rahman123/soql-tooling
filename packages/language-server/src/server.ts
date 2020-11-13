/*
 *  Copyright (c) 2020, salesforce.com, inc.
 *  All rights reserved.
 *  Licensed under the BSD 3-Clause license.
 *  For full license text, see LICENSE.txt file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 *
 */

import {
  createConnection,
  TextDocuments,
  ProposedFeatures,
  InitializeParams,
  TextDocumentSyncKind,
  InitializeResult,
  TextDocumentPositionParams,
  CompletionItem,
  CompletionItemKind,
} from 'vscode-languageserver';

import { TextDocument } from 'vscode-languageserver-textdocument';
import { Validator } from './validator';
import { completionsFor } from './completion';

// Create a connection for the server, using Node's IPC as a transport.
let connection = createConnection(ProposedFeatures.all);

// Create a simple text document manager.
let documents: TextDocuments<TextDocument> = new TextDocuments(TextDocument);

connection.onInitialize((params: InitializeParams) => {
  const result: InitializeResult = {
    capabilities: {
      textDocumentSync: TextDocumentSyncKind.Full, // sync full document for now
      completionProvider: {
        // resolveProvider: true,
        triggerCharacters: [' '],
      },
    },
  };
  return result;
});

documents.onDidChangeContent((change) => {
  const diagnostics = Validator.validateSoqlText(change.document);
  connection.sendDiagnostics({ uri: change.document.uri, diagnostics });
});

connection.onCompletion(
  async (request: TextDocumentPositionParams): Promise<CompletionItem[]> => {
    const doc = documents.get(request.textDocument.uri);

    console.log('========= onCompletion.  doc:' + doc);
    console.log('========= onCompletion.  doc.getText():' + doc?.getText());
    if (!doc) return [];

    return completionsFor(
      doc.getText(),
      request.position.line + 1,
      request.position.character + 1
    );
  }
);

// This handler resolves additional information for the item selected in
// the completion list.
// connection.onCompletionResolve(
//   (item: CompletionItem): CompletionItem => {
//     if (item.data === 1) {
//       item.detail = 'Account details';
//       item.documentation = 'Account documentation';
//     } else if (item.data === 2) {
//       item.detail = 'Contact details';
//       item.documentation = 'Contact documentation';
//     } else if (item.data === 3) {
//       item.detail = 'User details';
//       item.documentation = 'User documentation';
//     }
//     return item;
//   }
// );

documents.listen(connection);

connection.listen();
